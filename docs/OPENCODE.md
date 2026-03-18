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

> **See also:** [ADR: MCP Governance](./adr/0001-mcp-governance.md) — Formal architectural decision on MCP layered classification, runtime vs connection separation, and activation policy.

## MCP Servers Organization

### Layer 1: Core Shared Workstation
Available in all projects, enabled by default:
- `docker` - Docker management
- `github` - GitHub API operations
- `fetch` - HTTP requests
- `context7` - Context7 documentation lookup
- `playwright` - Browser automation and testing
- `filesystem` - Filesystem access (whitelist policy)
- `git` - Git operations (dynamic repo detection)
- `sequential-thinking` - Structured reasoning tool

### Layer 2: Visual / Architecture
- `excalidraw` - Diagram creation (enabled by default)

### Layer 3: Knowledge / Semantic
- `gitnexus` - Code understanding and documentation generation

### Layer 4: Domain-Specific (Optional)
- `obsidian` - Obsidian vault operations (notes, frontmatter, tags, search)
  - **Note:** Requires Obsidian vault at `/mnt/c/Users/jesus/Documents/vault`
  - **Enabled:** false (opt-in, see docs/MCP_OBSIDIAN_PROPOSAL.md)
  - **Complementary to:** Filesystem MCP (raw file access)

### Layer 4: Platform / Data Stack

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

- `postgres` - PostgreSQL database (uses `~/bin/mcp-postgres-launcher`)
- `trino` - Trino query engine (uses `~/.config/ai/runtime/.venv/bin/python -m trino_mcp`)

#### Why NOT global?

Database connections depend on project-specific context:
- Host, port, database/schema/catalog
- User, password, authentication method
- Project secrets (DSN from `~/.config/mcp-secrets.env`)
- Stack-specific configuration (e.g., Trino catalog)

A "global" PostgreSQL or Trino connection would incorrectly couple all projects to one DSN, which is wrong.

#### The correct model: Runtime Global + Connection Project-Specific

```
Runtime (tooling):      ~/bin/mcp-postgres-launcher or ~/.config/ai/runtime/.venv
Connection (config):   Project-specific (env vars, secrets file)
Activation:            Per-project via local mcp.json or opencode.json
```

**Architecture:**

| Component | PostgreSQL | Trino |
|----------|------------|-------|
| Launcher/Runtime | `~/bin/mcp-postgres-launcher` | `~/.config/ai/runtime/.venv/bin/python -m trino_mcp` |
| Connection Config | `~/.config/mcp-secrets.env` (POSTGRES_DSN) | `env` block (TRINO_HOST, etc.) |

**Pattern:**
- Both follow the same architecture: launcher + connection profile
- The launcher handles runtime (npx/Python)
- Connection profile provides credentials and endpoint details
- Project-specific config keeps secrets isolated per project/stack

**Current implementation:**
- `store-etl` project uses `dot_config/store-etl/store-etl.mcp.json.tmpl`
- Wrapper: `~/bin/mcp-postgres-launcher` (created 2025)
- Secrets: `~/.config/mcp-secrets.env` (renamed from legacy `~/.secrets/codex.env`)
- Trino uses `env` block for connection (same pattern as `dagster`, `loki`, etc.)

This separation ensures:
- No duplicated runtime installation
- No cross-project credential leakage
- Clean project boundaries
- Consistent pattern across all database MCPs

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

## Understanding `dot_config/` Semantics

### The distinction: Global Client vs Project-Specific

In this repository, `dot_config/` contains **two fundamentally different types** of configuration:

| Path | Type | Scope | Materialization |
|------|------|-------|-----------------|
| `dot_config/opencode/` | Global client config | Workstation-wide, all projects | `~/.config/opencode/` |
| `dot_config/store-etl/` | Project/stack config | Specific to `store-etl` project | `~/.config/store-etl/` |

**Why this matters:**
- `dot_config/opencode/` defines MCPs available to **any** project opened with OpenCode
- `dot_config/store-etl/` defines MCPs specific to the **store-etl** stack (postgres, trino, dagster, etc.)

### Historical context: The `private_dot_config/` migration

Previously, project-specific configuration lived in `private_dot_config/store-etl/`. The "private_" prefix provided **semantic separation** from global configs, not security (there were no secrets hardcoded).

This was migrated to `dot_config/store-etl/` to fix a chezmoi inconsistency. However, this **does not** make it a "global" configuration in the functional sense.

### Key principle

**"Under `dot_config/` ≠ automatically global."**

The directory structure reflects:
1. Where the tool expects its config (XDG: `~/.config/...`)
2. The project or stack context

When adding new configs:
- Client-wide tools → `dot_config/opencode/`
- Project-specific stacks → `dot_config/<project-name>/`

### Database MCPs: Runtime global, connection project-specific

PostgreSQL and Trino follow this pattern:
- **Runtime** (launcher): `~/bin/mcp-postgres-launcher` or `~/.config/ai/runtime/.venv/bin/python -m trino_mcp`
- **Connection** (secrets/env): `~/.config/mcp-secrets.env` or env block
- **Why?** Each project has different hosts, catalogs, credentials

**Convention (2025+):**
- Database MCPs use a **launcher wrapper** for runtime isolation
- Connection profile is **project-specific** (secrets file or env block)
- The launcher receives connection via `MCP_POSTGRES_SECRETS` env var or direct argument

Do NOT add postgres/trino to `dot_config/opencode/opencode.json.tmpl` as "global" connections. They belong in project-specific configs like `dot_config/store-etl/`.

---

## MCP Design Convention (2025+)

### The Three Layers

| Layer | Scope | `enabled` default | Examples |
|-------|-------|-------------------|----------|
| **Core Workstation** | All projects, all sessions | `true` | `docker`, `github`, `fetch`, `context7`, `excalidraw`, `playwright` |
| **Platform Specialized** | All projects, optional per-project | `false` | `dagster`, `loki`, `prometheus`, `tempo`, `minio`, `store_etl_ops` |
| **Data / Connection-Specific** | Project-specific only | Per-project | `postgres`, `trino`, future DB connectors |

### Decision Criteria

**A. MCP should be Core Workstation when:**
- It's a transversal tool used in **any** project
- No external service dependency (or always available: Docker, network)
- Examples: Docker CLI, GitHub API, HTTP fetch, documentation lookup, diagrams, browser automation

**B. MCP should be Platform Specialized when:**
- Depends on a **specific local service** (localhost:XXXX)
- Useful only for particular stacks or projects
- Must be `enabled: false` by default to avoid connection noise

**C. MCP should be Connection-Specific when:**
- Requires **project-specific credentials** (DSN, secrets, tokens)
- Has **per-project configuration** (host, port, catalog, schema)
- The same MCP tool could connect to different instances per project
- Examples: Database connectors (PostgreSQL, Trino, MySQL), API clients with project keys

### Runtime vs Connection Profile

```
┌─────────────────────────────────────────────────────────┐
│  MCP Tool (shared)                                      │
│  - npx package                                          │
│  - python -m module                                     │
│  - docker image                                         │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Connection Profile (project-specific)                   │
│  - DSN / endpoint                                       │
│  - Credentials / secrets                                │
│  - Catalog / schema / namespace                         │
│  - Auth method                                          │
└─────────────────────────────────────────────────────────┘
```

**Key distinction:**
- **Runtime/Launcher**: The tool itself (npx, python module). Can be shared globally.
- **Connection Profile**: The specific endpoint + credentials. Must be project-specific.

### Anti-Patterns to Avoid

| Anti-Pattern | Why it's wrong | Correct approach |
|--------------|----------------|-----------------|
| Hardcoded DSN in global config | Couples all projects to one database | Use project-specific config or env vars |
| "Global" database MCP | Assumes one DSN fits all projects | Keep connection profile per-project |
| `enabled: true` for platform MCPs | Causes errors when services aren't running | Default to `false`, enable per-project |
| Secrets file named after a client | Couples secrets to tool naming | Use neutral names like `mcp-secrets.env` |
| Runtime path hardcoded in project | Duplicates tool installation | Reference shared runtime paths |

### Adding a New MCP

1. **Classify it**: Core / Platform / Connection-Specific?
2. **Set default `enabled`**:
   - Core → `true`
   - Platform → `false`
   - Connection-Specific → per-project config (not global)
3. **Define runtime path**: Use shared paths (`~/.config/ai/runtime/.venv`, `npx`, etc.)
4. **Define connection profile**: Keep in project-specific config or env block
5. **Document**: Add to this convention with the appropriate layer

### Quick Reference

```
# Global workstation (enabled: true)
docker, github, fetch, context7, excalidraw, playwright, filesystem, git, sequential-thinking

# Knowledge/Semantic (enabled: true)
gitnexus

# Platform specialized (enabled: false)
dagster, loki, minio, prometheus, tempo, store_etl_ops

# Connection-specific (project-only)
postgres, trino, [future DB MCPs]
```

This convention ensures:
- No cross-project credential leakage
- No connection errors from missing services
- Clear separation between shared tooling and project configuration
- Scalable pattern for future MCP integrations
