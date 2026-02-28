# Loki MCP wrapper

Local stdio MCP wrapper for Grafana Loki query API.
Default query matcher for examples: `{service_name=~".+"}` (Loki rejects empty `{}` selectors).

## Env vars
- `LOKI_BASE_URL` (default: `http://localhost:3100`)
- `LOKI_TIMEOUT_SECONDS` (default: `30`)
- `LOKI_ORG_ID` (optional)
- `LOKI_BEARER_TOKEN` (optional)

## Smoke test
```bash
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/loki/server.py --smoke-test
```

## Query examples
```text
{service_name=~".+"} |= "hydration"
{job=~".+"} |= "hydration"
```
