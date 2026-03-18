# MCP Quick Reference

**For AI agents working with this dotfiles repository**

## Three Layers

| Layer | Scope | `enabled` | Examples |
|-------|-------|-----------|----------|
| Core | All projects | true | docker, github, fetch, context7, excalidraw, playwright, filesystem, git, sequential-thinking |
| Knowledge/Semantic | All projects | true | gitnexus |
| Platform | All (opt-in) | false | dagster, loki, minio, prometheus, tempo |
| Connection-Specific | Per-project | per-project | postgres, trino |

## GitNexus

| Aspect | Value |
|--------|-------|
| **Type** | Knowledge/Semantic MCP |
| **Scope** | Global (multi-repo) |
| **Config Pattern** | `npx -y gitnexus@latest mcp` |
| **Index Location** | `~/.gitnexus/` |
| **CLI** | Installed via npm in `~/.local` |
| **Wiki Output** | `docs/wiki/` (per project) |
| **LLM Required** | Yes (OpenAI API key for wiki) |

### GitNexus Helpers

```bash
ups              # Updates GitNexus CLI
gnx-serve        # Start local server
gnx-analyze-here # Analyze current repo
gnx-map          # Analyze + serve
gnx-wiki-here    # Generate wiki (requires OPENAI_API_KEY)
```

## Filesystem MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (filesystem access) |
| **Scope** | Global with whitelist policy |
| **Config Pattern** | Launcher wrapper |
| **Allowed Roots** | `/home/jesus/dotfiles`, `/home/jesus/proyectos`, `/home/jesus/.config`, `/mnt/c/Users/jesus/Documents/vault` |
| **Launcher** | `~/.local/share/chezmoi/bin/mcp-filesystem-launcher` |

### Policy

- Fixed whitelist: Only directories explicitly listed are accessible
- No dynamic cwd-based access as primary policy
- Additional paths can be passed but must be within allowed roots

## Git MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (Git operations) |
| **Scope** | Global (dynamic repo detection) |
| **Config Pattern** | Launcher wrapper |
| **Detection** | `git rev-parse --show-toplevel` from cwd |
| **Override** | `MCP_GIT_REPO` environment variable |
| **Launcher** | `~/.local/share/chezmoi/bin/mcp-git-launcher` |

### Behavior

- Detects repo from current working directory
- Fails clearly if not inside a Git repository
- Allows explicit override via `MCP_GIT_REPO`

## Sequential Thinking MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (cognitive support) |
| **Scope** | Global |
| **Config Pattern** | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| **Purpose** | Structured reasoning tool for complex problem solving |

### Note

This MCP is from the official MCP repository. It provides cognitive support for reasoning but does not have direct system access.

## Anti-Patterns

- ❌ Hardcoded DSN in global config
- ❌ Database MCPs as "global" connections
- ❌ Platform MCPs enabled by default
- ❌ Client-named secrets (use `mcp-secrets.env`)

## Key Files

- `docs/adr/0001-mcp-governance.md` — Full ADR
- `docs/OPENCODE.md` — Operational guide
- `ai/assets/skills/mcp-governance/SKILL.md` — Skill for agents

## Runtime vs Connection

```
Runtime (shared) ──▶ Connection (project-specific)
npx/python/wrapper     DSN/credentials/env
```

## Adding MCPs

1. Classify: Core / Platform / Connection-Specific
2. Set correct `enabled` default
3. Use shared runtime paths
4. Keep connection profile project-specific
5. Validate: `~/dotfiles/bin/validate-mcp-governance`
