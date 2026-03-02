#!/usr/bin/env python3
import argparse
import json
import os
from typing import Any

import boto3
from botocore.client import BaseClient
from mcp.server.fastmcp import FastMCP

MCP_NAME = "minio"

mcp = FastMCP("minio-mcp")


def _env_bool(key: str, default: bool) -> bool:
    value = os.getenv(key)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _s3_client() -> BaseClient:
    endpoint = os.getenv("MINIO_ENDPOINT", "localhost:9000")
    if endpoint.startswith("http://") or endpoint.startswith("https://"):
        endpoint_url = endpoint
    else:
        scheme = "https" if _env_bool("MINIO_SECURE", False) else "http"
        endpoint_url = f"{scheme}://{endpoint}"

    return boto3.client(
        "s3",
        endpoint_url=endpoint_url,
        aws_access_key_id=os.getenv("MINIO_ACCESS_KEY"),
        aws_secret_access_key=os.getenv("MINIO_SECRET_KEY"),
        region_name=os.getenv("MINIO_REGION", "us-east-1"),
    )


@mcp.tool()
def list_objects(bucket: str, prefix: str = "", max_keys: int = 100) -> list[dict[str, Any]]:
    """List objects in a MinIO/S3 bucket by prefix."""
    client = _s3_client()
    resp = client.list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=max(max_keys, 1))
    items = []
    for obj in resp.get("Contents", []):
        items.append(
            {
                "key": obj.get("Key"),
                "size": obj.get("Size"),
                "etag": obj.get("ETag"),
                "last_modified": obj.get("LastModified").isoformat() if obj.get("LastModified") else None,
            }
        )
    return items


@mcp.tool()
def get_object_metadata(bucket: str, key: str) -> dict[str, Any]:
    """Get object metadata using HEAD request."""
    client = _s3_client()
    meta = client.head_object(Bucket=bucket, Key=key)
    return {
        "content_length": meta.get("ContentLength"),
        "content_type": meta.get("ContentType"),
        "etag": meta.get("ETag"),
        "last_modified": meta.get("LastModified").isoformat() if meta.get("LastModified") else None,
        "metadata": meta.get("Metadata", {}),
    }


@mcp.tool()
def get_object(bucket: str, key: str, max_bytes: int = 131072, decode_utf8: bool = True) -> dict[str, Any]:
    """Download object content (up to max_bytes)."""
    client = _s3_client()
    resp = client.get_object(Bucket=bucket, Key=key)
    body = resp["Body"].read(max(max_bytes, 1))
    if decode_utf8:
        payload = body.decode("utf-8", errors="replace")
    else:
        payload = body.hex()
    return {
        "bucket": bucket,
        "key": key,
        "bytes_returned": len(body),
        "payload": payload,
    }


def smoke_test() -> int:
    try:
        client = _s3_client()
        buckets = [b["Name"] for b in client.list_buckets().get("Buckets", [])]
        sample = {"buckets": buckets}
        if buckets:
            sample["objects_sample"] = list_objects(bucket=buckets[0], max_keys=3)
        print(json.dumps({"server": MCP_NAME, "ok": True, "sample": sample}, indent=2))
        return 0
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"server": MCP_NAME, "ok": False, "error": str(exc)}, indent=2))
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="MinIO MCP wrapper (stdio)")
    parser.add_argument("--smoke-test", action="store_true", help="Run live connectivity test")
    args = parser.parse_args()
    if args.smoke_test:
        return smoke_test()
    mcp.run(transport="stdio")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
