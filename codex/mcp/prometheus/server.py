#!/usr/bin/env python3
import argparse
import json
import os
import re
from datetime import datetime
from typing import Any

import requests
from requests import RequestException
from mcp.server.fastmcp import FastMCP

MCP_NAME = "prometheus"

mcp = FastMCP("prometheus-mcp")
_LABEL_RE = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_]*$")


def _base_url() -> str:
    return os.getenv("PROMETHEUS_URL", "http://localhost:9090").rstrip("/")


def _timeout() -> float:
    return float(os.getenv("PROMETHEUS_TIMEOUT_SECONDS", "15"))


def _parse_rfc3339(value: str) -> str:
    # Validate RFC3339 input before forwarding to Prometheus API.
    parsed = value
    if value.endswith("Z"):
        parsed = value[:-1] + "+00:00"
    datetime.fromisoformat(parsed)
    return value


def _safe_error(exc: Exception) -> dict[str, Any]:
    if isinstance(exc, requests.Timeout):
        return {"ok": False, "error": f"timeout after {_timeout()}s"}
    if isinstance(exc, RequestException):
        message = str(exc)
        status_code = None
        if getattr(exc, "response", None) is not None:
            status_code = exc.response.status_code
            try:
                message = exc.response.text[:500]
            except Exception:  # noqa: BLE001
                message = str(exc)
        return {
            "ok": False,
            "error": "http_error",
            "status_code": status_code,
            "details": message,
        }
    return {"ok": False, "error": str(exc)}


def _compact(body: dict[str, Any]) -> dict[str, Any]:
    data = body.get("data", {}) if isinstance(body, dict) else {}
    return {
        "status": body.get("status") if isinstance(body, dict) else None,
        "data": {
            "resultType": data.get("resultType"),
            "result": data.get("result", []),
        },
    }


def _get(path: str, params: dict[str, Any]) -> dict[str, Any]:
    resp = requests.get(f"{_base_url()}{path}", params=params, timeout=_timeout())
    resp.raise_for_status()
    return resp.json()


@mcp.tool()
def query_instant(query: str, time_rfc3339: str | None = None) -> dict[str, Any]:
    """Run an instant Prometheus query."""
    params: dict[str, Any] = {"query": query}
    if time_rfc3339:
        params["time"] = _parse_rfc3339(time_rfc3339)

    try:
        body = _get("/api/v1/query", params)
        result = _compact(body)
        result["ok"] = True
        return result
    except Exception as exc:  # noqa: BLE001
        return _safe_error(exc)


@mcp.tool()
def query_range(query: str, start_rfc3339: str, end_rfc3339: str, step: str) -> dict[str, Any]:
    """Run a range Prometheus query."""
    params = {
        "query": query,
        "start": _parse_rfc3339(start_rfc3339),
        "end": _parse_rfc3339(end_rfc3339),
        "step": step,
    }
    try:
        body = _get("/api/v1/query_range", params)
        result = _compact(body)
        result["ok"] = True
        return result
    except Exception as exc:  # noqa: BLE001
        return _safe_error(exc)


@mcp.tool()
def list_targets() -> dict[str, Any]:
    """List active and dropped Prometheus targets."""
    try:
        body = _get("/api/v1/targets", {})
        data = body.get("data", {}) if isinstance(body, dict) else {}
        return {
            "ok": True,
            "status": body.get("status"),
            "data": {
                "activeTargets": data.get("activeTargets", []),
                "droppedTargets": data.get("droppedTargets", []),
            },
        }
    except Exception as exc:  # noqa: BLE001
        return _safe_error(exc)


@mcp.tool()
def label_values(label: str, matchers: list[str] | None = None) -> dict[str, Any]:
    """Get values for a Prometheus label."""
    safe_label = label.strip()
    if not safe_label:
        return {"ok": False, "error": "label must not be empty"}
    if not _LABEL_RE.match(safe_label):
        return {"ok": False, "error": "invalid label name"}

    params: dict[str, Any] = {}
    if matchers:
        params["match[]"] = [m for m in matchers if m and m.strip()]

    try:
        body = _get(f"/api/v1/label/{safe_label}/values", params)
        return {
            "ok": True,
            "status": body.get("status"),
            "data": {
                "resultType": "vector",
                "result": body.get("data", []),
            },
        }
    except Exception as exc:  # noqa: BLE001
        return _safe_error(exc)


def smoke_test() -> int:
    try:
        result = query_instant("up")
        print(
            json.dumps(
                {
                    "server": MCP_NAME,
                    "ok": bool(result.get("ok")),
                    "base_url": _base_url(),
                    "sample": result,
                },
                indent=2,
            )
        )
        return 0 if result.get("ok") else 1
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"server": MCP_NAME, "ok": False, "error": str(exc)}, indent=2))
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Prometheus MCP wrapper (stdio)")
    parser.add_argument("--smoke-test", action="store_true", help="Run live connectivity test")
    args = parser.parse_args()
    if args.smoke_test:
        return smoke_test()
    mcp.run(transport="stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
