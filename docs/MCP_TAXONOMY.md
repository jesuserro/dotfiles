# MCP Taxonomy

Canonical reference for MCP classification in this dotfiles repository.

---

## Purpose

This document establishes the taxonomy for all MCPs integrated in the workstation. It provides:
- Classification by functional layer
- Operational policy (how each type is managed)
- Criteria for adding/removing MCPs

---

## Classification Layers

| Layer | Scope | Default | Examples |
|-------|-------|---------|----------|
| **Core** | All projects | `true` | docker, github, fetch, context7, filesystem, git, sequential-thinking |
| **Knowledge/Semantic** | All projects | `true` | gitnexus |
| **Domain-Specific** | Opt-in | `false` | obsidian |
| **Platform** | Opt-in | `false` | dagster, loki, minio, prometheus, tempo, store_etl_ops |
| **Connection-Specific** | Per-project | per-project | postgres, trino |

### Layer Descriptions

**Core:** Transversal tools used in daily development workflow. Always available.

**Knowledge/Semantic:** Code understanding and documentation generation. Always available.

**Domain-Specific:** Tools focused on specific domains (e.g., Obsidian). Disabled by default, enable when needed.

**Platform:** Tools requiring specific local services. Disabled by default to avoid connection errors.

**Connection-Specific:** MCPs with project-dependent credentials. Runtime is global, connection is project-specific.

---

## Operational Policy

### Ups-Managed (Explicit Updates)

These MCPs require explicit installation or update via `ups`:

| MCP | Update Method |
|-----|--------------|
| gitnexus CLI | `npm install -g --prefix=~/.local gitnexus@latest` |
| excalidraw | `git pull` + `pnpm install` + `pnpm run build` |
| fetch | `uv tool install mcp-server-fetch` |
| docker, postgres | `npm update` in `~/.config/mcp/servers/*/` |
| Python MCPs | `pip install -r requirements.txt -U` in venv |

### Runtime-Managed (Automatic)

These MCPs use `npx -y` or `uvx` and get latest version automatically:

| MCP | Command |
|-----|---------|
| context7 | `npx -y @upstash/context7-mcp` |
| github | `npx -y @modelcontextprotocol/server-github` |
| sequential-thinking | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| obsidian | `npx -y @bitbonsai/mcpvault` |
| git | `uvx mcp-server-git` |

### Launcher-Managed

MCPs using custom launchers (no update needed):

| MCP | Launcher |
|-----|----------|
| filesystem | `~/.local/share/chezmoi/bin/mcp-filesystem-launcher` |
| git | `~/.local/share/chezmoi/bin/mcp-git-launcher` |

---

## Adding a New MCP

### Criteria for Acceptance

1. **Usefulness:** Provides clear value for development workflow
2. **Scope:** Fits into existing layer taxonomy
3. **Maintenance:** Can be maintained without excessive effort
4. **Security:** No significant security concerns
5. **Integration:** Follows existing patterns (launchers if needed, configuration templates)

### Process

1. Classify: Core / Knowledge / Domain / Platform / Connection
2. Set correct `enabled` default
3. Add to configuration templates (Cursor, OpenCode, Codex)
4. Document in MCP_QUICKREF.md
5. Update UPS.md if explicit update needed
6. Add validation in `bin/validate-mcp-governance` if applicable

---

## Deprecation/Removal Criteria

1. **No longer maintained:** Package abandoned or incompatible
2. **Redundancy:** Functionality covered by another MCP
3. **Security concerns:** Unresolved vulnerabilities
4. **Better alternatives:** Significantly superior replacement available

---

## Scope Definitions

| Type | Definition | Configuration |
|------|------------|---------------|
| **Global** | Available in all projects | Templates in `dot_cursor/`, `dot_codex/`, `dot_config/opencode/` |
| **Domain-Optional** | Global but disabled by default | Same as global, `enabled: false` |
| **Project-Local** | Per-project only | In project's own config, not in global templates |

---

## Key References

| Document | Purpose |
|----------|---------|
| `docs/MCP_TAXONOMY.md` | This document - canonical taxonomy |
| `docs/MCP_QUICKREF.md` | Quick reference for agents |
| `docs/adr/0001-mcp-governance.md` | Architectural decision record |
| `docs/UPS.md` | Update management |
| `bin/validate-mcp-governance` | Validation script |

---

## Current Configuration

See `docs/MCP_QUICKREF.md` for the current list of MCPs in each layer.
