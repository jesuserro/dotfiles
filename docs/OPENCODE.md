# OpenCode Integration

This document describes how OpenCode is integrated into the dotfiles workstation.

## Overview

OpenCode is configured globally via Chezmoi. All MCP servers are defined once in `dot_config/opencode/opencode.json.tmpl` and materialized to `~/.config/opencode/opencode.json`.

## Files Created

```
dot_config/opencode/
├── opencode.json.tmpl    # Main MCP configuration
├── AGENTS.md.tmpl       # Global agent instructions
├── commands/.keep       # Future: custom commands
├── plugins/.keep        # Future: plugins directory
└── skills/.keep         # Future: global skills
```

## MCP Servers Organization

### Layer 1: Core Shared Workstation
Available in all projects, enabled by default:
- `docker` - Docker management
- `github` - GitHub API operations
- `fetch` - HTTP requests
- `context7` - Context7 documentation lookup

### Layer 2: Visual / Architecture
- `excalidraw` - Diagram creation (enabled by default)

### Layer 3: Platform / Data Stack
Disabled by default, enable per-project when needed:
- `dagster` - Dagster orchestrator
- `loki` - Log aggregation
- `minio` - S3-compatible storage
- `prometheus` - Metrics
- `tempo` - Trace visualization
- `store_etl_ops` - Store ETL operations

Platform MCPs are disabled by default because they require specific local services (Docker containers, local servers) to be running. Enabling them globally would cause connection errors on startup.

## Materialization

Apply the configuration:

```bash
chezmoi apply
```

This generates:
- `~/.config/opencode/opencode.json`
- `~/.config/opencode/AGENTS.md`

## Verification

Check that OpenCode detects the MCPs:

```bash
opencode mcp list
```

Debug a specific MCP:

```bash
opencode mcp debug docker
opencode mcp debug github
```

## Enabling Platform MCPs

To enable a platform MCP for a specific project, create a local `opencode.json` in the project:

```json
{
  "mcp": {
    "dagster": {
      "enabled": true
    }
  }
}
```

Or use the global config and set `enabled: true` directly.

## Extending Configuration

### Adding New MCPs

1. Edit `dotfiles/dot_config/opencode/opencode.json.tmpl`
2. Follow the existing pattern for local or remote MCPs
3. Run `chezmoi apply`

### Future: Commands, Plugins, Skills

The directory structure supports future expansion:
- `commands/` - Custom OpenCode commands
- `plugins/` - Plugin configurations
- `skills/` - Global skill definitions

## Troubleshooting

If an MCP fails to start:
1. Check `opencode mcp debug <name>` for error details
2. Verify the command path exists
3. For platform MCPs, ensure the required service is running (e.g., Docker daemon, local servers)

## Design Decisions

- **Disabled platform MCPs**: Platform-specific MCPs (dagster, loki, etc.) are disabled by default to avoid connection errors when their services aren't running
- **Reused paths**: MCP server paths follow the same patterns as Codex configuration to maintain consistency
- **Global-first**: MCPs are defined globally to avoid duplication across projects
