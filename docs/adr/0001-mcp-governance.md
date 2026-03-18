# ADR: MCP Governance - Layered Architecture for Database and Platform MCPs

**Date:** 2025-03-17  
**Status:** Accepted  
**Author:** jesus

---

## Context

This repo integrates multiple MCP (Model Context Protocol) servers across different AI clients (OpenCode, Cursor, Codex). The current implementation includes:

- **Core Workstation MCPs**: `docker`, `github`, `fetch`, `context7`, `excalidraw`, `playwright`, `filesystem`, `git`, `sequential-thinking`
- **Knowledge/Semantic MCPs**: `gitnexus`
- **Platform Specialized MCPs**: `dagster`, `loki`, `minio`, `prometheus`, `tempo`, `store_etl_ops`
- **Database MCPs**: `postgres`, `trino`

A decision was needed on how to classify, scope, and configure these MCPs to avoid:
- Globalizing project-specific connections
- Coupling all projects to a single DSN or credential set
- Causing connection errors from missing services
- Mixing shared runtime with connection profiles

---

## Decision

### 1. Three-Layer Classification

| Layer | Scope | `enabled` default | Rationale |
|-------|-------|-------------------|-----------|
| **Core Workstation** | All projects | `true` | Transversal tools used everywhere |
| **Knowledge/Semantic** | All projects | `true` | Code understanding and documentation |
| **Platform Specialized** | All projects (opt-in) | `false` | Requires specific local services |
| **Connection-Specific** | Per-project only | Per-project config | Credentials are project-dependent |

### 2. Runtime vs Connection Profile Separation

For database and platform MCPs, distinguish between:

- **Runtime/Launcher**: The tool itself (`npx package`, `python -m module`, wrapper script). Can be shared globally.
- **Connection Profile**: The specific endpoint, credentials, DSN, catalog, schema. Must remain project-specific.

Example:
```
postgres MCP:
  - Runtime: ~/.local/share/chezmoi/bin/mcp-postgres-launcher  (shared)
  - Connection: ~/.config/mcp-secrets.env (POSTGRES_DSN)         (project-specific)

filesystem MCP:
  - Runtime: ~/.local/share/chezmoi/bin/mcp-filesystem-launcher (shared)
  - Policy: Fixed whitelist of allowed roots (/home/jesus/dotfiles, /home/jesus/proyectos, /home/jesus/.config, /mnt/c/Users/jesus/Documents/vault)

git MCP:
  - Runtime: ~/.local/share/chezmoi/bin/mcp-git-launcher        (shared)
  - Repository: Dynamically detected from cwd (git rev-parse --show-toplevel) or MCP_GIT_REPO env var
```
postgres MCP:
  - Runtime: ~/.local/share/chezmoi/bin/mcp-postgres-launcher  (shared)
  - Connection: ~/.config/mcp-secrets.env (POSTGRES_DSN)         (project-specific)

trino MCP:
  - Runtime: ~/.config/ai/runtime/.venv/bin/python -m trino_mcp  (shared)
  - Connection: env block (TRINO_HOST, TRINO_CATALOG, etc.)      (project-specific)
```

### 3. Activation Policy

- **Core Workstation MCPs**: Always enabled globally
- **Platform Specialized MCPs**: Disabled by default, enable per-project when the service is available
- **Connection-Specific MCPs**: Never globalize the connection; keep in project-specific config

### 4. Anti-Patterns Prohibited

| Anti-Pattern | Why |
|--------------|-----|
| Hardcoded DSN in global config | Couples all projects to one database |
| "Global" database MCP | Assumes one DSN fits all projects |
| `enabled: true` for platform MCPs | Causes connection errors when services are down |
| Secrets file named after client | Couples secrets to tool naming (use neutral names) |

---

## Consequences

### Positive

- **Isolation**: No cross-project credential leakage
- **Reliability**: No MCP connection errors from missing services in unrelated projects
- **Scalability**: Clear pattern for adding future MCPs
- **Maintainability**: Runtime can be updated centrally, connection config stays project-scoped

### Negative

- **Complexity**: More configuration files than a simple global approach
- **Awareness required**: Developers must understand the layer classification

### Neutral

- **Project-specific configs**: MCPs like `postgres` and `trino` live in `dot_config/store-etl/` not in global config
- **GitNexus**: MCP global de conocimiento estructural. Su índice vive en `~/.gitnexus/` y es multi-repo. La wiki generada se направляет a `docs/wiki/` por convención.

---

## References

- Taxonomía: `docs/MCP_TAXONOMY.md`
- Operational guide: `docs/OPENCODE.md`
- Agent instructions: `dot_config/opencode/AGENTS.md.tmpl`
- Implementation: `dot_config/store-etl/store-etl.mcp.json.tmpl`
- GitNexus integration: ADR `0002-gitnexus-mcp.md`

---

## Adding New ADRs

New architectural decisions should be documented as ADRs in this folder.

**Naming convention:** `XXXX-title-slug.md` (4-digit sequence + descriptive slug)

**Template:** See `docs/adr/template.md`

**Process:**
1. Copy template to new file with appropriate sequence number
2. Fill in the sections
3. Set status to "Proposed"
4. After review/acceptance, update status to "Accepted"
