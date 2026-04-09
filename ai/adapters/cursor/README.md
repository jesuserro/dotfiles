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

El script `run_after_11_link_ai_assets` expone en `~/.cursor/skills-cursor` el mismo canon publicado en `~/.config/ai/skills`.
