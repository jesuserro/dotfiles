# Propuesta: MCP de Obsidian (mcpvault)

**Fecha:** 2026-03-18  
**Estado:** Propuesto (no implementado)  
**MCP relacionado:** Filesystem MCP (ya integrado)

> **Histórico / legado:** Los ejemplos con ruta absoluta fija más abajo son del diseño inicial. La configuración actual del repo usa **`ai.obsidian_vault_path`** en Chezmoi y plantillas MCP generadas con `make ai-mcp-generate APPLY=1` — ver [CHEZMOI.md](./CHEZMOI.md) y [MCP_QUICKREF.md](./MCP_QUICKREF.md).

---

## Contexto

El Filesystem MCP ya proporciona acceso al vault de Obsidian en la ruta configurada (hoy vía Chezmoi `ai.obsidian_vault_path`; ver [CHEZMOI.md](./CHEZMOI.md)):
```
<OBSIDIAN_VAULT_PATH>
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

# Default vault path (Windows mount via WSL) — en el repo real usar dato Chezmoi, no hardcode
DEFAULT_VAULT="<OBSIDIAN_VAULT_PATH>"

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

**Codex (`dot_codex/private_config.toml.tmpl`):**
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
npx @bitbonsai/mcpvault <OBSIDIAN_VAULT_PATH>
```

---

## Referencias

- Repo: https://github.com/bitbonsai/mcpvault
- npm: `@bitbonsai/mcpvault`
- Docs: https://mcpvault.org
