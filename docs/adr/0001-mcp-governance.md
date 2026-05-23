# ADR: MCP Governance - Layered Architecture for Database and Platform MCPs

**Date:** 2025-03-17  
**Status:** Accepted  
**Author:** jesus

---

## Context

This repo integrates multiple MCP (Model Context Protocol) servers across different AI clients (OpenCode, Cursor, Codex). The current implementation includes:

- **Core Workstation MCPs**: `docker`, `github`, `fetch`, `context7`, `excalidraw_canvas`, `playwright`, `filesystem`, `git`, `sequential-thinking`
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

> **Note (2026):** Default **`enabled`** intent for global agent surfaces is now driven solely by **`ai/assets/mcps/MANIFEST.yaml`** (`compatible_by_default_enabled: true`). The table below records the **original 2025 classification**; product defaults for Cursor/Codex/OpenCode follow the manifest and the **Evolution (2026)** section, not the middle column here.

### 1. Three-Layer Classification

| Layer | Scope | `enabled` default (historical 2025) | Rationale |
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
  - Policy: Fixed whitelist of allowed roots (/home/jesus/dotfiles, /home/jesus/proyectos, /home/jesus/.config, plus Obsidian vault path from Chezmoi data `ai.obsidian_vault_path` in the managed launcher template)

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

### 3. Activation Policy (historical 2025)

- **Core Workstation MCPs**: Always enabled globally
- **Platform Specialized MCPs**: (Superseded for global templates — see **Evolution (2026)**.) Historically: disabled by default in global configs.
- **Connection-Specific MCPs**: Runtime shared; connection material outside git or per-stack configs

### 4. Anti-Patterns Prohibited

| Anti-Pattern | Why |
|--------------|-----|
| Hardcoded DSN in global config | Couples all projects to one database |
| Secret **values** committed in repo or manifest | Use paths / `keys_hint` only; values in user secrets files |
| Silently omitting an MCP from a surface without manifest `reason` | Hides intent drift vs other agents |
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

- **Project-specific configs**: Optional stack configs live in their own project repositories (for example, `store-etl/.cursor/mcp.json`). Dotfiles owns only global workstation templates and shared launchers; global parity is defined in **`MANIFEST.yaml`**.
- **GitNexus**: MCP global de conocimiento estructural. Su índice vive en `~/.gitnexus/` y es multi-repo. La wiki generada se направляет a `docs/wiki/` por convención.

---

## Evolution (2026) — compatible-enabled-by-default

Earlier sections of this ADR assumed **platform MCPs disabled by default** in global configs and **database MCPs** limited to project-local templates to avoid noisy connection failures.

That policy is **partially superseded** for **global agent parity**:

- **Canonical intent** for which MCPs exist and how they apply to **Cursor, Codex, and OpenCode** now lives in **`ai/assets/mcps/MANIFEST.yaml`**, validated with **`make ai-mcp-validate`**.
- **Default:** every compatible MCP is **intended `enabled: true`** on all three surfaces. Gaps (missing services, secrets, binaries, WSL paths) are handled by **readiness** tooling (`make ai-cursor-check` and future checks), not by silently withholding a server from one client.
- **Exceptions** must be explicit in the manifest: `enabled: false` plus a non-empty **`reason`** (e.g. a future technical incompatibility).
- **Chezmoi templates** can be synced from manifest + recipes using **`make ai-mcp-generate APPLY=1`** (after `make ai-mcp-validate`, `make ai-mcp-render`, and `make ai-mcp-drift` with no unexpected drift). Without **`APPLY=1`**, `make ai-mcp-generate` is plan-only and writes nothing. Publishing to HOME still requires **chezmoi apply**. **`bin/validate-mcp-governance`** (and **`make ai-mcp-governance`**) orchestrates the same non-mutating gates as **`ai-mcp-validate`**, **`ai-mcp-render`**, and **`ai-mcp-drift`**; it does **not** embed a second product policy and does **not** substitute readiness checks (**`make ai-cursor-check`**).

The separation **runtime (shared) vs connection profile (sensitive / per-project)** remains valid engineering guidance; only the *default visibility* of those MCPs across global agent surfaces changed.

---

## References

- Taxonomía: `docs/MCP_TAXONOMY.md`
- Operational guide: `docs/OPENCODE.md`
- Agent instructions: `dot_config/opencode/AGENTS.md.tmpl`
- Implementation: project-local MCP files, outside this dotfiles repository
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
