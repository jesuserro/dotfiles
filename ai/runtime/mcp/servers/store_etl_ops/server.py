#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP

MCP_NAME = "store_etl_ops"
DEFAULT_STORE_ETL_WORKDIR = Path("/home/jesus/proyectos/store-etl")
STORE_ETL_WORKDIR_ENV = "STORE_ETL_WORKDIR"
STORE_ETL_REPO_MARKERS = (".git", "pyproject.toml", "Makefile")
MAX_STDIO_BYTES = 32768

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


def resolve_store_etl_workdir() -> Path:
    """Resolve the Store ETL workspace from STORE_ETL_WORKDIR or the local fallback."""
    raw = os.environ.get(STORE_ETL_WORKDIR_ENV, "").strip()
    source = STORE_ETL_WORKDIR_ENV if raw else f"default fallback ({DEFAULT_STORE_ETL_WORKDIR})"

    if raw:
        workdir = Path(raw).expanduser()
        if not workdir.is_absolute():
            workdir = (Path.cwd() / workdir).resolve()
        else:
            workdir = workdir.resolve()
    else:
        workdir = DEFAULT_STORE_ETL_WORKDIR

    if not workdir.exists():
        raise FileNotFoundError(
            f"Store ETL workdir not found: {workdir} (from {source}). "
            f"Set {STORE_ETL_WORKDIR_ENV} to your store-etl checkout "
            f"or create the fallback path."
        )

    if not workdir.is_dir():
        raise NotADirectoryError(
            f"Store ETL workdir is not a directory: {workdir} (from {source})"
        )

    if not _looks_like_store_etl_repo(workdir):
        markers = ", ".join(STORE_ETL_REPO_MARKERS)
        raise ValueError(
            f"Store ETL workdir does not look like a store-etl repository: {workdir}. "
            f"Expected at least one marker: {markers}"
        )

    return workdir


def _looks_like_store_etl_repo(workdir: Path) -> bool:
    return any((workdir / marker).exists() for marker in STORE_ETL_REPO_MARKERS)


def get_logs_dir() -> Path:
    return resolve_store_etl_workdir() / "logs"


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
    workdir = resolve_store_etl_workdir()

    cmd = ["make", target, *env_pairs]
    completed = subprocess.run(
        cmd,
        cwd=str(workdir),
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
        "workdir": str(workdir),
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
        logs_dir = get_logs_dir()
        requested = Path(file)
        if requested.is_absolute():
            resolved = requested.resolve()
        else:
            resolved = (logs_dir / requested).resolve()

        logs_resolved = logs_dir.resolve()
        if logs_resolved not in resolved.parents and resolved != logs_resolved:
            raise ValueError(f"File must be inside {logs_resolved}")
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
