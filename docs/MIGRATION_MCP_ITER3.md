# Migración MCP — Iteración 3 (AI Workstation)

**Fecha:** 2026-03-05

## Estado actual

Los servidores MCP Python están en `ai/runtime/mcp/` dentro del AI Workstation Framework. Ya no existe `mcp/` en la raíz del repo.

## Estructura

```
ai/runtime/mcp/
  requirements.txt
  servers/
    dagster/server.py
    minio/server.py
    loki/server.py
    prometheus/server.py
    store_etl_ops/server.py
    tempo/server.py
```

- **Venv:** `~/.config/ai/runtime/.venv`
- **Templates:** `dot_codex/private_config.toml.tmpl`; project-specific `store-etl` MCP configuration lives in the `store-etl` repository, not in dotfiles.
- **Rutas en templates:**
  - `command`: `{{ .chezmoi.homeDir }}/.config/ai/runtime/.venv/bin/python`
  - `args`: `{{ .chezmoi.sourceDir }}/ai/runtime/mcp/servers/<name>/server.py`

## Referencias

- [CHEZMOI.md](CHEZMOI.md) — referencia principal
- [MIGRATION_MCP_CHEZMOI.md](MIGRATION_MCP_CHEZMOI.md) — migración MCP
- [GUIA_MCP_AI.md](GUIA_MCP_AI.md) — guía práctica con comandos
- [ai/README.md](../ai/README.md) — arquitectura AI Workstation
