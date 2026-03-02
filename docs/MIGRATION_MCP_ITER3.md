# Migración MCP — Iteración 3

**Fecha:** 2026-03-02

## Objetivo

Layout neutro para MCPs Python en el repo: `mcp/servers/*` y `mcp/requirements.txt`.

## Qué se movió

- **Origen:** `codex/mcp/<name>/server.py` y `codex/mcp/requirements.txt`
- **Destino:**
  - `mcp/servers/dagster/server.py`
  - `mcp/servers/minio/server.py`
  - `mcp/servers/loki/server.py`
  - `mcp/servers/tempo/server.py`
  - `mcp/servers/prometheus/server.py`
  - `mcp/servers/store_etl_ops/server.py`
  - `mcp/requirements.txt`

El venv sigue en `codex/mcp/.venv`; los templates (`dot_codex/config.toml.tmpl` y el MCP de Cursor del proyecto store-etl) usan:

- `command`: `{{ .chezmoi.sourceDir }}/codex/mcp/.venv/bin/python` (sin cambios)
- `args`: `{{ .chezmoi.sourceDir }}/mcp/servers/<name>/server.py` (nueva ruta)

## Qué NO se movió (Iteración 4)

- MCPs instalados en HOME: **postgres**, **trino**, **docker** (siguen en `~/.codex/mcp/...`).
- Symlinks en HOME ni `~/.config/mcp/servers` (queda para una iteración posterior).

## Referencia

- `STRUCTURE.md`: árbol actualizado con `mcp/servers` y código Python fuera de `codex/mcp` para estos servidores.
- Config global Codex: `dot_codex/config.toml.tmpl`.
- Config Cursor store-etl: `private_proyectos/store-etl/dot_cursor/mcp.json.tmpl` y `private_dot_config/store-etl/store-etl.mcp.json.tmpl`.
