# Skills

Canonical source of global skills for AI agents.

## Purpose

This directory contains **global, project-agnostic skills** that apply across multiple projects. Skills here are transversal knowledge: coding conventions, process guidelines, architectural patterns, and technical standards.

**This is the single source of truth** for global skills within this dotfiles repository.

## Canonical Source

```
ai/assets/skills/           ← Source of truth (here)
~/.config/ai/skills/        ← Symlinked via chezmoi
~/.config/opencode/skills/  ← Surface for OpenCode
~/.cursor/skills-cursor/    ← Surface for Cursor
~/.codex/skills/           ← Surface for Codex
```

Do not edit files in surface directories (`dot_config/opencode/skills/`, etc.) directly. Changes belong here.

## Categories

| Category | Purpose | Skills |
|----------|---------|--------|
| `diagrams/` | Visual communication | Excalidraw generator, conventions |
| `docs/` | Technical writing | ADR writer |
| `etl/` | Data engineering | Data contracts |
| `git/` | Version control | PR conventions |
| `ops/` | Infrastructure | MCP governance, system workflow |
| `postgres/` | Database | SQL style, schema review |
| `python/` | Python development | Project structure |
| `tools/` | Developer tools | Code intelligence (GitNexus) |

## Skills Index

### Diagrams
- `diagrams/excalidraw/` — Excalidraw diagram generator
- `diagrams/conventions/` — Excalidraw architecture conventions

### Docs
- `docs/adr-writer/` — Guide for writing Architecture Decision Records

### ETL
- `etl/data-contracts/` — Data contract patterns

### Git
- `git/pr-conventions/` — PR and commit conventions

### Ops
- `ops/mcp-governance/` — MCP server classification guide
- `ops/system-workflow/` — System update workflow

### Postgres
- `postgres/schema-review/` — Database schema review guide
- `postgres/sql-style/` — SQL formatting standards

### Python
- `python/project-structure/` — Python project layout conventions

### Tools
- `tools/code-intelligence/` — GitNexus code analysis skills (6 variants)

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
