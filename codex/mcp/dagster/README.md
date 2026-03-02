# Dagster MCP wrapper

Local stdio MCP wrapper for Dagster GraphQL API.

## Env vars
- `DAGSTER_GRAPHQL_URL` (default: `http://localhost:3000/graphql`)
- `DAGSTER_TIMEOUT_SECONDS` (default: `30`)

## Smoke test
```bash
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/dagster/server.py --smoke-test
```
