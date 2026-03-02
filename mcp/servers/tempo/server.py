#!/usr/bin/env python3
import argparse
import json
import os
import time
from typing import Any

import requests
from mcp.server.fastmcp import FastMCP

MCP_NAME = "tempo"

mcp = FastMCP("tempo-mcp")


def _base_url() -> str:
    return os.getenv("TEMPO_BASE_URL", "http://localhost:3200").rstrip("/")


def _timeout() -> float:
    return float(os.getenv("TEMPO_TIMEOUT_SECONDS", "30"))


def _headers() -> dict[str, str]:
    headers: dict[str, str] = {}
    org = os.getenv("TEMPO_ORG_ID")
    token = os.getenv("TEMPO_BEARER_TOKEN")
    if org:
        headers["X-Scope-OrgID"] = org
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _get(path: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    url = f"{_base_url()}{path}"
    resp = requests.get(url, params=params, headers=_headers(), timeout=_timeout())
    resp.raise_for_status()
    return resp.json()


@mcp.tool()
def get_trace(trace_id: str) -> dict[str, Any]:
    """Get full trace payload from Tempo by trace ID."""
    return _get(f"/api/traces/{trace_id}")


@mcp.tool()
def search_traces_by_tags(
    tags: dict[str, str],
    start_epoch_seconds: int | None = None,
    end_epoch_seconds: int | None = None,
    limit: int = 20,
) -> dict[str, Any]:
    """Search traces in Tempo using tag filters (legacy search endpoint)."""
    now = int(time.time())
    start = start_epoch_seconds if start_epoch_seconds is not None else now - 3600
    end = end_epoch_seconds if end_epoch_seconds is not None else now

    # Tempo /api/search expects tags in "k=v k2=v2" form.
    tags_expr = " ".join([f"{k}={v}" for k, v in tags.items()])
    return _get(
        "/api/search",
        {
            "tags": tags_expr,
            "start": start,
            "end": end,
            "limit": max(limit, 1),
        },
    )


@mcp.tool()
def search_traces_traceql(
    traceql_query: str,
    start_epoch_seconds: int | None = None,
    end_epoch_seconds: int | None = None,
    limit: int = 20,
) -> dict[str, Any]:
    """Search traces in Tempo using TraceQL query string."""
    now = int(time.time())
    start = start_epoch_seconds if start_epoch_seconds is not None else now - 3600
    end = end_epoch_seconds if end_epoch_seconds is not None else now

    return _get(
        "/api/search",
        {
            "q": traceql_query,
            "start": start,
            "end": end,
            "limit": max(limit, 1),
        },
    )


def smoke_test() -> int:
    try:
        base = _base_url()
        ready = requests.get(f"{base}/ready", headers=_headers(), timeout=_timeout())
        ready.raise_for_status()
        search = search_traces_traceql("{}", limit=1)
        print(
            json.dumps(
                {
                    "server": MCP_NAME,
                    "ok": True,
                    "base_url": base,
                    "ready": ready.text.strip(),
                    "search_sample": search,
                },
                indent=2,
            )
        )
        return 0
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"server": MCP_NAME, "ok": False, "error": str(exc)}, indent=2))
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Tempo MCP wrapper (stdio)")
    parser.add_argument("--smoke-test", action="store_true", help="Run live connectivity test")
    args = parser.parse_args()
    if args.smoke_test:
        return smoke_test()
    mcp.run(transport="stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
