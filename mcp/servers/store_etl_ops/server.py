#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP

MCP_NAME = "store_etl_ops"
WORKDIR = Path("/home/jesus/proyectos/store-etl")
MAX_STDIO_BYTES = 32768
LOGS_DIR = WORKDIR / "logs"

mcp = FastMCP("store-etl-ops-mcp")


_ALLOWED_TARGETS = {
    "hydration-observability-report": {"args": set()},
    "hydration-domain-workflow": {"args": set()},
    "frontier-to-gold-domain-centric": {"args": set()},
    "hydration-recover-failed-reviews": {"args": {"SOURCE_RUN_ID"}},
    "db-reset-from-zero": {"args": set()},
}

_SAFE_VALUE = re.compile(r"^[A-Za-z0-9._:/-]+$")
_ALLOWED_LOG_EXTS = {".log", ".txt", ".json", ".ndjson"}


def _validate_target_and_args(target: str, args: dict[str, Any] | None) -> tuple[str, list[str]]:
    t = target.strip()
    if t not in _ALLOWED_TARGETS:
        raise ValueError(f"Unsupported target '{t}'. Allowed targets: {sorted(_ALLOWED_TARGETS)}")

    input_args = args or {}
    allowed_args = _ALLOWED_TARGETS[t]["args"]

    unknown = sorted(set(input_args.keys()) - allowed_args)
    if unknown:
        raise ValueError(f"Unsupported args for target '{t}': {unknown}")

    if t == "hydration-recover-failed-reviews" and "SOURCE_RUN_ID" not in input_args:
        raise ValueError("Target 'hydration-recover-failed-reviews' requires args.SOURCE_RUN_ID")

    env_pairs: list[str] = []
    for key in sorted(allowed_args):
        if key not in input_args:
            continue
        value = str(input_args[key]).strip()
        if not value:
            raise ValueError(f"Argument '{key}' must not be empty")
        if not _SAFE_VALUE.match(value):
            raise ValueError(f"Invalid value for '{key}': only [A-Za-z0-9._:/-] allowed")
        env_pairs.append(f"{key}={value}")

    return t, env_pairs


def _run_make(target: str, env_pairs: list[str]) -> dict[str, Any]:
    if not WORKDIR.exists():
        raise FileNotFoundError(f"Workdir not found: {WORKDIR}")

    cmd = ["make", target, *env_pairs]
    completed = subprocess.run(
        cmd,
        cwd=str(WORKDIR),
        check=False,
        capture_output=True,
        text=True,
    )

    stdout = completed.stdout or ""
    stderr = completed.stderr or ""
    combined = (stdout + "\n" + stderr).strip()
    if len(combined.encode("utf-8", errors="replace")) > MAX_STDIO_BYTES:
        combined = combined.encode("utf-8", errors="replace")[:MAX_STDIO_BYTES].decode("utf-8", errors="replace")

    return {
        "ok": completed.returncode == 0,
        "return_code": completed.returncode,
        "workdir": str(WORKDIR),
        "command": cmd,
        "output": combined,
    }


@mcp.tool()
def run_make(target: str, args: dict[str, Any] | None = None) -> dict[str, Any]:
    """Run a curated allow-listed make target in store-etl workdir."""
    try:
        safe_target, env_pairs = _validate_target_and_args(target, args)
        return _run_make(safe_target, env_pairs)
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": str(exc)}


@mcp.tool()
def tail_log(file: str, lines: int = 200) -> dict[str, Any]:
    """Tail an allow-listed log file path under store-etl workspace."""
    try:
        requested = Path(file)
        if requested.is_absolute():
            resolved = requested.resolve()
        else:
            resolved = (LOGS_DIR / requested).resolve()

        logs_resolved = LOGS_DIR.resolve()
        if logs_resolved not in resolved.parents and resolved != logs_resolved:
            raise ValueError("File must be inside /home/jesus/proyectos/store-etl/logs")
        if resolved.suffix and resolved.suffix.lower() not in _ALLOWED_LOG_EXTS:
            raise ValueError(f"File extension not allowed: {resolved.suffix}")
        if not resolved.exists():
            raise FileNotFoundError(f"File not found: {resolved}")
        if not resolved.is_file():
            raise ValueError(f"Not a file: {resolved}")

        safe_lines = min(max(int(lines), 1), 5000)
        completed = subprocess.run(
            ["tail", "-n", str(safe_lines), str(resolved)],
            check=False,
            capture_output=True,
            text=True,
        )
        return {
            "ok": completed.returncode == 0,
            "return_code": completed.returncode,
            "file": str(resolved),
            "lines": safe_lines,
            "output": completed.stdout,
            "stderr": completed.stderr,
        }
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": str(exc)}


def smoke_test() -> int:
    result = run_make("hydration-observability-report")
    print(
        json.dumps(
            {
                "server": MCP_NAME,
                "ok": bool(result.get("ok")),
                "sample": {
                    "return_code": result.get("return_code"),
                    "command": result.get("command"),
                    "output_head": (result.get("output") or "")[:500],
                },
            },
            indent=2,
        )
    )
    return 0 if result.get("ok") else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Store ETL Ops MCP wrapper (stdio)")
    parser.add_argument("--smoke-test", action="store_true", help="Run curated make smoke test")
    args = parser.parse_args()
    if args.smoke_test:
        return smoke_test()
    mcp.run(transport="stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
