---
name: dotfiles-excalidraw-mcp-operations
description: Operate the canonical Docker-based yctimlin/mcp_excalidraw setup in dotfiles; use for starting, stopping, updating, diagnosing, and wiring Excalidraw MCP.
---

# Dotfiles Excalidraw MCP Operations

The canonical implementation is `yctimlin/mcp_excalidraw` via published Docker images.

## When to Use

Use this skill when an agent needs to start, stop, update, diagnose, or configure the Excalidraw MCP runtime in dotfiles.

## Canonical Runtime

- Canvas image: `ghcr.io/yctimlin/mcp_excalidraw-canvas:latest`
- MCP image: `ghcr.io/yctimlin/mcp_excalidraw:latest`
- MCP clients launch the server ephemerally with `docker run -i --rm`
- The canvas uses stable host URL `http://127.0.0.1:3210`
- Docker maps host `3210` to the container's internal `3000` port (`3210:3000`)
- The MCP container connects to the canvas through `EXPRESS_SERVER_URL=http://host.docker.internal:3210`
- Host port `3000` is reserved for Store ETL/Dagster
- `ENABLE_CANVAS_SYNC=true` is enabled in MCP configs

Do not clone, `npm install`, `pnpm install`, Bun install, Vite build, TypeScript build, or depend on `~/mcp-servers/excalidraw-mcp/dist/index.js` for normal operation.

## Make Targets

- `make excalidraw-start` — start canvas idempotently
- `make excalidraw-stop` — stop canvas tolerantly
- `make excalidraw-status` — show Docker readiness and canvas URL
- `make excalidraw-update` — pull canvas and MCP images without keeping canvas running

`make update` may update images but must not start the canvas.

## Diagnostics

1. Run `make excalidraw-status`.
2. If Docker does not respond, open Docker Desktop on Windows.
3. Run `make excalidraw-update` to refresh images.
4. Run `make ai-mcp-governance` to validate manifest and templates.
5. After template changes, run `make ai-mcp-generate APPLY=1` and then `chezmoi --source=$HOME/dotfiles apply`.

Historical local checkouts can be removed manually after validating the Docker migration; update scripts must not delete HOME directories.
