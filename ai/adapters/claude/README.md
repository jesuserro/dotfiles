# Claude Adapter

Wiring específico para integrar el hub AI con Claude Code / Claude Desktop.

## Rutas

| Destino | Origen |
|---------|--------|
| `~/.claude/skills` | `~/.config/ai/skills` |

## Variables

- `{{ .chezmoi.homeDir }}`: directorio home del usuario

## Skills

El script `run_after_11_link_ai_assets` crea el symlink `~/.claude/skills` → `~/.config/ai/skills` automáticamente.

Claude Code usa `~/.claude/skills` para skills compatibles.
