# ADR: Global Skills Architecture

**Date:** 2026-03-18  
**Status:** Accepted  
**Author:** jesus  

---

## Context

This dotfiles repository manages configuration for multiple AI agents (OpenCode, Cursor, Codex). A decision was needed on how to structure, classify, and distribute reusable knowledge assets (skills) across agents while:

- Maintaining a single source of truth
- Avoiding content duplication
- Keeping global skills project-agnostic
- Supporting future platform integrations
- Working seamlessly with the existing chezmoi-managed dotfiles

---

## Decision

### 1. Single Source of Truth Location

All global skills live in `~/dotfiles/ai/assets/skills/`.

```
dotfiles/
  ai/
    assets/
      skills/           # Canonical source within this dotfiles repo
        docs/
        diagrams/
        etl/
        git/
        postgres/
        python/
```

This location is:
- Neutral to any specific agent platform
- Managed by chezmoi (versioned, portable)
- Consumed via `~/.config/ai/skills/` hub and symlinked to agents

**Important**: This is the canonical location within this dotfiles repo. It is not a universal standard—other repos or organizations may organize skills differently. Platform consumers may require adapters, symlinks, or surface transformations.

### 2. Two-Layer Classification

| Layer | Scope | Location | Examples |
|-------|-------|----------|----------|
| **Global Skills** | All projects | `~/dotfiles/ai/assets/skills/` | SQL style, ADR template, PR conventions |
| **Local Skills** | Single project | Project's own repo | Domain-specific conventions, internal models |

### 3. Distribution via Symlinks

The existing `run_after_11_link_ai_assets.sh.tmpl` script publishes skills to:

```
~/.config/ai/skills/           # XDG hub (single source)
~/.cursor/skills-cursor/*/     # Per-skill symlinks
~/.codex/skills/*/            # Per-skill symlinks
~/.config/opencode/skills/*/  # Per-skill symlinks
```

This approach:
- Maintains single source of truth (no duplication)
- Allows per-agent overrides in agent-specific directories
- Is idempotent and chezmoi-safe

### 4. Skill Format

Skills use a simple, portable structure:

```
skill-directory/
  SKILL.md        # Required: main content file
  references/     # Optional: supporting files
  templates/       # Optional: reusable templates
```

**SKILL.md requirements**:
- Starts with a title (`# Skill Name`)
- Contains at least one recognizable section (`When to Use`, `Guidelines`, `Checklist`, `Examples`, etc.)
- Is self-contained and understandable without external context
- No frontmatter is required

**Rationale for no frontmatter**:
- Skills remain readable in any context (markdown viewer, git diff, plain text)
- No dependency on specific tooling to parse metadata
- Simpler validation and maintenance
- Future metadata needs can be addressed via separate indexes or adapters if required

### 5. Platform Compatibility Notes

The skill format is designed to be portable, but compatibility with specific platforms (Cursor, Codex, OpenCode) is not guaranteed and should be verified per platform. If a platform requires a specific format or metadata, an adapter should be created in `ai/adapters/` to transform skills as needed.

### 6. Anti-Patterns Prohibited

| Anti-Pattern | Why |
|--------------|-----|
| Project-specific content in global skills | Couples dotfiles to single project |
| Hardcoded paths in skills | Breaks portability |
| Secrets in skills | Must use env vars or SOPS references |
| Duplicating skill content per agent | Maintenance nightmare |
| Agent-specific naming conventions | Skills should be platform-agnostic |

---

## Consequences

### Positive

- Single source of truth for all global knowledge
- Clear separation between transversal and project-specific
- Easy distribution to multiple agents via symlinks
- Version-controlled skills with dotfiles
- Extensible architecture for new categories
- Portable format that works without special tooling

### Negative

- All skills must be project-agnostic (steeper learning curve)
- Requires discipline to not pollute global with local
- No standardized metadata format (each platform may require different conventions)

### Neutral

- Local skills remain in each project's repo
- Platform-specific adapters may be needed for optimal integration

---

## Global Skills Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| `docs/` | Technical writing | ADR writer, documentation templates |
| `diagrams/` | Visual communication | Excalidraw architecture conventions |
| `etl/` | Data engineering | Data contracts, pipeline patterns |
| `git/` | Version control | PR conventions, commit style |
| `postgres/` | Database | Schema review, SQL style |
| `python/` | Python development | Project structure, packaging |

### What's NOT Global

Skills that belong in individual projects, not here:

- Internal database tables/models
- Project-specific commands (Makefile targets, scripts)
- Domain entity definitions
- Client-specific conventions
- Build system configurations
- Table schemas or DDL for a specific project

---

## References

- MCP Governance ADR: `docs/adr/0001-mcp-governance.md`
- AI Framework: `ai/README.md`
- Skills Architecture: `ai/SKILLS_ARCHITECTURE.md`
- Chezmoi scripts: `.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl`
- AGENTS.md template: `dot_config/opencode/AGENTS.md.tmpl`
