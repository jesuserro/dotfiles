# Architecture Decision Records (ADR)

## Propósito

Los ADRs documentan **decisiones técnicas ya tomadas** en dotfiles: contexto, decisión, consecuencias y referencias. Ayudan a humanos y agentes a entender por qué existen ciertos patrones sin redescubrirlos en cada chat.

Plantilla para nuevos ADRs: [template.md](template.md).

Contrato agentes: [docs/AGENT_WORKFLOW.md](../AGENT_WORKFLOW.md).

## Convenciones

- Numeración secuencial de cuatro dígitos: `0001`, `0002`, …
- **Accepted** — decisión vigente (implementada o pointer con dirección aprobada)
- Las decisiones implementadas deben tener **validación asociada** en tests o targets documentados cuando aplique (ver columna Validación)
- Los ADR **pointer** (0008–0010) registran decisiones aprobadas cuya implementación vive en handoffs separados

## Índice

| ADR | Título | Estado | Resumen | Validación |
|-----|--------|--------|---------|------------|
| [0001](0001-mcp-governance.md) | MCP Governance | Accepted | Capas MCP, MANIFEST, perfiles | `make ai-mcp-governance`, bats MCP |
| [0002](0002-gitnexus-mcp.md) | GitNexus MCP | Accepted | GitNexus como MCP knowledge/semantic | `gitnexus-status`, bats gitnexus |
| [0003](0003-skills-architecture.md) | Global Skills Architecture | Accepted | Skills en `ai/assets/skills/` | `validate-skills-structure`, bats-skills |
| [0004](0004-ai-assets-not-materialized.md) | AI Assets Not Materialized in Checkout | Accepted | Sin `.claude/skills/` en repo | `canonical-skills.bats` |
| [0005](0005-mcp-runtime-managed-vs-installed.md) | MCP Runtime-Managed vs Installed | Accepted | fetch uvx; no persistent install | `mcp-taxonomy-consistency.bats`, `update-workflow.bats` |
| [0006](0006-gitnexus-post-commit-policy.md) | GitNexus Post-Commit Best-Effort | Accepted | Hook no bloquea commit | `git-hooks/hooks.bats` |
| [0007](0007-playwright-docker-via-chezmoi-bin.md) | Playwright Docker via Chezmoi Bin | Accepted | Symlink `playwright-docker` | `playwright-docker.bats` |
| [0008](0008-git-flow-pr-policy.md) | Git Flow PR Policy | Accepted (pointer) | PR configurable por repo; impl. separada | `git-flow/policy.bats` (policy doc) |
| [0009](0009-dotfiles-update-wrapper.md) | dotfiles-update Wrapper | Accepted (pointer) | Wrapper global → `make update` | `dotfiles-update.bats` |
| [0010](0010-ups-removal.md) | Removal of ups | Accepted (pointer) | Sin alias legacy `ups` | Handoff dotfiles-update |

## Relacionados

- Skill: `ai/assets/skills/docs/adr-writer/`
- Mapa repo: [docs/AI_REPO_MAP.md](../AI_REPO_MAP.md)
