# AI Adapters

Capa de adaptación entre el contenido canónico de dotfiles y las convenciones de cada plataforma AI.

## Arquitectura

```
ai/assets/commands/    ← Canonical content (source of truth)
ai/adapters/          ← Platform adapters (formato por plataforma)
dot_config/           ← Generated artifacts (derivados finales)
```

## Adapters Disponibles

| Platform | Template | Propósito |
|----------|----------|-----------|
| `opencode` | `opencode/TEMPLATE.md` | Slash commands con frontmatter YAML |
| `cursor` | `cursor/TEMPLATE.md` | Slash commands en Markdown simple |
| `codex` | `codex/TEMPLATE.md` | Prompts personalizados con frontmatter YAML |

## Uso

Los adapters son utilizados por `scripts/generate-commands.sh` para producir los artefactos finales en `dot_config/`.

## Añadir un Nuevo Adapter

1. Crear `ai/adapters/<platform>/TEMPLATE.md` con el formato esperado
2. Añadir el platform al registry en `ai/assets/commands/registry.yaml`
3. Asegurar que `generate-commands.sh` handle el nuevo platform
4. Regenerar: `./scripts/generate-commands.sh`

## Relación con Skills

Este directorio también contiene wiring para skills (MCP servers, symlinks, etc.) en subdirectorios específicos de plataforma. Ver cada subdirectorio para detalles.
