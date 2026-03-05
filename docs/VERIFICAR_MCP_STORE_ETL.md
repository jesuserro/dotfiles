# Verificar MCPs en store-etl

Comprobaciones tras `chezmoi apply` para dotfiles y proyecto store-etl.

---

## 1. Desde terminal (dotfiles)

```bash
# Trino MCP — debe arrancar sin error
~/.config/ai/runtime/.venv/bin/python -m trino_mcp --help

# Postgres MCP — requiere DSN (source codex.env)
source ~/.secrets/codex.env
npx -y @modelcontextprotocol/server-postgres "$POSTGRES_DSN"
# (Ctrl+C para salir; si Postgres no está en marcha, fallará la conexión)
```

---

## 2. En Cursor (proyecto store-etl)

1. Abrir Cursor en `~/proyectos/store-etl`
2. Verificar que los MCPs aparecen: postgres, trino, dagster, minio, etc.
3. Probar herramientas:
   - **Postgres**: `list_tables` o `query` (si Postgres está en marcha)
   - **Trino**: `list_catalogs` o `execute_query_read_only` (si Trino está en localhost:8080)

---

## 3. Prompt para agente en store-etl

Copia y pega en un chat de Cursor dentro del proyecto store-etl:

```
Verifica que los MCPs de store-etl funcionan:

1. Lista los MCPs disponibles en este proyecto (revisa .cursor/mcp.json).
2. Si Postgres MCP está activo: usa list_tables o una query simple para comprobar conexión.
3. Si Trino MCP está activo: usa list_catalogs o execute_query_read_only con "SELECT 1".
4. Confirma que postgres usa npx @modelcontextprotocol/server-postgres y trino usa ~/.config/ai/runtime/.venv (trino-mcp).

Resume el resultado: qué MCPs responden OK y cuáles fallan (y por qué).
```

---

## Configuración actual (post-migración)

| MCP      | Comando / Origen                                      |
|----------|--------------------------------------------------------|
| postgres | npx @modelcontextprotocol/server-postgres + POSTGRES_DSN |
| trino    | ~/.config/ai/runtime/.venv + trino_mcp                        |
| dagster  | ~/.config/ai/runtime/.venv + ai/runtime/mcp/servers/dagster/server.py   |
| minio    | ~/.config/ai/runtime/.venv + ai/runtime/mcp/servers/minio/server.py     |
