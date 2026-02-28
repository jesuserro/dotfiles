# Tempo MCP wrapper

Local stdio MCP wrapper for Grafana Tempo HTTP API.

## Env vars
- `TEMPO_BASE_URL` (default: `http://localhost:3200`)
- `TEMPO_TIMEOUT_SECONDS` (default: `30`)
- `TEMPO_ORG_ID` (optional)
- `TEMPO_BEARER_TOKEN` (optional)

## Smoke test
```bash
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/tempo/server.py --smoke-test
```
