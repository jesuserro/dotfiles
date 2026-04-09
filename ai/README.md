# AI Workstation Framework

Hub neutral de infraestructura IA para dotfiles: runtime ejecutable, assets de conocimiento y adapters por agente.

## Arquitectura

```
ai/
  runtime/     # Código ejecutable (MCP servers, runtimes)
  assets/      # Conocimiento consumido por agentes (skills, prompts, rules, commands)
  adapters/    # Wiring específico de cada agente (cursor, codex, opencode)
```

## Principios

| Concepto   | Descripción                                              |
| ---------- | -------------------------------------------------------- |
| **runtime** | Código ejecutable usado por agentes (MCP servers)        |
| **assets**  | Conocimiento consumido por agentes (skills, prompts, rules, commands) |
| **adapters** | Configuración específica de cada IDE/agente             |
| **hub XDG** | `~/.config/ai` como punto central (estándar XDG)         |

## Estructura en el sistema

**Fuente canónica**: `ai/assets/skills/` — editar aquí.

**Surfaces derivadas**: symlinked via `chezmoi apply`:

```
~/.config/ai/
  skills/      # symlink → dotfiles/ai/assets/skills
  prompts/     # symlink → dotfiles/ai/assets/prompts
  rules/       # symlink → dotfiles/ai/assets/rules

~/.config/opencode/skills/   # skills symlinked per-category
~/.cursor/skills-cursor/     # skills symlinked per-category
~/.codex/skills/            # skills symlinked per-category
```

No editar en surfaces. Todos los cambios en `ai/assets/skills/`.

> **Nota:** `.claude/skills/` es una convención de nombre compartida por Claude Code y OpenCode. No implica que el repo soporte a Claude — es solo el nombre del directorio que ambos herramientas usan para skills. Los skills de este repo viven en `ai/assets/skills/` y se symlinkean a las rutas que cada plataforma espera.

## Adapters

El directorio `ai/adapters/` documenta el wiring específico de cada agente. Contiene adapters simples para Codex y Cursor. OpenCode tiene documentación completa en `docs/OPENCODE.md` y no requiere adapter adicional aquí.

## Añadir skills

1. Clonar o copiar el skill en `ai/assets/skills/<nombre-skill>/`
2. El skill debe contener `SKILL.md` (formato Cursor/Codex) o equivalente
3. Si clonas un repo externo: `git clone <url> ai/assets/skills/<nombre>` y luego `rm -rf ai/assets/skills/<nombre>/.git` para trackear los archivos
4. Tras `chezmoi apply`, el script `run_after_11_link_ai_assets` publica los skills a cada agente

### Skills instalados

| Categoría | Skill | Descripción |
|-----------|-------|-------------|
| `diagrams/` | `excalidraw/` | Generador de diagramas Excalidraw |
| `diagrams/` | `conventions/` | Convenciones de diagramación |
| `docs/` | `adr-writer/` | Guía para escribir ADRs |
| `etl/` | `data-contracts/` | Contratos de datos transversales |
| `git/` | `pr-conventions/` | Convenciones de PR y commits |
| `ops/` | `mcp-governance/` | Gobernanza de MCPs |
| `ops/` | `system-workflow/` | Workflow de actualizaciones |
| `postgres/` | `schema-review/` | Guía de revisión de esquemas |
| `postgres/` | `sql-style/` | Estilo SQL general |
| `python/` | `project-structure/` | Estructura de proyectos Python |
| `tools/` | `code-intelligence/` | GitNexus (6 variantes) |

Para más detalles, ver [SKILLS_ARCHITECTURE.md](SKILLS_ARCHITECTURE.md) y [ai/assets/skills/README.md](assets/skills/README.md).

## Separación transversal vs proyecto

| Tipo                     | Ubicación           |
| ------------------------ | ------------------- |
| Herramientas universales | dotfiles/ai/...     |
| Prompts de proyecto X    | repo del proyecto   |

El hub `ai/` contiene solo assets reutilizables entre proyectos.

## Commands

Los commands son utilidades globales invocables con `/<command>`.

| Command | Descripción | Plataforma |
|---------|-------------|------------|
| `sos` | Ayuda general para asistentes IA | opencode |

Para más detalles, ver [docs/COMMANDS_ARCHITECTURE.md](../docs/COMMANDS_ARCHITECTURE.md) y [ai/assets/commands/README.md](assets/commands/README.md).

## Prompt launchers

Los prompt launchers son wrappers mínimos para leer prompts canónicos externos desde el vault de trabajo, sin duplicarlos dentro de `dotfiles`.

Para uso, contrato público y depuración, ver [docs/PROMPT_LAUNCHERS.md](../docs/PROMPT_LAUNCHERS.md).

## Añadir un nuevo MCP servidor

Ver [docs/GUIA_MCP_AI.md](../docs/GUIA_MCP_AI.md) — sección "Añadir un nuevo MCP servidor Python".
