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

`~/.codex/config.toml` debe apuntar a:

```toml
[mcp_servers.postgres]
command = "/usr/bin/node"
args = ["/home/jesus/.codex/mcp/postgres/server.mjs", "${POSTGRES_DSN}"]
enabled = true
```
