# MCP Quick Reference

**For AI agents working with this dotfiles repository**

## Three Layers

| Layer | Scope | `enabled` | Examples |
|-------|-------|-----------|----------|
| Core | All projects | true | docker, github, fetch, context7, excalidraw, playwright |
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
