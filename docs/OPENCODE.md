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
- `playwright` - Browser automation and testing

### Layer 2: Visual / Architecture
- `excalidraw` - Diagram creation (enabled by default)

### Layer 3: Platform / Data Stack

**Defined globally but disabled by default.** Enable per-project when needed:
- `dagster` - Dagster orchestrator (requires `localhost:3000`)
- `loki` - Log aggregation (requires `localhost:3100`)
- `minio` - S3-compatible storage (requires `localhost:9000`)
- `prometheus` - Metrics (requires `localhost:9090`)
- `tempo` - Trace visualization (requires `localhost:3200`)
- `store_etl_ops` - Store ETL operations

#### Why disabled by default?

Platform MCPs depend on specific local services running. Enabling them globally would cause:
- Connection errors on startup (services not running)
- Noise in projects where they're irrelevant
- Confusion about available tools

**The policy is conservative by design:**
- MCPs that are general workstation tools → `enabled: true`
- MCPs that are platform-specific → `enabled: false` unless explicitly needed

### Layer 4: Database MCPs (Runtime Global + Connection Project-Specific)

**Defined at project level, not globally.** The runtime tools exist in the workstation, but connections are project-specific:

- `postgres` - PostgreSQL database (uses `npx @modelcontextprotocol/server-postgres`)
- `trino` - Trino query engine (uses `~/.config/ai/runtime/.venv/bin/python -m trino_mcp`)

#### Why NOT global?

Database connections depend on project-specific context:
- Host, port, database/schema/catalog
- User, password, authentication method
- Project secrets (DSN from `~/.secrets/codex.env`)
- Stack-specific configuration (e.g., Trino catalog)

A "global" PostgreSQL or Trino connection would incorrectly couple all projects to one DSN, which is wrong.

#### The correct model: Runtime Global + Connection Project-Specific

```
Runtime (tooling):      Shared globally in workstation
Connection (config):   Project-specific (env vars, DSN, secrets)
Activation:            Per-project via local opencode.json or .cursor/mcp.json
```

**Current implementation:**
- `store-etl` project has its own `mcp.json.tmpl` with postgres/trino config
- Runtime tools (npx, trino-mcp) are available in the workstation
- Each project defines its own connection parameters

This separation ensures:
- No duplicated runtime installation
- No cross-project credential leakage
- Clean project boundaries

**Example: `dagster`**
- Defined globally so it's available in all projects without duplication
- Disabled by default because most projects don't have a Dagster instance at `localhost:3000`
- In `store_etl` or similar projects, enable it via project-local `opencode.json`

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
- **Database MCPs as project-specific**: PostgreSQL and Trino MCPs are NOT globally configured because their connections depend on project context (host, DSN, secrets, catalog). The runtime tools exist globally, but connections are project-specific.
- **Reused paths**: MCP server paths follow the same patterns as Codex configuration to maintain consistency
- **Global-first**: MCPs are defined globally to avoid duplication across projects
- **Playwright as global workstation**: Browser automation is a general-purpose tool that belongs in the core workstation layer

## Why `dot_config/opencode/`? (Architectural Decision)

### The Visual Asymmetry

You may notice that OpenCode uses `dot_config/opencode/` while other AI tools use different patterns:

| Tool     | Source in dotfiles       | Destination in `$HOME`       |
|----------|--------------------------|------------------------------|
| Cursor   | `dot_cursor/`            | `~/.cursor/`                 |
| Codex    | `dot_codex/`             | `~/.codex/`                  |
| OpenCode | `dot_config/opencode/`   | `~/.config/opencode/`        |

This is **not an inconsistency** or an error. It's the correct pattern for each tool.

### Why OpenCode uses XDG convention

OpenCode follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html), which is the standard convention for application configuration on Linux/Unix systems. By convention:

- User config lives in `$XDG_CONFIG_HOME` (default: `~/.config`)
- Therefore, OpenCode expects its config at `~/.config/opencode/`

### How Chezmoi handles this

Chezmoi has a specific mapping rule:
- `dot_foo/` → `~/.foo/` (hidden file/directory in home)
- `dot_config/foo/` → `~/.config/foo/` (XDG-compliant path)

This is why `dot_config/opencode/` is the correct source path - it maps exactly to where OpenCode looks for its configuration.

### Why we don't normalize to `dot_opencode/`

We could rename it to `dot_opencode/` for visual symmetry with Cursor/Codex, but that would break the materialization. The destination path is determined by the runtime convention (XDG for OpenCode, home-hidden for others), not by our aesthetic preferences.

### Architectural Principle

**"Respect the runtime's native convention, not the repo's visual symmetry."**

When integrating any new AI tool into dotfiles:
1. Find where the tool expects its config in the user's home directory
2. Use the Chezmoi source path that maps to that exact destination
3. Prioritize correctness over visual uniformity

This principle ensures:
- Configuration works out of the box after `chezmoi apply`
- No manual symlinks or overrides needed
- Future tool updates won't break assumptions
