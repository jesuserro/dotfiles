# ADR: GitNexus as Global Knowledge MCP

**Date:** 2026-03-18  
**Status:** Accepted  
**Author:** jesus

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

The MCP always uses `@latest` to ensure freshness:

```json
{
  "mcpServers": {
    "gitnexus": {
      "command": "npx",
      "args": ["-y", "gitnexus@latest", "mcp"]
    }
  }
}
```

This pattern is used in:
- Cursor: `~/.cursor/mcp.json`
- OpenCode: `~/.config/opencode/opencode.json`
- Codex: `~/.codex/config.toml`

### 3. CLI Installation Separately

The CLI is installed globally but separately from the MCP:

- **Installation**: `npm install -g --prefix=~/.local gitnexus@latest`
- **Update**: Via `ups` command
- **Location**: `~/.local/bin/gitnexus`

This avoids sudo permission issues and keeps the CLI independent from MCP clients.

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
- **Separate maintenance**: CLI needs `ups`, MCP uses npx
- **Index storage**: Each repo stores ~20-30MB in `.gitnexus/`

### Neutral

- **Not a project-specific MCP**: GitNexus is global, not tied to one project
- **Works offline**: Basic queries (context, impact, query) work without LLM
- **Wiki is optional**: Serve and analyze work without API key

---

## Helpers

| Command | Purpose |
|---------|---------|
| `ups` | Updates GitNexus CLI |
| `gnx-serve` | Starts local HTTP server |
| `gnx-analyze-here` | Indexes current repo |
| `gnx-map` | Analyzes + serves |
| `gnx-wiki-here` | Generates wiki (requires API key) |

---

## References

- MCP Governance ADR: `docs/adr/0001-mcp-governance.md`
- MCP Quick Reference: `docs/MCP_QUICKREF.md`
- GitNexus CLI: `scripts/install-gitnexus.sh`
- GitNexus skills: `.claude/skills/gitnexus/`
