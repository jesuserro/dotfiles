# OpenCode Integration

This document describes how OpenCode is integrated into the dotfiles workstation.

## Overview

OpenCode is configured globally via Chezmoi. All MCP servers are defined once in `dot_config/opencode/opencode.json.tmpl` and materialized to `~/.config/opencode/opencode.json`.

## Files Created

```
dot_config/opencode/
├── opencode.json.tmpl    # Main MCP configuration
├── AGENTS.md.tmpl       # Global agent instructions
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

### Layer 4: Domain-Specific
- `obsidian` - Obsidian vault operations (notes, frontmatter, tags, search)
  - **Note:** Vault path comes from Chezmoi **`ai.obsidian_vault_path`** (default in repo: `/mnt/c/Users/jesus/Documents/vault_trabajo`; override locally when needed). See [CHEZMOI.md](./CHEZMOI.md).
  - **Intent:** `enabled: true` on global surfaces per **`ai/assets/mcps/MANIFEST.yaml`**; missing vault path is a **readiness** concern (`make ai-cursor-check`), not a reason to omit the MCP from the manifest
  - **Complementary to:** Filesystem MCP (raw file access)

### Layer 4: Platform / Data Stack

**Global templates, intended enabled by default** (same policy as Cursor/Codex: `compatible_by_default_enabled` in the manifest). Missing local services produce connection noise at runtime; **`make ai-cursor-check`** and logs should surface that, rather than silently disabling servers in the repo templates.

- `dagster` - Dagster orchestrator (expects `localhost:3000` by default in templates)
- `loki` - Log aggregation
- `minio` - S3-compatible storage
- `prometheus` - Metrics
- `tempo` - Trace visualization
- `store_etl_ops` - Store ETL operations

Optional **project-local** `opencode.json` can still narrow or override behavior for a repo without changing the dotfiles-wide intent in **`MANIFEST.yaml`**.

### Layer 4: Database MCPs (Runtime vs connection profile)

**Global OpenCode template lists the MCP** so all agents have parity with the manifest; **connection material** stays in neutral files / env blocks (not hardcoded secrets in git).

- `postgres` - Uses **`mcp-postgres-launcher`** and `MCP_POSTGRES_SECRETS` → `~/.config/mcp-secrets.env` (DSN and credentials live there, not in the repo)
- `trino` - Uses venv `python -m trino_mcp` with an `env` block for endpoints/catalog in the template (tune per machine or override per project)

#### Runtime vs connection (still the engineering model)

```
Runtime (shared):     launcher / venv python module
Connection profile: env vars, ~/.config/mcp-secrets.env, project-local overrides
```

| Component | PostgreSQL | Trino |
|----------|------------|-------|
| Launcher/Runtime | `mcp-postgres-launcher` (Chezmoi materialized path) | `~/.config/ai/runtime/.venv/bin/python -m trino_mcp` |
| Connection config | `~/.config/mcp-secrets.env` (via `MCP_POSTGRES_SECRETS`) | `env` block in template (override locally if needed) |

**Project-specific stacking:** el repositorio **store-etl** mantiene su propio `.cursor/mcp.json`; dotfiles no materializa esa configuración (ver [CHEZMOI.md](CHEZMOI.md)).

This separation ensures:
- No duplicated runtime installation
- Credentials are not committed to the dotfiles repo
- Optional per-project stacks keep extra isolation when you need it

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

## Optional per-project overrides

Global templates already declare platform MCPs **enabled** per manifest. If a project should **turn off** or narrow a server, use a local `opencode.json` in that project (merge semantics depend on OpenCode; treat as an escape hatch, not the default policy).

## Extending Configuration

### Adding New MCPs

1. Edit `dotfiles/dot_config/opencode/opencode.json.tmpl`
2. Follow the existing pattern for local or remote MCPs
3. Run `chezmoi apply`

### Future: Plugins, Skills, and Materialized Commands

The directory structure supports future expansion:
- `plugins/` - Plugin configurations
- `skills/` - Global skill definitions

Global commands are no longer stored as stable files under `dot_config/opencode/commands/`.
They are generated into `build/commands/opencode/` and materialized to `~/.config/opencode/commands/`.

## Troubleshooting

If an MCP fails to start:
1. Check `opencode mcp debug <name>` for error details
2. Verify the command path exists
3. For platform MCPs, ensure the required service is running (e.g., Docker daemon, local servers)

## Design Decisions

- **Platform MCPs enabled in templates by default**: Canonical intent is **`ai/assets/mcps/MANIFEST.yaml`** (`compatible_by_default_enabled: true`). Missing services are **readiness** (warnings / failures in checks), not a reason to fork product policy in grep scripts.
- **Database MCPs**: Global template wires **shared runtime** (launcher / venv); **secrets and DSN** live outside git (`mcp-secrets.env`, env blocks). Per-project files like `store-etl` remain for stack-specific composition.
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
| `~/.config/store-etl/` | Legacy compatibility secrets | Compatibility only for older `store-etl` consumers | Generated from SOPS, not a dotfiles MCP template |

**Why this matters:**
- `dot_config/opencode/` defines MCPs available to **any** project opened with OpenCode
- The **store-etl** repository owns its project-specific MCP stack configuration (postgres, trino, dagster, etc.).

### Historical context: The `private_dot_config/` migration

Previously, project-specific configuration lived in dotfiles under `private_dot_config/store-etl/` and later `dot_config/store-etl/`. That ownership has been retired: dotfiles no longer materializes the project MCP file, and keeps only shared workstation launchers plus legacy secret adapters.

### Key principle

**"Under `dot_config/` ≠ automatically global."**

The directory structure reflects:
1. Where the tool expects its config (XDG: `~/.config/...`)
2. The project or stack context

When adding new configs:
- Client-wide tools → `dot_config/opencode/`
- Project-specific stacks → `dot_config/<project-name>/`

### Database MCPs: Runtime global, connection profile outside git

PostgreSQL and Trino follow this pattern:
- **Runtime** (launcher / venv): materialized launcher path or `~/.config/ai/runtime/.venv/bin/python -m trino_mcp`
- **Connection** (secrets/env): `~/.config/mcp-secrets.env`, env blocks — **values** are not committed to the dotfiles repo
- **Why?** The same tool can point at different instances; secrets stay out of git

**Convention:** update **`ai/assets/mcps/MANIFEST.yaml`** and recipes in **`scripts/generate-mcp-configs.py`**, then **`make ai-mcp-governance`** before landing template changes. The global `opencode.json.tmpl` may list postgres/trino **because manifest parity requires it**; that is not the same as hardcoding a production DSN in the repo.

---

## MCP Design Convention (2025+) — superseded in product policy by the manifest

**Canonical activation intent** is **`ai/assets/mcps/MANIFEST.yaml`** (`compatible_by_default_enabled: true`). The table below describes **roles** (layers), not a second source of defaults:

| Layer | Role | Manifest default (global surfaces) | Examples |
|-------|------|-------------------------------------|----------|
| **Core Workstation** | Daily dev tools | enabled | `docker`, `github`, `fetch`, … |
| **Platform Specialized** | Local stack services | enabled (readiness if down) | `dagster`, `loki`, `prometheus`, `tempo`, `minio`, `store_etl_ops` |
| **Data / Connection-oriented** | DB engines, credentials | enabled; secrets via env/files | `postgres`, `trino` |

### Runtime vs Connection Profile

```
┌─────────────────────────────────────────────────────────┐
│  MCP Tool (shared)                                      │
│  - npx package                                          │
│  - python -m module                                     │
│  - launcher script                                      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Connection profile (sensitive / per machine or project) │
│  - DSN / endpoint                                       │
│  - Credentials / secrets                                │
│  - Catalog / schema                                     │
└─────────────────────────────────────────────────────────┘
```

### Anti-Patterns to Avoid

| Anti-Pattern | Why it's wrong | Correct approach |
|--------------|----------------|-----------------|
| Hardcoded DSN or passwords in repo templates | Secrets in git | Paths + `keys_hint` in manifest; values in `mcp-secrets.env` |
| Silently omitting an MCP from a surface | Hides intent drift | `enabled: false` + `reason` in **`MANIFEST.yaml`** only |
| Secrets file named after a client | Couples secrets to tool naming | Neutral names like `mcp-secrets.env` |
| A second “default disabled” policy in scripts | Contradicts manifest | Use **`make ai-mcp-governance`** + **`make ai-cursor-check`** |

### Adding a New MCP

1. Add or update **`MANIFEST.yaml`** (all surfaces; document exceptions with `reason`).
2. Update **`scripts/generate-mcp-configs.py`** recipes if command/env differ.
3. Run **`make ai-mcp-governance`**, then **`make ai-mcp-generate APPLY=1`** when you intend to refresh Chezmoi templates.

### Quick Reference (intent lives in the manifest)

Use **`docs/MCP_TAXONOMY.md`** and **`docs/MCP_QUICKREF.md`** for the authoritative list by layer; defaults follow **`MANIFEST.yaml`**, not this historical section.
