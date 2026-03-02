#!/usr/bin/env python3
import argparse
import json
import os
import time
from typing import Any

import requests
from mcp.server.fastmcp import FastMCP

MCP_NAME = "loki"

mcp = FastMCP("loki-mcp")
FALLBACK_MATCHER = '{service_name=~".+"}'


def _base_url() -> str:
    return os.getenv("LOKI_BASE_URL", "http://localhost:3100").rstrip("/")


def _timeout() -> float:
    return float(os.getenv("LOKI_TIMEOUT_SECONDS", "30"))


def _headers() -> dict[str, str]:
    headers: dict[str, str] = {}
    org = os.getenv("LOKI_ORG_ID")
    token = os.getenv("LOKI_BEARER_TOKEN")
    if org:
        headers["X-Scope-OrgID"] = org
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _to_nanos(epoch_seconds: int) -> str:
    return str(epoch_seconds * 1_000_000_000)


def _query_range(params: dict[str, Any]) -> dict[str, Any]:
    url = f"{_base_url()}/loki/api/v1/query_range"
    resp = requests.get(url, params=params, headers=_headers(), timeout=_timeout())
    resp.raise_for_status()
    return resp.json()


def _normalize_query(query: str) -> str:
    normalized = query.strip()
    if normalized == "{}":
        return FALLBACK_MATCHER
    if normalized.startswith("{}"):
        return normalized.replace("{}", FALLBACK_MATCHER, 1).strip()
    return query


@mcp.tool()
def query_logql(
    query: str,
    start_epoch_seconds: int | None = None,
    end_epoch_seconds: int | None = None,
    limit: int = 200,
    direction: str = "backward",
) -> dict[str, Any]:
    """Run a LogQL query over a time range."""
    normalized_query = _normalize_query(query)
    now = int(time.time())
    start = start_epoch_seconds if start_epoch_seconds is not None else now - 3600
    end = end_epoch_seconds if end_epoch_seconds is not None else now
    params = {
        "query": normalized_query,
        "start": _to_nanos(start),
        "end": _to_nanos(end),
        "limit": max(limit, 1),
        "direction": direction,
    }
    return _query_range(params)


def smoke_test() -> int:
    try:
        ready = requests.get(f"{_base_url()}/ready", headers=_headers(), timeout=_timeout())
        ready.raise_for_status()
        sample = query_logql('{job=~".+"}', limit=5)
        print(
            json.dumps(
                {
                    "server": MCP_NAME,
                    "ok": True,
                    "base_url": _base_url(),
                    "ready": ready.text.strip(),
                    "sample_status": sample.get("status"),
                    "streams": len(sample.get("data", {}).get("result", [])),
                },
                indent=2,
            )
        )
        return 0
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"server": MCP_NAME, "ok": False, "error": str(exc)}, indent=2))
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Loki MCP wrapper (stdio)")
    parser.add_argument("--smoke-test", action="store_true", help="Run live connectivity test")
    args = parser.parse_args()
    if args.smoke_test:
        return smoke_test()
    mcp.run(transport="stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
