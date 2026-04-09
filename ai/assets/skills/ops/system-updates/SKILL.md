---
name: dotfiles-ups-workflow
description: Guides development and extension of the ups system update alias. Use when working with the ups command, editing aliases for system updates, adding new MCP servers to the update flow, or extending the dotfiles update workflow.
---

# Dotfiles UPS Workflow

Guía para desarrollar y extender el alias `ups` de actualización integral del sistema.

## Ubicación y carga

- **Definición:** `~/dotfiles/aliases` (función `ups()` y helpers `_ups_*`)
- **Carga:** Via `~/.zshrc` → `~/.config/rcm/rcrc` (RCM)
- **Documentación:** [docs/UPS.md](../../../docs/UPS.md)

## Estructura de la función ups()

Orden de ejecución (no alterar sin motivo):

1. **🔐 Autenticación sudo** — `sudo -v`
2. **📦 APT** — `apt-get update`, `apt-get upgrade`, `apt-get autoremove`
3. **🧹 Limpieza** — (parte de APT)
4. **📚 NPM** — `npm update -g codex`
5. **⚡ Oh My Zsh** — `omz update`, `upgrade_oh_my_zsh_custom`
6. **🔌 MCP** — excalidraw, npm servers, uv fetch, Python venv
7. **🔄 Servicios** — `restart_apache` (Apache + MySQL)

## Convenciones de código

### Variables y funciones auxiliares

- Prefijo `_ups_` para todo lo interno (colores, helpers).
- Colores: `_ups_green`, `_ups_yellow`, `_ups_red`, `_ups_blue`, `_ups_cyan`, `_ups_magenta`, `_ups_bold`, `_ups_nc`.
- Helpers: `_ups_section()`, `_ups_success()`, `_ups_error()`, `_ups_info()`, `_ups_warning()`, `_ups_progress()`.

### Manejo de errores

- Cada sección usa `if ...; then ... else ... fi`.
- Errores críticos: `((errors++))` y `error_messages+=("mensaje")`.
- Fallos no críticos: `_ups_warning()` sin incrementar `errors`.
- Si una sección falla, el proceso continúa. El resumen final lista todos los errores.

### Patrón para añadir una nueva sección

```bash
_ups_section "🔌 Título de la sección"
_ups_progress "Descripción del paso..."
local mcp_start=$(date +%s)
if (comando_a_ejecutar); then
  local mcp_time=$(($(date +%s) - mcp_start))
  _ups_success "Mensaje de éxito (${mcp_time}s)"
else
  _ups_warning "Mensaje de fallo (o _ups_error si es crítico)"
  ((errors++))
  error_messages+=("Descripción del error")
fi
```

## Servidores MCP actualizados por ups

| Origen | Ruta / Comando |
|--------|----------------|
| excalidraw | `~/mcp-servers/excalidraw-mcp` — git pull + pnpm install + build |
| docker, postgres | `~/.config/mcp/servers/*/` — npm update |
| fetch | `uv tool install mcp-server-fetch` |
| Python (dagster, minio, etc.) | `pip install -r requirements.txt -U` en `~/.config/ai/runtime/.venv` |
| context7, github | npx — no requieren actualización |

## Añadir un nuevo MCP a la sección de ups

1. Verificar si el MCP existe en la ruta esperada.
2. Añadir el bloque siguiendo el patrón de `_ups_section` + `_ups_progress` + condicional.
3. Actualizar [docs/UPS.md](../../../docs/UPS.md) en la tabla de servidores MCP.
4. Actualizar [docs/GUIA_MCP_AI.md](../../../docs/GUIA_MCP_AI.md) sección 7 si aplica.

## Termux

En Termux, `ups` es un alias diferente: `pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom`. Ver `termux/install.sh`.

## Checklist al modificar ups

- [ ] Mantener convenciones `_ups_*`
- [ ] Usar helpers para output (no `echo` directo con colores)
- [ ] Errores críticos incrementan `errors` y añaden a `error_messages`
- [ ] Actualizar docs/UPS.md si cambia la estructura
- [ ] Probar en entorno real antes de commit
