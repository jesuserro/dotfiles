# MinIO MCP wrapper

Local stdio MCP wrapper for MinIO/S3 operations.

## Env vars
- `MINIO_ENDPOINT` (default: `localhost:9000`)
- `MINIO_ACCESS_KEY` (required)
- `MINIO_SECRET_KEY` (required)
- `MINIO_SECURE` (default: `false`)
- `MINIO_REGION` (default: `us-east-1`)

## Smoke test
```bash
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/minio/server.py --smoke-test
```
