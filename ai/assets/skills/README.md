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

## Naming Taxonomy

Visible skill names follow semantic origin, not just repository location:

- `Vault ...` for skills whose conceptual source is the personal canonical vault (`vault_trabajo`)
- `Dotfiles ...` for transversal skills maintained in this repo that are not clearly vault-derived and are not third-party
- Third-party skills keep their original brand, such as `GitNexus ...`
- Project-specific families such as `Store ETL ...` belong in the corresponding project repo, not here

## Skills Index

### Diagrams

- `diagrams/excalidraw/` - Excalidraw diagram generator (programmatic)
- `diagrams/conventions/excalidraw-architecture/` - Conventions for manual diagrams

**When to use which:**
- `excalidraw/` (generator): When creating diagrams programmatically or via AI
- `conventions/`: When creating diagrams manually and needing style guidance

### Docs

- `docs/adr-writer/` - `Dotfiles ADR Writer`
- `docs/plans-and-notepads-naming/` - `Dotfiles Plans and Notepads Naming`

### ETL

- `etl/data-contracts/` - Data contract patterns

### Git

- `git/pr-conventions/` - PR and commit conventions

### GitNexus (Code Intelligence)

- `gitnexus/gitnexus-cli/` - `GitNexus CLI Commands`
- `gitnexus/gitnexus-debugging/` - `GitNexus Debugging`
- `gitnexus/gitnexus-exploring/` - `GitNexus Exploring Codebases`
- `gitnexus/gitnexus-guide/` - `GitNexus Guide`
- `gitnexus/gitnexus-impact-analysis/` - `GitNexus Impact Analysis`
- `gitnexus/gitnexus-refactoring/` - `GitNexus Refactoring`

### Ops

- `ops/ai-prompt-consumer/` - `Vault AI Prompt Consumer`
- `ops/dotfiles-skill-registration/` - `Dotfiles Skill Registration`
- `ops/vault-development-acceleration/` - `Vault Development Acceleration`
- `ops/vault-review-diff/` - `Vault Review Diff`
- `ops/vault-detect-errors/` - `Vault Detect Errors`
- `ops/vault-suggest-improvements/` - `Vault Suggest Improvements`
- `ops/vault-update-documentation/` - `Vault Update Documentation`
- `ops/vault-write-commit-message/` - `Vault Write Commit Message`
- `ops/mcp-governance/` - `Dotfiles MCP Governance`
- `ops/system-updates/` - `Dotfiles UPS Workflow`
- `ops/playwright-ui-validation/` - `Dotfiles Playwright UI Validation`
- `ops/wsl2-local-tools/` - `Dotfiles WSL2 Local Tools`

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
