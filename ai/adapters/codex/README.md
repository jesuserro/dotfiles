# Codex Adapter

Wiring específico para integrar el hub AI con Codex.

## Rutas

| Destino | Origen |
|---------|--------|
| `~/.codex/skills` | `~/.config/ai/skills` |
| `~/.codex/config.toml` | `dot_codex/config.toml.tmpl` |

## Variables

- `{{ .chezmoi.homeDir }}`: directorio home del usuario
- `{{ .chezmoi.sourceDir }}`: ruta al repo dotfiles

## Skills

El script `run_after_11_link_ai_assets` crea el symlink `~/.codex/skills` → `~/.config/ai/skills` automáticamente.

Codex usa `$CODEX_HOME/skills` (por defecto `~/.codex/skills`).
