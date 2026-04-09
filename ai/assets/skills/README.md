# Skills

Canonical source of global skills for AI agents.

## Purpose

This directory contains **global, project-agnostic skills** that apply across multiple projects. Skills here are transversal knowledge: coding conventions, process guidelines, architectural patterns, and technical standards.

**This is the single source of truth** for global skills within this dotfiles repository.

## Canonical Source

```
ai/assets/skills/           <- Source of truth (here)
~/.config/ai/skills/        <- Symlinked via chezmoi
~/.config/opencode/skills/  <- Surface for OpenCode
~/.cursor/skills-cursor/    <- Surface for Cursor
~/.codex/skills/           <- Surface for Codex
```

Do not edit files in surface directories (`dot_config/opencode/skills/`, etc.) directly. Changes belong here.

## Categories

| Category | Purpose |
|----------|---------|
| `diagrams/` | Visual communication |
| `docs/` | Technical writing |
| `etl/` | Data engineering |
| `git/` | Version control |
| `gitnexus/` | Code intelligence |
| `ops/` | Infrastructure |
| `postgres/` | Database |
| `python/` | Python development |

## Skills Index

### Diagrams

- `diagrams/excalidraw/` - Excalidraw diagram generator (programmatic)
- `diagrams/conventions/excalidraw-architecture/` - Conventions for manual diagrams

**When to use which:**
- `excalidraw/` (generator): When creating diagrams programmatically or via AI
- `conventions/`: When creating diagrams manually and needing style guidance

### Docs

- `docs/adr-writer/` - Guide for writing Architecture Decision Records
- `docs/plans-and-notepads-naming/` - Naming convention for `.cursor/plans/*.plan.md` (chronological prefix)

### ETL

- `etl/data-contracts/` - Data contract patterns

### Git

- `git/pr-conventions/` - PR and commit conventions

### GitNexus (Code Intelligence)

- `gitnexus/cli/` - CLI commands
- `gitnexus/debugging/` - Debugging workflows
- `gitnexus/exploring/` - Code exploration
- `gitnexus/guide/` - General guide
- `gitnexus/impact-analysis/` - Impact analysis
- `gitnexus/refactoring/` - Refactoring workflows

### Ops

- `ops/ai-prompt-consumer/` - Uso seguro de `ai-prompt` desde agentes y otros proyectos
- `ops/mcp-governance/` - MCP server classification guide
- `ops/system-updates/` - System update workflow (dotfiles ups alias)
- `ops/playwright-ui-validation/` - Validate rendered dashboards/apps with Playwright and capture acceptance evidence

### Postgres

- `postgres/schema-review/` - Database schema review guide
- `postgres/sql-style/` - SQL formatting standards

### Python

- `python/project-structure/` - Python project layout conventions

## Global vs Local

**Global skills** (here): Transversal knowledge applicable to multiple projects.

**Local skills** (project repo): Domain-specific conventions, internal models, project commands.

| Belongs Here | Belongs to Project |
|--------------|-------------------|
| SQL style guide | Internal table DDL |
| ADR template | Project-specific commands |
| PR conventions | Domain entity models |
| Python structure | Client-specific config |
| Data contract patterns | Custom CI scripts |

## Adding a Skill

1. Create directory: `ai/assets/skills/<category>/<skill-name>/`
2. Create `SKILL.md` with:
   - Title heading (`# Skill Name`)
   - At least one section (`## ...`)
   - Self-contained, portable content
3. Validate: `./scripts/validate-skills-structure.sh`
4. Apply: `chezmoi apply`

## Documentation

- Architecture: [ai/SKILLS_ARCHITECTURE.md](../SKILLS_ARCHITECTURE.md)
- ADR: [docs/adr/0003-skills-architecture.md](../../docs/adr/0003-skills-architecture.md)
