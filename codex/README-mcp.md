# MCP servers for Codex (dotfiles)

This repo now includes local stdio MCP wrappers for:
- Dagster
- MinIO/S3
- Tempo (OTEL traces)
- Loki (LogQL)

Existing MCPs in `codex/config.toml` were left unchanged.

## Installed components

- Shared Python venv for MCP wrappers:
  - `/home/jesus/dotfiles/codex/mcp/.venv`
- Shared Python dependencies file:
  - `/home/jesus/dotfiles/codex/mcp/requirements.txt`
- Servers:
  - `/home/jesus/dotfiles/codex/mcp/dagster/server.py`
  - `/home/jesus/dotfiles/codex/mcp/minio/server.py`
  - `/home/jesus/dotfiles/codex/mcp/tempo/server.py`
  - `/home/jesus/dotfiles/codex/mcp/loki/server.py`

## Required environment variables

Set in your shell profile (`~/.zshrc.local` or equivalent):

```bash
# Dagster
export DAGSTER_GRAPHQL_URL="http://localhost:3000/graphql"
export DAGSTER_TIMEOUT_SECONDS="30"

# MinIO/S3
# MinIO se configura leyendo `~/.secrets/codex.env`, que a su vez es un
# symlink a `~/.config/store-etl/secrets.env` generado por Chezmoi+SOPS.
# Las variables relevantes son:
# - MINIO_ENDPOINT (por defecto http://localhost:9000)
# - MINIO_ACCESS_KEY
# - MINIO_SECRET_KEY
# - MINIO_SECURE (false para HTTP local)

# Tempo
export TEMPO_BASE_URL="http://localhost:3200"
export TEMPO_TIMEOUT_SECONDS="30"
# Optional multi-tenant/auth
# export TEMPO_ORG_ID="1"
# export TEMPO_BEARER_TOKEN="<token>"

# Loki
export LOKI_BASE_URL="http://localhost:3100"
export LOKI_TIMEOUT_SECONDS="30"
# Optional multi-tenant/auth
# export LOKI_ORG_ID="1"
# export LOKI_BEARER_TOKEN="<token>"
```

## Install/reinstall dependencies

```bash
cd /home/jesus/dotfiles/codex/mcp
python3 -m venv .venv
./.venv/bin/pip install --upgrade pip
./.venv/bin/pip install -r requirements.txt
```

## Smoke tests

Each command starts the server code and performs one live API call:

```bash
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/dagster/server.py --smoke-test
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/minio/server.py --smoke-test
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/tempo/server.py --smoke-test
/home/jesus/dotfiles/codex/mcp/.venv/bin/python /home/jesus/dotfiles/codex/mcp/loki/server.py --smoke-test
```

For Loki queries, use a non-empty matcher:
```text
{service_name=~".+"} |= "hydration"
{job=~".+"} |= "hydration"
```

## Troubleshooting quick notes

- `Connection refused` / `Max retries exceeded`: target service is not running or wrong host/port.
- `401/403`: missing or invalid credentials/token.
- MinIO `InvalidAccessKeyId` or `SignatureDoesNotMatch`: check key/secret/secure flag.
- Dagster GraphQL errors: verify repository/job/asset identifiers and GraphQL endpoint.
- Tempo or Loki empty results with HTTP 200: query works, but no data in selected time range.

## How to apply via dotfiles

From your dotfiles workspace:

```bash
cd /home/jesus/dotfiles
rcup
```

That keeps `~/.codex/config.toml` synced from this repo.
