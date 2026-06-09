# ADR: GitNexus as Global Knowledge MCP

**Date:** 2026-03-18  
**Status:** Accepted  
**Author:** jesus

**Status update — 2026-06-09:** This ADR is superseded in part by the agent-first GitNexus runtime policy (M6A/M6B). GitNexus MCP is launched through the dotfiles MCP launcher (`mcp-gitnexus-launcher`, materialized under `~/.local/share/chezmoi/bin/`) and resolves the canonical agent path `~/.local/bin/gitnexus`. The real npm-managed installation is `~/.npm-global/bin/gitnexus`; `~/.local/bin/gitnexus` is materialized as the agent-facing symlink to that binary. Agents must not use `npx gitnexus@latest` as the default MCP or analysis path. Agents should run `make gitnexus-status` before relying on read-only impact/context. Operational detail: [`docs/GITNEXUS_OPERATIONAL_POLICY.md`](../GITNEXUS_OPERATIONAL_POLICY.md), [`docs/MCP_QUICKREF.md`](../MCP_QUICKREF.md).

---

## Context

The workstation needs a way to understand the structure, relationships, and execution flows within any repository. While other MCPs provide execution capabilities (docker, postgres, fetch), there's no MCP for code comprehension and documentation generation.

GitNexus is a tool that:
- Indexes repositories to build a knowledge graph (symbols, edges, clusters, processes)
- Provides contextual queries about code structure
- Can generate wikis from the knowledge graph using LLMs

---

## Decision

### 1. Classification: Knowledge/Semantic Layer

GitNexus is classified as a **Knowledge/Semantic MCP** in the three-layer architecture:

| Layer | Rationale |
|-------|-----------|
| Core Workstation | Transversal execution tools (docker, fetch, etc.) |
| Knowledge/Semantic | Code understanding and documentation |
| Platform Specialized | Service-specific (dagster, minio, etc.) |

### 2. MCP Execution Pattern

**Current (agent-first):** Productive MCP clients (Cursor, OpenCode, Codex) invoke the materialized launcher, which executes `~/.local/bin/gitnexus mcp` without `npx` at runtime:

```json
{
  "mcpServers": {
    "gitnexus": {
      "command": "~/.local/share/chezmoi/bin/mcp-gitnexus-launcher"
    }
  }
}
```

The launcher resolves `~/.local/bin/gitnexus` first (see operational policy for `MCP_GITNEXUS_BIN` override).

**Historical (2026-03):** An earlier pattern used `npx -y gitnexus@latest mcp` in client configs. That path is **not** the current default for agents: it may bind to IDE-injected Node and bypass the managed npm install.

### 3. CLI Installation and Canonical Agent Path

The CLI is installed globally via npm but exposed to agents through a canonical symlink:

| Role | Path |
|------|------|
| Real npm install | `~/.npm-global/bin/gitnexus` |
| Canonical agent path | `~/.local/bin/gitnexus` → `~/.npm-global/bin/gitnexus` |

- **Installation**: `scripts/install-gitnexus.sh` (also materializes the canonical symlink)
- **Update**: `make update-wsl` / `make update` (tools section)
- **Alignment check**: `make gitnexus-status` (read-only; includes path alignment)

This avoids sudo permission issues and keeps one managed version for terminal, MCP, and `gnx-*` aliases.

### 4. Multi-Repo Index Architecture

GitNexus maintains a global index at `~/.gitnexus/`:

```
~/.gitnexus/
├── registry.json    # Indexed repositories
└── config.json      # API keys, preferences

<repo>/.gitnexus/
├── lbug             # Knowledge graph (binary)
└── meta.json        # Index metadata
```

Each project gets indexed individually via `gitnexus analyze`.

### 5. Wiki Output Convention

Wiki generation targets `docs/wiki/` per project:

```bash
gnx-wiki-here  # Generates wiki to docs/wiki/
```

This convention:
- Keeps wiki alongside code
- Works with gitignored `.gitnexus/` directory
- Follows common documentation patterns

> **Note:** `.gitnexus/` is GitNexus internal local state, stored per-project. It is ignored by git (see `.gitignore`). The official project documentation lives in `docs/wiki/`.

### 6. LLM Requirement for Wiki

**Important:** GitNexus wiki generation requires an LLM API key because it generates documentation using AI.

Options:
- `OPENAI_API_KEY` (preferred)
- `GITNEXUS_API_KEY`
- `--api-key` flag

Without an API key, `gnx-wiki-here` provides clear guidance.

---

## Consequences

### Positive

- **Cross-repo understanding**: One tool indexes all repos
- **Consistent patterns**: Same MCP config across all clients
- **IDE integration**: Cursor, OpenCode, Codex all use the same index
- **Documentation**: Auto-generated wikis from code structure

### Negative

- **LLM dependency**: Wiki generation requires API key (OpenAI)
- **Separate maintenance**: CLI needs `make update`, MCP uses launcher
- **Index storage**: Each repo stores ~20-30MB in `.gitnexus/`

### Neutral

- **Not a project-specific MCP**: GitNexus is global, not tied to one project
- **Works offline**: Basic queries (context, impact, query) work without LLM
- **Wiki is optional**: Serve and analyze work without API key

---

## Helpers

| Command | Purpose |
|---------|---------|
| `make gitnexus-status` | Read-only index/lock/Node/path alignment (agents) |
| `make update` | Updates GitNexus CLI and canonical symlink |
| `gnx-serve` | Starts local HTTP server (human) |
| `gnx-analyze-here` | Indexes current repo (human) |
| `gnx-map` | Analyzes + serves (human) |
| `gnx-wiki-here` | Generates wiki (human; requires API key) |

---

## References

- MCP Governance ADR: `docs/adr/0001-mcp-governance.md`
- Operational policy: `docs/GITNEXUS_OPERATIONAL_POLICY.md`
- MCP Quick Reference: `docs/MCP_QUICKREF.md`
- Canonical symlink helper: `scripts/lib/gitnexus_canonical.sh`
- GitNexus CLI install: `scripts/install-gitnexus.sh`
- MCP launcher: `bin/mcp-gitnexus-launcher`
- GitNexus skills: `ai/assets/skills/gitnexus/`
