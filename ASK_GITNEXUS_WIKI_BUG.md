## Problema: gitnexus wiki no detecta el índice

Al ejecutar `gitnexus wiki` obtengo "No GitNexus index found" aunque el índice existe.

### Comandos probados y resultados

```bash
# 1. analyze funciona
cd /home/jesus/dotfiles && gitnexus analyze
# Output: Already up to date (248 nodes, 363 edges)

# 2. status funciona y detecta el índice
gitnexus status
# Output:
# Repository: /home/jesus/dotfiles
# Indexed: 3/18/2026, 9:38:01 AM
# Indexed commit: 3d0a7a3
# Current commit: 3d0a7a3
# Status: ✅ up-to-date

# 3. list funciona
gitnexus list
# Output:
# Indexed Repositories (1)
#   dotfiles
#     Path:    /home/jesus/dotfiles
#     Stats:   123 files, 248 symbols, 363 edges

# 4. wiki NO funciona
gitnexus wiki docs/wiki
# Output: Error: No GitNexus index found. Run `gitnexus analyze` first to index this repository.

# 5. wiki con --force tampoco funciona
gitnexus wiki --force docs/wiki
# Output: Error: No GitNexus index found.

# 6. mcp funciona
npx -y gitnexus@latest mcp
# Output: GitNexus: MCP server starting with 1 repo(s): dotfiles
```

### Estado del índice

```bash
# ~/.gitnexus/registry.json
[
  {
    "name": "dotfiles",
    "path": "/home/jesus/dotfiles",
    "storagePath": "/home/jesus/dotfiles/.gitnexus",
    "indexedAt": "2026-03-18T08:38:01.205Z",
    "stats": { "files": 123, "nodes": 248, "edges": 363 }
  }
]

# /home/jesus/dotfiles/.gitnexus/
# - lbug (26MB)
# - meta.json
```

### Preguntas

1. ¿Es un bug en gitnexus?
2. ¿Hay alguna forma de generar la wiki manualmente?
3. ¿Dónde guarda gitnexus el índice y por qué wiki no lo encuentra?

### Entorno
- gitnexus versión: 1.4.5
- OS: Ubuntu (WSL)
- Instalación: npm --prefix=$HOME/.local
