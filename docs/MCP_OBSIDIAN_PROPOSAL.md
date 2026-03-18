# Propuesta: MCP de Obsidian (mcpvault)

**Fecha:** 2026-03-18  
**Estado:** Propuesto (no implementado)  
**MCP relacionado:** Filesystem MCP (ya integrado)

---

## Contexto

El Filesystem MCP ya proporciona acceso al vault de Obsidian en:
```
/mnt/c/Users/jesus/Documents/vault
```

Esto cubre necesidades básicas de lectura/escritura de archivos.

---

## ¿Qué ofrece mcpvault adicional?

| Capacidad | Filesystem MCP | mcpvault |
|-----------|-----------------|----------|
| Leer archivos | ✅ | ✅ |
| Escribir archivos | ✅ | ✅ |
| Buscar por contenido | ❌ | ✅ |
| Gestión de tags | ❌ | ✅ |
| Frontmatter parsing | ❌ | ✅ |
| Metadata de vault | ❌ | ✅ |
| Soporte Obsidian URI | ❌ | ✅ |

---

## Implementación propuesta

### 1. Launcher: `bin/mcp-obsidian-launcher`

```bash
#!/usr/bin/env bash
# MCP Obsidian Launcher
# Provides Obsidian-specific operations via mcpvault

set -euo pipefail

# Default vault path (Windows mount via WSL)
DEFAULT_VAULT="/mnt/c/Users/jesus/Documents/vault"

# Allow override via OBSIDIAN_VAULT env var
VAULT_PATH="${OBSIDIAN_VAULT:-$DEFAULT_VAULT}"

# Validate vault exists
if [[ ! -d "$VAULT_PATH" ]]; then
    echo "ERROR: Vault not found at: $VAULT_PATH" >&2
    echo "       Set OBSIDIAN_VAULT environment variable to override" >&2
    exit 1
fi

exec npx -y "@bitbonsai/mcpvault@latest" "$VAULT_PATH"
```

### 2. Configuración MCP

**Cursor (`dot_cursor/mcp.json.tmpl`):**
```json
"obsidian": {
  "command": "{{ .chezmoi.homeDir }}/.local/share/chezmoi/bin/mcp-obsidian-launcher",
  "args": [],
  "env": {}
}
```

**OpenCode (`dot_config/opencode/opencode.json.tmpl`):**
```json
"obsidian": {
  "type": "local",
  "command": ["{{ .chezmoi.homeDir }}/.local/share/chezmoi/bin/mcp-obsidian-launcher"],
  "enabled": false
}
```

**Codex (`dot_codex/config.toml.tmpl`):**
```toml
[mcp_servers.obsidian]
command = "{{ .chezmoi.homeDir }}/.local/share/chezmoi/bin/mcp-obsidian-launcher"
args = []
enabled = false
```

### 3. Clasificación propuesta

| Capa | Rationale |
|------|-----------|
| **Core** | Herramienta de productividad personal |
| **Enabled** | `false` por defecto (como Platform MCPs) |
| **Wrapper** | Necesario para soportar OBSIDIAN_VAULT override |

---

## Razones para no implementar ahora

1. **Filesystem MCP ya cubre el caso de uso básico**
2. **Requiere desarrollo de launcher adicional** (similar a Git MCP)
3. **Complejidad marginal** para las capacidades adicionales
4. **El vault está en Windows mount** - potenciales problemas de path

---

## Para implementar después

```bash
# 1. Crear launcher
vim ~/dotfiles/bin/mcp-obsidian-launcher

# 2. Añadir a configuración MCP (enabled: false)

# 3. Aplicar
chezmoi --source=$HOME/dotfiles apply

# 4. Probar
npx @bitbonsai/mcpvault /mnt/c/Users/jesus/Documents/vault
```

---

## Referencias

- Repo: https://github.com/bitbonsai/mcpvault
- npm: `@bitbonsai/mcpvault`
- Docs: https://mcpvault.org
