---
name: mcp-governance
description: Guides classification, integration and maintenance of MCP servers following the layered architecture. Use when adding, modifying or auditing MCP configuration in the dotfiles.
---

# MCP Governance

Guía para mantener la arquitectura de MCPs según la convención de capas.

## Referencia rápida

| Capa | Scope | enabled | Ejemplos |
|------|-------|---------|----------|
| **Core Workstation** | Todos proyectos | `true` | docker, github, fetch, context7, excalidraw, playwright |
| **Platform** | Todos proyectos (opt-in) | `false` | dagster, loki, minio, prometheus, tempo, store_etl_ops |
| **Connection-Specific** | Solo proyecto | per-project | postgres, trino |

## Anti-patterns a evitar

- ❌ DSN hardcodeado en config global
- ❌ MCP de base de datos como "global"
- ❌ Platform MCPs con `enabled: true` por defecto
- ❌ Secrets con nombres de cliente (usar `mcp-secrets.env`)

## Añadir un nuevo MCP

### Paso 1: Clasificar

¿El MCP es transversal a todos los proyectos?
- **Sí** → ¿Depende de servicio local específico?
  - **No** → **Core Workstation** (`enabled: true`)
  - **Sí** → **Platform** (`enabled: false`)
- **No** → ¿Requiere credenciales/DSN project-specific?
  - **Sí** → **Connection-Specific** (config per-project)

### Paso 2: Definir runtime

- **npm/npx**: `npx -y @vendor/package`
- **Python**: `~/.config/ai/runtime/.venv/bin/python -m module`
- **Wrapper**: `~/.local/share/chezmoi/bin/mcp-<name>-launcher`

### Paso 3: Definir conexión

| Tipo | Ubicación |
|------|-----------|
| Core/Platform | `env` block en config global |
| Connection-Specific | `~/.config/mcp-secrets.env` o env block per-project |

### Paso 4: Configurar

**Global** (`dot_config/opencode/opencode.json.tmpl`):
```json
{
  "mcp": {
    "<name>": {
      "command": ["..."],
      "enabled": true|false
    }
  }
}
```

**Project-specific** (`dot_config/<project>/<project>.mcp.json.tmpl`):
```json
{
  "mcpServers": {
    "<name>": {
      "command": "...",
      "env": {}
    }
  }
}
```

## Runtime vs Connection Profile

```
┌─────────────────────┐     ┌─────────────────────┐
│  MCP Tool (shared) │     │  Connection Profile  │
│  - npx package     │     │  - DSN / endpoint   │
│  - python -m       │ ──▶ │  - Credentials      │
│  - wrapper script  │     │  - Catalog/Schema   │
└─────────────────────┘     └─────────────────────┘
```

**Regla**: Runtime puede ser compartido; Connection debe ser project-specific.

## Archivos clave

| Archivo | Propósito |
|---------|-----------|
| `docs/adr/0001-mcp-governance.md` | ADR formal |
| `docs/OPENCODE.md` | Guía operativa |
| `dot_config/opencode/AGENTS.md.tmpl` | Instrucciones para IAs |
| `dot_config/opencode/opencode.json.tmpl` | MCPs globales |
| `dot_config/store-etl/store-etl.mcp.json.tmpl` | MCPs project-specific |

## Verificar configuración

```bash
# Ver MCPs activos
opencode mcp list

# Debuguear un MCP específico
opencode mcp debug <nombre>

# Ver secrets
cat ~/.config/mcp-secrets.env
```

## Checklist al añadir MCP

- [ ] Clasificar en la capa correcta
- [ ] Definir runtime path (compartido)
- [ ] Definir connection profile (project-specific si aplica)
- [ ] Configurar `enabled` correcto
- [ ] Documentar en docs/OPENCODE.md
- [ ] Probar con `opencode mcp debug`
