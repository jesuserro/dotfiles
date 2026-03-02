# Codex MCP Postgres (local)

Servidor MCP PostgreSQL local compatible con el runtime actual de Codex.

## Archivos

- `server.mjs`: servidor MCP por `stdio`
- `package.json`: metadatos y dependencias
- `package-lock.json`: lockfile para instalación reproducible

## Instalación (después de `rcup`)

```bash
source ~/.zshrc
cd ~/.codex/mcp/postgres
npm install
```

## Activación de dotfiles

```bash
source ~/.zshrc
rcup -v
```

## Configuración esperada

La configuración real de MCPs ahora la gestiona **Chezmoi** a través de
`~/.codex/config.toml`, generado desde `dot_codex/config.toml`.

El bloque relevante para Postgres es:

```toml
[mcp_servers.postgres]
command = "/usr/bin/bash"
args = ["-lc", "source ~/.secrets/codex.env 2>/dev/null; exec /usr/bin/node /home/jesus/.codex/mcp/postgres/server.mjs"]
enabled = true
```

La variable `POSTGRES_DSN` se inyecta desde `~/.config/store-etl/secrets.env`
→ `~/.secrets/codex.env`, gestionados por Chezmoi + SOPS + Age (ver
`docs/MIGRATION_MCP_CHEZMOI.md`).
