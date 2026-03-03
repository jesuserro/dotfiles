# Migración MCP — Iteración 3

**Fecha:** 2026-03-02

## Objetivo

Layout neutro para MCPs Python en el repo: `mcp/servers/*` y `mcp/requirements.txt`.

## Qué se movió

- **Origen (eliminado):** `codex/mcp/<name>/server.py` y `codex/mcp/requirements.txt` — ya no existe en el repo.
- **Destino:**
  - `mcp/servers/dagster/server.py`
  - `mcp/servers/minio/server.py`
  - `mcp/servers/loki/server.py`
  - `mcp/servers/tempo/server.py`
  - `mcp/servers/prometheus/server.py`
  - `mcp/servers/store_etl_ops/server.py`
  - `mcp/requirements.txt`

El venv está en `~/.config/mcp/.venv`; los templates (`dot_codex/config.toml.tmpl` y el MCP de Cursor del proyecto store-etl) usan:

- `command`: `{{ .chezmoi.homeDir }}/.config/mcp/.venv/bin/python`
- `args`: `{{ .chezmoi.sourceDir }}/mcp/servers/<name>/server.py`

## Migrado después (post-iteración 4)

- **Postgres**: npx `@modelcontextprotocol/server-postgres` (sin .codex).
- **Trino**: `trino-mcp` en `mcp/requirements.txt`, venv `~/.config/mcp/.venv`.

## Qué NO se movió (pendiente)

- **Docker** MCP: sigue en `~/.codex/mcp/docker/` (runtime desacoplado).
- Symlinks en HOME ni `~/.config/mcp/servers` (queda para iteración posterior).

## Referencia

- [CHEZMOI.md](CHEZMOI.md) — referencia principal Chezmoi + SOPS + Age.
- [MIGRATION_MCP_CHEZMOI.md](MIGRATION_MCP_CHEZMOI.md) — migración MCP.
- `STRUCTURE.md`: árbol actualizado con `mcp/servers` y `codex/` solo config + docs (sin `codex/mcp`).
- Config global Codex: `dot_codex/config.toml.tmpl`.
- Config Cursor store-etl: `private_proyectos/store-etl/dot_cursor/mcp.json.tmpl` y `private_dot_config/store-etl/store-etl.mcp.json.tmpl`.
