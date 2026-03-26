# Global Skills Architecture

Documentation for the global skills system in dotfiles.

## Overview

Global skills are project-agnostic knowledge assets maintained in `~/dotfiles/ai/assets/skills/`. They are distributed to AI agents via symlinks managed by chezmoi.

**This is the single source of truth** within this dotfiles repository.

## Canonical Source

```
dotfiles/
  ai/
    assets/
      skills/              ← CANONICAL SOURCE (edit here)
        diagrams/
        docs/
        etl/
        git/
        ops/
        postgres/
        python/
        tools/
```

**All changes to skills belong here.** Surface directories (symlinked or generated) are derived, not sources.

## Source vs Surface

| Path | Role | Edit Here? |
|------|------|------------|
| `ai/assets/skills/` | Canonical source | **Yes** |
| `~/.config/ai/skills/` | XDG hub (symlinked) | No |
| `dot_config/opencode/skills/` | OpenCode surface (symlinked) | No |
| `~/.cursor/skills-cursor/` | Cursor surface (symlinked) | No |
| `~/.codex/skills/` | Codex surface (symlinked) | No |

Do not edit files in surface directories. Changes belong in `ai/assets/skills/` and are distributed via `chezmoi apply`.

## Principles

| Principle | Description |
|-----------|-------------|
| **Single source of truth** | All global skills live in `ai/assets/skills/` |
| **Project-agnostic** | Skills contain only transversal knowledge |
| **Portable** | Skills work without platform-specific tooling |
| **Distribution via symlinks** | No content duplication across agents |

## Categories

| Category | Purpose | Skills |
|----------|---------|--------|
| `diagrams/` | Visual communication | Excalidraw generator, conventions |
| `docs/` | Technical writing | ADR writer |
| `etl/` | Data engineering | Data contracts |
| `git/` | Version control | PR conventions |
| `gitnexus/` | Code intelligence | GitNexus skills (6 variants) |
| `ops/` | Infrastructure/ops | MCP governance, system updates, Playwright UI validation |
| `postgres/` | Database | SQL style, schema review |
| `python/` | Python development | Project structure |

## What Goes in Global Skills

Skills that belong in dotfiles (transversal, reusable across projects):

- General coding conventions (SQL style, Python structure)
- Technical writing standards (ADR format, documentation)
- Process guidelines (PR conventions, code review)
- Architectural patterns (data contracts, schema review)
- Visual standards (diagram conventions)
- Infrastructure governance (MCP, system workflows)

## What Stays Local

Skills that belong in each project's own repository:

- Domain-specific entity models
- Internal table definitions
- Project-specific commands (Makefile targets)
- Client or business-specific conventions
- Custom workflow scripts
- DDL for a specific database schema

## Adding a New Global Skill

1. Create the skill directory:
   ```bash
   mkdir -p ai/assets/skills/<category>/<skill-name>
   ```

2. Create `SKILL.md` with:
   - A title heading (`# Skill Name`)
   - At least one recognizable section
   - Clear, self-contained content

3. Follow the existing format (see other skills for reference)

4. Validate and apply:
   ```bash
   ./scripts/validate-skills-structure.sh
   chezmoi apply
   ```

## Skill Format

Each skill is a directory containing `SKILL.md` with:

```markdown
# Skill Title

Brief description of what this skill covers.

## When to Use
When to apply this skill.

## Guidelines
Main content with practical guidance.

## Examples
Optional: concrete examples.
```

**Requirements**:
- `SKILL.md` must exist and not be empty
- Must have a title (`# ...`)
- Must have at least one section (## ...)
- Content should be self-contained

**No frontmatter required**: Skills are plain markdown for maximum portability.

## Distribution

After `chezmoi apply`, skills are symlinked to surface directories:

```
~/.config/ai/skills/<category>/<skill>/SKILL.md
~/.cursor/skills-cursor/<category>-<skill>/SKILL.md
~/.codex/skills/<category>-<skill>/SKILL.md
~/.config/opencode/skills/<category>-<skill>/SKILL.md
```

**Platform compatibility**: Actual compatibility with specific platforms (Cursor, Codex, OpenCode) should be verified per platform. If a platform requires specific formatting, create an adapter in `ai/adapters/`.

## Validation

Check skill structure and quality:

```bash
./scripts/validate-skills-structure.sh
```

The validator checks:
- `SKILL.md` exists and has content
- Title and sections are present
- No project-specific coupling (paths, tables, commands)

## Secrets and Configuration

Global skills must not contain secrets. Use:

- Environment variable references: `${POSTGRES_DSN}`
- SOPS-encrypted files for sensitive config
- External path references

## Global vs Local: Quick Reference

| Belongs in Dotfiles | Belongs in Project |
|--------------------|--------------------|
| SQL style guide | Internal table DDL |
| ADR template | Project-specific commands |
| PR conventions | Domain entity models |
| Python structure | Client-specific config |
| Data contract patterns | Custom CI scripts |
| MCP governance | DSN/project-specific config |
| System workflow | Internal tooling |

## Future Integrations

### Adding External Skills

External skills can be cloned and tracked:

```bash
cd ~/dotfiles/ai/assets/skills
git clone <external-repo> <category>/<skill-name>
rm -rf <category>/<skill-name>/.git
```

### Platform-Specific Adapters

If a platform requires different skill formats, create adapters in `ai/adapters/` to transform skills as needed.

## Related Documentation

- Skills index: `ai/assets/skills/README.md`
- ADR: `docs/adr/0003-skills-architecture.md`
- MCP Governance: `docs/adr/0001-mcp-governance.md`
- AI Framework: `ai/README.md`
- Sync Script: `.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl`
