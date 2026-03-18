# Commands

Canonical source of global commands for AI agents.

## Purpose

This directory contains **global, project-agnostic commands** that can be invoked across multiple AI agent platforms. Commands here are transversal utilities: help systems, diagnostic tools, workflow accelerators.

**This is the single source of truth** for global commands within this dotfiles repository.

## Architecture

```
ai/assets/commands/           <- Source of truth (here)
├── registry.yaml             <- Command metadata and platform mapping
├── README.md                <- This file
└── <command>/               <- One directory per command
    └── COMMAND.md           <- Command content (required)

dot_config/opencode/commands/ <- Surface for OpenCode (generated)
```

Do not edit files in surface directories (`dot_config/opencode/commands/`, etc.) directly. Changes belong here.

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

## Output

What kind of response or action is expected.
```

## Available Commands

| Command | Description | Platforms |
|---------|-------------|-----------|
| `sos` | General help command for AI assistants | opencode |

## Adding a Command

1. Create directory: `ai/assets/commands/<command-id>/`
2. Create `COMMAND.md` with:
   - Title heading (`# Command Name`)
   - Purpose section
   - Behavior section
   - Output section (optional)
3. Add entry to `registry.yaml`:
   ```yaml
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
4. Generate: `./scripts/generate-commands.sh`
5. Validate: `./scripts/validate-commands-structure.sh`
6. Apply: `chezmoi apply`

## Distribution

After `./scripts/generate-commands.sh`, commands are copied to surface directories:

```
~/.config/opencode/commands/<command-id>.md
~/.codex/commands/<command-id>.md        # future
~/.cursor/commands/<command-id>.md       # future
```

## Commands vs Skills

| Concept | Purpose | Pattern |
|---------|---------|---------|
| **Commands** | Executable help invoked with `/<command>` | Short, actionable responses |
| **Skills** | Deep knowledge about a specific domain | Detailed guidance and checklists |

Commands are lightweight invocations; skills are comprehensive references.

## Documentation

- Architecture: [docs/COMMANDS_ARCHITECTURE.md](../../docs/COMMANDS_ARCHITECTURE.md)
- OpenCode integration: [docs/OPENCODE.md](../../docs/OPENCODE.md)
