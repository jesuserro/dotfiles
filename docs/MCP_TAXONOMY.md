# MCP Taxonomy

Canonical reference for MCP classification in this dotfiles repository.

---

## Purpose

This document establishes the taxonomy for all MCPs integrated in the workstation. It provides:
- Classification by functional layer
- Operational policy (how each type is managed)
- Criteria for adding/removing MCPs

**Canonical activation intent** for Cursor, Codex, and OpenCode lives in **`ai/assets/mcps/MANIFEST.yaml`** (validated with `make ai-mcp-validate`). Layers below describe *role*; default **enabled** intent for every compatible MCP on every surface is **true**, with missing services or secrets handled by **readiness** checks, not by silently dropping servers from a client.

---

## Classification Layers

| Layer | Scope | Manifest default (global surfaces) | Examples |
|-------|-------|--------------------------------------|----------|
| **Core** | All projects | enabled | docker, github, fetch, context7, filesystem, git, sequential-thinking |
| **Knowledge/Semantic** | All projects | enabled | gitnexus |
| **Domain-Specific** | Vault / host paths | enabled (readiness if path missing) | obsidian |
| **Platform** | Local services | enabled (readiness if service down) | dagster, loki, minio, prometheus, tempo, store_etl_ops |
| **Connection-Specific** | Credentials / DSN | enabled (readiness if secrets or DB absent) | postgres, trino |

### Layer Descriptions

**Core:** Transversal tools used in daily development workflow. Always available.

**Knowledge/Semantic:** Code understanding and documentation generation. Always available.

**Domain-Specific:** Tools focused on specific domains (e.g., Obsidian). Intended enabled globally; path and host availability are readiness concerns.

**Platform:** Tools requiring specific local services. Intended enabled globally; connectivity errors are readiness WARN/MISSING, not a reason to omit the MCP from the manifest.

**Connection-Specific:** MCPs with project-dependent credentials. Runtime is global, connection is project-specific.

---

## Operational Policy

### Update-Managed (Explicit Updates)

These MCPs require explicit installation or update via `make update` or a dedicated Make target:

| MCP | Update Method |
|-----|--------------|
| gitnexus CLI | `npm install -g --prefix=~/.npm-global gitnexus@latest` |
| excalidraw | `make excalidraw-update` pulls Docker images; MCP clients run `docker run -i --rm` |
| fetch | `uv tool install mcp-server-fetch` |
| docker | Docker Desktop MCP Gateway: `docker.exe mcp gateway run` from WSL |
| postgres | `npm update` in `~/.config/mcp/servers/*/` (only if present) |
| Python MCPs | `pip install -r requirements.txt -U` in venv |

### Runtime-Managed (Automatic)

These MCPs use `npx -y` or `uvx` and get latest version automatically:

| MCP | Command |
|-----|---------|
| context7 | `npx -y @upstash/context7-mcp` |
| github | `npx -y @modelcontextprotocol/server-github` |
| sequential-thinking | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| obsidian | `npx -y @bitbonsai/mcpvault` + vault path from Chezmoi `ai.obsidian_vault_path` (see [CHEZMOI.md](./CHEZMOI.md)) |
| git | `uvx mcp-server-git` |

### Docker Desktop MCP Gateway on WSL

Docker MCP uses the official Docker Desktop MCP Gateway, launched as
`docker.exe mcp gateway run`. From WSL, prefer `docker.exe` because the Linux
`docker mcp gateway run` command can report `Docker Desktop is not running`
even when `docker ps` and the Docker Engine work through Docker Desktop.

Manual validation:

```bash
docker.exe mcp version
docker.exe mcp profile ls
timeout 8s docker.exe mcp gateway run
```

The legacy `npx -y @0xshariq/docker-mcp-server` runtime is discarded here
because it behaves like a CLI in Cursor, prints help, and exits.

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
2. Add or update the entry in `ai/assets/mcps/MANIFEST.yaml` (all three surfaces; document any `enabled: false` with `reason`)
3. Run `make ai-mcp-validate`
4. Update execution recipes in `scripts/generate-mcp-configs.py` if `command`/`args`/`env` change; run `make ai-mcp-render` and `make ai-mcp-drift`
5. When ready, run `make ai-mcp-generate APPLY=1`, then `chezmoi apply` (or `make install-dotfiles DOTFILES_APPLY=1`)
6. Document in MCP_QUICKREF.md
7. Update UPDATE.md if explicit update needed
8. Run `make ai-mcp-governance` (or `bin/validate-mcp-governance`) before commit when MCP intent or templates change

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
| **Domain-Optional** | Global; path-dependent | Same as global; readiness if vault/host path missing |
| **Project-Local** | Per-project only | In project's own config, not in global templates |

---

## Key References

| Document | Purpose |
|----------|---------|
| `docs/MCP_TAXONOMY.md` | This document - canonical taxonomy |
| `docs/MCP_QUICKREF.md` | Quick reference for agents |
| `docs/adr/0001-mcp-governance.md` | Architectural decision record |
| `docs/UPDATE.md` | Update management |
| `ai/assets/mcps/MANIFEST.yaml` | Canonical MCP intent per surface |
| `make ai-mcp-validate` | Manifest structure and policy checks |
| `make ai-mcp-render` / `make ai-mcp-drift` | Dry-run under `build/mcps/` + drift vs templates |
| `make ai-mcp-generate APPLY=1` | Write productive MCP templates after gates (no `APPLY` = plan only) |
| `make ai-mcp-governance` / `bin/validate-mcp-governance` | Non-mutating: validate + render + drift (repo governance) |

---

## Current Configuration

See `docs/MCP_QUICKREF.md` for the current list of MCPs in each layer.
