# Cursor Adapter

Wiring específico para integrar el hub AI con Cursor IDE.

## Rutas

| Destino | Origen |
|---------|--------|
| `~/.cursor/skills` | `~/.config/ai/skills` |
| `~/.cursor/mcp.json` | `dot_cursor/mcp.json.tmpl` |

## Variables

- `{{ .chezmoi.homeDir }}`: directorio home del usuario
- `{{ .chezmoi.sourceDir }}`: ruta al repo dotfiles

## Skills

El script `run_after_11_link_ai_assets` crea el symlink `~/.cursor/skills` → `~/.config/ai/skills` automáticamente.

Si Cursor usa `~/.cursor/skills-cursor` en lugar de `~/.cursor/skills`, ajustar el script en `.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl`.
