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
