#!/usr/bin/env python3
import argparse
import json
import os
from typing import Any

import requests
from mcp.server.fastmcp import FastMCP

MCP_NAME = "dagster"
DEFAULT_GRAPHQL_URL = os.getenv("DAGSTER_GRAPHQL_URL", "http://localhost:3000/graphql")
DEFAULT_TIMEOUT = float(os.getenv("DAGSTER_TIMEOUT_SECONDS", "30"))

mcp = FastMCP("dagster-mcp")


def _graphql(query: str, variables: dict[str, Any] | None = None) -> dict[str, Any]:
    payload = {"query": query, "variables": variables or {}}
    resp = requests.post(
        DEFAULT_GRAPHQL_URL,
        json=payload,
        timeout=DEFAULT_TIMEOUT,
        headers={"Content-Type": "application/json"},
    )
    resp.raise_for_status()
    body = resp.json()
    if "errors" in body and body["errors"]:
        raise RuntimeError(f"Dagster GraphQL errors: {body['errors']}")
    return body.get("data", {})


def _normalize_tags(tags: dict[str, Any] | None) -> list[dict[str, str]]:
    if not tags:
        return []

    normalized: list[dict[str, str]] = []
    allowed = {"batch_id", "source_run_id", "entity_type"}
    for key, value in tags.items():
        if key not in allowed:
            raise ValueError(f"Unsupported tag key '{key}'. Allowed: {sorted(allowed)}")
        if value is None:
            continue
        normalized.append({"key": key, "value": str(value)})
    return normalized


@mcp.tool()
def list_assets(limit: int = 100) -> list[dict[str, Any]]:
    """List Dagster assets via GraphQL assetNodes."""
    query = """
    query ListAssets {
      assetNodes {
        assetKey { path }
        description
        groupName
        opName
        isExecutable
      }
    }
    """
    data = _graphql(query)
    nodes = data.get("assetNodes", [])
    out = []
    for node in nodes[: max(limit, 0)]:
        key_path = node.get("assetKey", {}).get("path", [])
        out.append(
            {
                "asset_key": "/".join(key_path),
                "description": node.get("description"),
                "group_name": node.get("groupName"),
                "op_name": node.get("opName"),
                "is_executable": node.get("isExecutable"),
            }
        )
    return out


@mcp.tool()
def launch_materialization(
    repository_location: str,
    repository_name: str,
    job_name: str,
    asset_keys: list[str],
    run_config: dict[str, Any] | None = None,
    mode: str = "default",
) -> dict[str, Any]:
    """Launch a Dagster run that materializes specific assets through a job."""
    query = """
    mutation LaunchRun($executionParams: ExecutionParams!) {
      launchPipelineExecution(executionParams: $executionParams) {
        __typename
        ... on LaunchRunSuccess {
          run { runId status }
        }
        ... on PythonError { message stack }
        ... on InvalidSubsetError { message }
        ... on RunConfigValidationInvalid { errors { message reason } }
      }
    }
    """
    asset_selection = [{"path": key.split("/")} for key in asset_keys]
    variables = {
        "executionParams": {
            "selector": {
                "repositoryLocationName": repository_location,
                "repositoryName": repository_name,
                "pipelineName": job_name,
                "assetSelection": asset_selection,
            },
            "runConfigData": run_config or {},
            "mode": mode,
        }
    }
    data = _graphql(query, variables)
    result = data.get("launchPipelineExecution", {})
    typename = result.get("__typename")
    if typename != "LaunchRunSuccess":
        return {"ok": False, "result_type": typename, "details": result}
    run = result.get("run", {})
    return {"ok": True, "run_id": run.get("runId"), "status": run.get("status")}


@mcp.tool()
def list_runs(limit: int = 20, statuses: list[str] | None = None) -> list[dict[str, Any]]:
    """Return Dagster run status summary."""
    query = """
    query ListRuns($limit: Int!, $filter: RunsFilter) {
      runsOrError(limit: $limit, filter: $filter) {
        __typename
        ... on Runs {
          results {
            runId
            status
            pipelineName
            startTime
            endTime
          }
        }
        ... on PythonError { message stack }
      }
    }
    """
    run_filter = {"statuses": statuses} if statuses else None
    data = _graphql(query, {"limit": max(limit, 1), "filter": run_filter})
    block = data.get("runsOrError", {})
    if block.get("__typename") != "Runs":
        raise RuntimeError(f"Dagster runs query failed: {block}")
    return block.get("results", [])


@mcp.tool()
def list_runs_by_tags(
    tags: dict[str, Any],
    limit: int = 20,
    statuses: list[str] | None = None,
) -> list[dict[str, Any]]:
    """List runs filtered by Dagster tags (batch_id, source_run_id, entity_type)."""
    query = """
    query ListRunsByTags($limit: Int!, $filter: RunsFilter) {
      runsOrError(limit: $limit, filter: $filter) {
        __typename
        ... on Runs {
          results {
            runId
            status
            pipelineName
            startTime
            endTime
            tags { key value }
          }
        }
        ... on PythonError { message stack }
      }
    }
    """
    run_filter: dict[str, Any] = {}
    normalized_tags = _normalize_tags(tags)
    if normalized_tags:
        run_filter["tags"] = normalized_tags
    if statuses:
        run_filter["statuses"] = statuses

    data = _graphql(query, {"limit": max(limit, 1), "filter": run_filter or None})
    block = data.get("runsOrError", {})
    if block.get("__typename") != "Runs":
        raise RuntimeError(f"Dagster runs-by-tags query failed: {block}")
    return block.get("results", [])


@mcp.tool()
def list_asset_materializations(
    asset_keys: list[str] | None = None,
    limit: int = 20,
    after_cursor: str | None = None,
) -> dict[str, Any]:
    """List recent materialization events, optionally filtered by asset keys."""
    query = """
    query ListAssetMaterializations($runsLimit: Int!, $eventsLimit: Int!, $afterCursor: String) {
      runsOrError(limit: $runsLimit) {
        __typename
        ... on Runs {
          results {
            runId
            pipelineName
            status
            eventConnection(limit: $eventsLimit, afterCursor: $afterCursor) {
              cursor
              hasMore
              events {
                __typename
                ... on MaterializationEvent {
                  runId
                  timestamp
                  message
                  partition
                  stepKey
                  assetKey { path }
                  tags { key value }
                }
              }
            }
          }
        }
        ... on PythonError { message stack }
      }
    }
    """
    safe_limit = max(limit, 1)
    runs_limit = min(max(safe_limit, 5), 100)
    events_limit = min(max(safe_limit, 20), 200)
    data = _graphql(
        query,
        {
            "runsLimit": runs_limit,
            "eventsLimit": events_limit,
            "afterCursor": after_cursor,
        },
    )
    block = data.get("runsOrError", {})
    if block.get("__typename") != "Runs":
        raise RuntimeError(f"Dagster materializations query failed: {block}")

    wanted_keys = {k.strip() for k in (asset_keys or []) if k and k.strip()}
    events: list[dict[str, Any]] = []
    next_cursor = after_cursor
    for run in block.get("results", []):
        conn = run.get("eventConnection") or {}
        if conn.get("cursor"):
            next_cursor = conn["cursor"]
        for event in conn.get("events", []):
            if event.get("__typename") != "MaterializationEvent":
                continue
            path = (event.get("assetKey") or {}).get("path") or []
            asset_key = "/".join(path)
            if wanted_keys and asset_key not in wanted_keys:
                continue
            events.append(
                {
                    "run_id": event.get("runId"),
                    "pipeline_name": run.get("pipelineName"),
                    "run_status": run.get("status"),
                    "timestamp_ms": event.get("timestamp"),
                    "asset_key": asset_key,
                    "partition": event.get("partition"),
                    "step_key": event.get("stepKey"),
                    "message": event.get("message"),
                    "tags": event.get("tags", []),
                }
            )
            if len(events) >= safe_limit:
                return {
                    "items": events,
                    "next_cursor": next_cursor,
                }

    return {
        "items": events,
        "next_cursor": next_cursor,
    }


def smoke_test() -> int:
    try:
        assets = list_assets(limit=3)
        runs = list_runs(limit=3)
        print(
            json.dumps(
                {
                    "server": MCP_NAME,
                    "ok": True,
                    "graphql_url": DEFAULT_GRAPHQL_URL,
                    "assets_sample": assets,
                    "runs_sample": runs,
                },
                indent=2,
            )
        )
        return 0
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"server": MCP_NAME, "ok": False, "error": str(exc)}, indent=2))
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Dagster MCP wrapper (stdio)")
    parser.add_argument("--smoke-test", action="store_true", help="Run live connectivity test")
    args = parser.parse_args()
    if args.smoke_test:
        return smoke_test()
    mcp.run(transport="stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
