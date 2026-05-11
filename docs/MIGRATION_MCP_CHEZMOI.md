# Migración MCP a Chezmoi + SOPS + Age

Este documento describe la migración inicial de la gestión de MCPs (Cursor/Codex) a **Chezmoi** con secretos cifrados con **SOPS** y **Age**.

> **Estado actual:** Chezmoi gestiona también los RC files de la zsh stack (`~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`). RCM/rcup queda fuera del flujo activo. Ver [CHEZMOI.md](CHEZMOI.md) para el alcance vigente.

📖 **Referencia principal:** [CHEZMOI.md](CHEZMOI.md)

---

## Restricciones (alcance original de la migración MCP)

- **Solo** se gestionaban con Chezmoi:
  - `~/.cursor/mcp.json` (MCPs globales: excalidraw, context7, docker, github, fetch)
  - `~/.codex/config.toml`
  - Symlink `~/.secrets/codex.env` → `~/.config/store-etl/secrets.env`
- Los servidores MCP Python están en `~/dotfiles/ai/runtime/mcp/servers/**`; runtime en `~/.config/ai/runtime/`.
- Secreto canónico: `~/.config/store-etl/secrets.env` (generado desde `secrets.sops.yaml`).

---

## Detalles MCP

Para requisitos, uso de Chezmoi, configuración Age+SOPS y estructura de secretos, ver [CHEZMOI.md](CHEZMOI.md).

---

## MCPs globales vs proyecto Store ETL

- **Global** (`~/.cursor/mcp.json`): excalidraw, context7, docker, github, fetch. Cualquier repo solo ve estos.
- **Store ETL** (`/home/jesus/proyectos/store-etl/.cursor/mcp.json`): postgres, trino, dagster, minio, tempo, loki, prometheus, store_etl_ops. Solo al abrir Cursor en ese proyecto.

---

## Validación

1. `chezmoi --source=$HOME/dotfiles apply`
2. Abrir Cursor en otro repo → solo MCP global.
3. Abrir Cursor en store-etl → MCPs específicos del proyecto.
4. Comprobar: GitHub MCP, Postgres MCP, MinIO MCP, Dagster.

---

## No hacer

- Postgres: npx. Trino: venv mcp. Docker: `~/.codex/mcp/docker` si existe.
- No reintroducir RCM/rcup en el flujo activo.
- No mover los servidores MCP de `ai/runtime/mcp/`.
