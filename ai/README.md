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

~/.config/opencode/skills/   # surface linked to the shared skills hub
~/.cursor/skills-cursor/     # surface linked to the shared skills hub
~/.codex/skills/            # surface linked to the shared skills hub
```

No editar en surfaces. Todos los cambios en `ai/assets/skills/`.

## Taxonomía visible de skills

Los títulos visibles siguen procedencia semántica:

- `Vault ...` para skills propios cuyo origen conceptual está en `vault_trabajo`
- `Dotfiles ...` para skills propios transversales mantenidos en este repo y no claramente derivados del vault
- marca original para terceros, como `GitNexus ...`
- familias de proyecto como `Store ETL ...` reservadas para repos concretos

> **Nota:** `.claude/skills/` es una convención de nombre compartida por Claude Code y OpenCode. No implica que el repo soporte a Claude — es solo el nombre del directorio que ambos herramientas usan para skills. Los skills de este repo viven en `ai/assets/skills/` y se symlinkean a las rutas que cada plataforma espera.

## Adapters

El directorio `ai/adapters/` documenta el wiring específico de cada agente. Contiene adapters simples para Codex y Cursor. OpenCode tiene documentación completa en `docs/OPENCODE.md` y no requiere adapter adicional aquí.

## Añadir skills

1. Clonar o copiar el skill en `ai/assets/skills/<category>/<skill-name>/`
2. El skill debe contener `SKILL.md` (formato Cursor/Codex) o equivalente
3. Si clonas un repo externo: `git clone <url> ai/assets/skills/<category>/<skill-name>` y luego `rm -rf ai/assets/skills/<category>/<skill-name>/.git` para trackear los archivos
4. Tras `chezmoi apply`, el script `run_after_11_link_ai_assets` publica los skills a cada agente

### Skills instalados

| Categoría | Skill | Descripción |
|-----------|-------|-------------|
| `diagrams/` | `excalidraw/` | Creación/edición de diagramas Excalidraw vía MCP Docker |
| `diagrams/` | `conventions/` | Convenciones de diagramación |
| `docs/` | `adr-writer/` | `Dotfiles ADR Writer` |
| `docs/` | `excalidraw-publishing/` | `Dotfiles Excalidraw Publishing` |
| `docs/` | `plans-and-notepads-naming/` | `Dotfiles Plans and Notepads Naming` |
| `etl/` | `data-contracts/` | Contratos de datos transversales |
| `git/` | `pr-conventions/` | Convenciones de PR y commits |
| `gitnexus/` | `gitnexus-*` | Skills de `GitNexus` con marca original |
| `ops/` | `ai-prompt-consumer/` | `Vault AI Prompt Consumer` |
| `ops/` | `dotfiles-skill-registration/` | `Dotfiles Skill Registration` |
| `ops/` | `vault-development-acceleration/` | `Vault Development Acceleration` |
| `ops/` | `vault-review-diff/` | `Vault Review Diff` |
| `ops/` | `vault-detect-errors/` | `Vault Detect Errors` |
| `ops/` | `vault-suggest-improvements/` | `Vault Suggest Improvements` |
| `ops/` | `vault-project-wiki/` | `Vault Project Wiki` |
| `ops/` | `vault-update-documentation/` | `Vault Update Documentation` |
| `ops/` | `vault-write-commit-message/` | `Vault Write Commit Message` |
| `ops/` | `mcp-governance/` | `Dotfiles MCP Governance` |
| `ops/` | `playwright-ui-validation/` | `Dotfiles Playwright UI Validation` |
| `ops/` | `system-updates/` | `Dotfiles Update Workflow` |
| `ops/` | `excalidraw-mcp-operations/` | `Dotfiles Excalidraw MCP Operations` |
| `ops/` | `wsl2-local-tools/` | `Dotfiles WSL2 Local Tools` |
| `ops/` | `agent-workflow/` | `Dotfiles Agent Workflow` (mapa de familia) |
| `ops/` | `grill-plan/` | `Dotfiles Grill Plan` |
| `ops/` | `to-spec/` | `Dotfiles To Spec` |
| `ops/` | `to-issues/` | `Dotfiles To Issues` |
| `ops/` | `test-driven-change/` | `Dotfiles Test Driven Change` |
| `ops/` | `architecture-review/` | `Dotfiles Architecture Review` |
| `ops/` | `vault-issue-bridge/` | `Dotfiles Vault Issue Bridge` |
| `postgres/` | `schema-review/` | Guía de revisión de esquemas |
| `postgres/` | `sql-style/` | Estilo SQL general |
| `python/` | `project-structure/` | Estructura de proyectos Python |

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

Los prompt launchers exponen una CLI mínima para leer prompts canónicos externos desde el vault de trabajo, sin duplicarlos dentro de `dotfiles`. El catálogo sigue centralizado en el helper compartido y se consume vía `ai-prompt`.

Referencias:

- sistema y contrato humano: [docs/AI_PROMPTS_SYSTEM.md](../docs/AI_PROMPTS_SYSTEM.md)
- referencia operativa corta: [docs/PROMPT_LAUNCHERS.md](../docs/PROMPT_LAUNCHERS.md)
- guía reutilizable para agentes: `Vault AI Prompt Consumer` → [ai/assets/skills/ops/ai-prompt-consumer/SKILL.md](assets/skills/ops/ai-prompt-consumer/SKILL.md)
- wrappers operativos derivados del vault: `Vault Development Acceleration`, `Vault Review Diff`, `Vault Detect Errors`, `Vault Suggest Improvements`, `Vault Update Documentation`, `Vault Write Commit Message`, `Vault Project Wiki`

## Agent workflow (vault + issues + repo)

Tutorial paso a paso: [Agent Workflow Loop](../docs/AGENT_WORKFLOW_LOOP.md).

Guía operativa para agentes IA (orquestación, delegación, política `gh`/CLI): [AGENT_WORKFLOW_FOR_AGENTS.md](AGENT_WORKFLOW_FOR_AGENTS.md).

Flujo transversal documentado en `Dotfiles Agent Workflow` → [ai/assets/skills/ops/agent-workflow/SKILL.md](assets/skills/ops/agent-workflow/SKILL.md): de idea a Grill Report, spec en vault, issues en Markdown para GitHub, implementación guiada por tests del repo, y notas en vault. Los artefactos bajo `projects/<project>/knowledge/reports/` viven en `vault_trabajo` (resolver raíz con `AI_PROMPTS_VAULT_ROOT`). No requiere cambios en Chezmoi: `run_after_11` ya enlaza la categoría `ops/`.

## Vault project wiki

Cuando una implementación relevante deja conocimiento reutilizable, el repo no debe absorber toda esa memoria operativa. La fuente de verdad de implementación sigue en el proyecto; la wiki destilada vive en `vault_trabajo/projects/<project>/knowledge/...`; y `dotfiles` aporta la guía transversal para que los agentes sepan cuándo capturarla y cómo hacerlo sin duplicar el repo.

Referencias:

- flujo humano corto: [docs/VAULT_PROJECT_WIKI_FLOW.md](../docs/VAULT_PROJECT_WIKI_FLOW.md)
- skill operativa: `Vault Project Wiki` → [ai/assets/skills/ops/vault-project-wiki/SKILL.md](assets/skills/ops/vault-project-wiki/SKILL.md)

## Añadir un nuevo MCP servidor

Ver [docs/GUIA_MCP_AI.md](../docs/GUIA_MCP_AI.md) — sección "Añadir un nuevo MCP servidor Python".
