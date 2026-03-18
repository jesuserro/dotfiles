# Global Commands Architecture

Documentation for the global commands system in dotfiles.

## Overview

Global commands are reusable command definitions maintained in `~/dotfiles/ai/assets/commands/`. They are published to AI agent platforms via a generation script.

**This is the single source of truth** within this dotfiles repository.

## Canonical Source

```
dotfiles/
  ai/
    assets/
      commands/              ← CANONICAL SOURCE (edit here)
        registry.yaml         <- Command metadata and platform mapping
        README.md            <- This directory's documentation
        sos/                 <- One directory per command
          COMMAND.md         <- Command content
```

**All changes to commands belong here.** Surface directories are derived, not sources.

## Source vs Surface

| Path | Role | Edit Here? |
|------|------|------------|
| `ai/assets/commands/` | Canonical source | **Yes** |
| `dot_config/opencode/commands/` | OpenCode surface (generated) | No |
| `~/.config/opencode/commands/` | OpenCode runtime (symlinked via chezmoi) | No |

Do not edit files in surface directories. Changes belong in `ai/assets/commands/` and are published via `./scripts/generate-commands.sh`, then distributed via `chezmoi apply`.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Canonical Source: ai/assets/commands/                      │
│  ├── registry.yaml  (metadata)                            │
│  └── <command>/                                           │
│      └── COMMAND.md  (content)                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ Generate
┌─────────────────────────────────────────────────────────────┐
│  OpenCode Surface: dot_config/opencode/commands/          │
│  └── <command>.md  (generated artifact)                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ chezmoi apply
~/.config/opencode/commands/<command>.md
```

## Principles

| Principle | Description |
|-----------|-------------|
| **Single source of truth** | All global commands live in `ai/assets/commands/` |
| **Project-agnostic** | Commands contain only transversal utilities |
| **Portable** | Commands work without platform-specific tooling |
| **Explicit generation** | No automatic syncing; run generator explicitly |

## Registry Format

Commands are declared in `registry.yaml`:

```yaml
version: 1

commands:
  - id: <command-id>
    description: Brief description
    platforms:
      - opencode
      # - codex  # future
      # - cursor  # future
    source: <command-id>/COMMAND.md
    enabled: true
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier (used as filename) |
| `description` | Yes | Human-readable description |
| `platforms` | Yes | List of target platforms |
| `source` | Yes | Path relative to `commands/` directory |
| `enabled` | Yes | Whether to generate for declared platforms |

### Valid Platforms

- `opencode` - OpenCode CLI (fully implemented)
- `codex` - Codex (future implementation)
- `cursor` - Cursor IDE (future implementation)

## Command Structure

Each command lives in its own directory:

```
ai/assets/commands/<command-id>/
└── COMMAND.md    # Required: command content
```

### COMMAND.md Format

Commands use a simple, portable structure:

```markdown
# Command Name

Brief description of what this command does.

## Purpose

What the command is for and when to use it.

## Behavior

How the AI should respond when this command is invoked.

## Style Guidelines

Formatting and tone guidelines.

## Expected Output

What kind of response or action is expected.
```

**Requirements**:
- `COMMAND.md` must exist and not be empty
- Must have a title (`# ...`)
- Must have at least one section (`## ...`)
- Content should be self-contained and actionable

## Adding a New Command

1. Create the command directory:
   ```bash
   mkdir -p ai/assets/commands/<command-id>
   ```

2. Create `COMMAND.md` with:
   - A title heading (`# Command Name`)
   - Purpose section
   - Behavior section
   - Clear, actionable content

3. Add entry to `registry.yaml`:
   ```yaml
   commands:
     - id: <command-id>
       description: Brief description
       platforms:
         - opencode
       source: <command-id>/COMMAND.md
       enabled: true
   ```

4. Generate and validate:
   ```bash
   ./scripts/generate-commands.sh
   ./scripts/validate-commands-structure.sh
   ```

5. Review the generated artifacts in `dot_config/opencode/commands/`

6. Apply with chezmoi:
   ```bash
   chezmoi apply
   ```

## Available Commands

| Command | Description | Status |
|---------|-------------|--------|
| `sos` | General help command for AI assistants | ✓ Implemented |

## Workflow

```
┌──────────────────────────────────────────────────────────────┐
│  EDIT SOURCE                                                │
│  ai/assets/commands/<command>/COMMAND.md                   │
│  ai/assets/commands/registry.yaml                           │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  GENERATE                                                   │
│  ./scripts/generate-commands.sh                             │
│  → dot_config/opencode/commands/<command>.md               │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  VALIDATE                                                   │
│  ./scripts/validate-commands-structure.sh                   │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  REVIEW                                                     │
│  Check generated files in dot_config/opencode/commands/     │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  APPLY                                                      │
│  chezmoi apply                                             │
│  → ~/.config/opencode/commands/<command>.md                │
└──────────────────────────────────────────────────────────────┘
```

## Bootstrap (New Machine)

On a fresh clone, generated artifacts do not exist yet. Run the generator before `chezmoi apply`:

```bash
# 1. Clone dotfiles
git clone https://github.com/jesuserro/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Generate command artifacts (REQUIRED - not versioned)
./scripts/generate-commands.sh
# Or via Make:
make generate-commands

# 3. Apply dotfiles (chezmoi materializes everything)
chezmoi apply

# 4. Verify
ls ~/.config/opencode/commands/
opencode mcp list  # or your verification command
```

**Important:** Step 2 is mandatory on new machines. Artifacts are not versioned (see Versioning Policy above).
┌──────────────────────────────────────────────────────────────┐
│  EDIT SOURCE                                                │
│  ai/assets/commands/<command>/COMMAND.md                   │
│  ai/assets/commands/registry.yaml                           │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  GENERATE                                                   │
│  ./scripts/generate-commands.sh                             │
│  → dot_config/opencode/commands/<command>.md                │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  VALIDATE                                                   │
│  ./scripts/validate-commands-structure.sh                   │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  REVIEW                                                     │
│  Check generated files in dot_config/opencode/commands/     │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  APPLY                                                      │
│  chezmoi apply                                             │
│  → ~/.config/opencode/commands/<command>.md               │
└──────────────────────────────────────────────────────────────┘
```

## Distribution

After `chezmoi apply`, commands are available at:

```
~/.config/opencode/commands/sos.md
```

OpenCode users can invoke with `/sos`.

## Generated File Headers

Generated artifacts include a header marking them as derived:

```html
<!--
  DO NOT EDIT MANUALLY
  This file is generated from ai/assets/commands/
  Run ./scripts/generate-commands.sh to regenerate
-->
```

**This header is intentional.** It:
- Makes the derived nature visible at a glance
- Discourages direct editing of artifacts
- Documents the regeneration workflow

## Versioning Policy

**Generated artifacts are NOT versioned in Git.**

Rationale:
- Artifacts are reproducible from the canonical source
- Versioning them would create drift between source and derived
- The `.keep` file maintains directory structure in Git
- Chezmoi handles materialization to the final destination

The `.gitignore` enforces this policy:

```gitignore
# Generated command artifacts (regenerated from ai/assets/commands/)
dot_config/opencode/commands/*.md
!dot_config/opencode/commands/.keep
```

## Commands vs Skills

| Concept | Purpose | Pattern |
|---------|---------|---------|
| **Commands** | Executable help invoked with `/<command>` | Short, actionable responses |
| **Skills** | Deep knowledge about a specific domain | Detailed guidance and checklists |

Commands are lightweight invocations; skills are comprehensive references.

| | Commands | Skills |
|-|----------|--------|
| **Invocation** | `/command` | Loaded automatically |
| **Content** | Concise, actionable | Comprehensive, reference-style |
| **Structure** | Single `COMMAND.md` | `SKILL.md` + optional subdirs |
| **Purpose** | Quick help or utility | Domain expertise |

## Secrets and Configuration

Global commands must not contain secrets. Use:

- Environment variable references: `${VARIABLE_NAME}`
- SOPS-encrypted files for sensitive config
- External path references

## Validation

Check command structure and quality:

```bash
./scripts/validate-commands-structure.sh
```

The validator checks:
- `registry.yaml` exists and is valid YAML
- All command IDs are unique
- Each command has a source file
- All declared platforms are valid
- `enabled` field is boolean
- COMMAND.md files have title and sections

## Generation

Generate command artifacts:

```bash
# Generate all commands
./scripts/generate-commands.sh

# Generate specific command
./scripts/generate-commands.sh -c sos

# Validate and generate
./scripts/generate-commands.sh --validate

# List available commands
./scripts/generate-commands.sh --list
```

## Future Platforms

The architecture is designed to support additional platforms:

### Codex

```yaml
# In registry.yaml
platforms:
  - opencode
  - codex  # future
```

```bash
# In generate-commands.sh
codex)
    generate_codex_command "${cmd_id}" "${source_file}"
    ;;
```

Implementation would:
1. Create `~/.codex/commands/` structure
2. Copy command files to that location
3. Document in `ai/adapters/codex/README.md`

### Cursor

```yaml
# In registry.yaml
platforms:
  - opencode
  - cursor  # future
```

Implementation would:
1. Create `~/.cursor/commands/` structure
2. Copy command files to that location
3. Document in `ai/adapters/cursor/README.md`

## Global vs Local: Quick Reference

| Belongs in Dotfiles | Belongs in Project |
|--------------------|--------------------|
| Help commands (`/sos`) | Project-specific utilities |
| Diagnostic tools | Custom workflow commands |
| Cross-project utilities | Domain-specific commands |

## Related Documentation

- Commands index: `ai/assets/commands/README.md`
- Skills Architecture: `ai/SKILLS_ARCHITECTURE.md`
- AI Framework: `ai/README.md`
- OpenCode integration: `docs/OPENCODE.md`

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/generate-commands.sh` | Generate command artifacts |
| `scripts/validate-commands-structure.sh` | Validate command structure |

## Pending for Future Iterations

- [ ] Implement Codex command generation
- [ ] Implement Cursor command generation
- [ ] Add command versioning strategy
- [ ] Consider automatic generation on `chezmoi apply` hook
- [ ] Add command templates/derivatives support
