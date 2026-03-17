# MCP Quick Reference

**For AI agents working with this dotfiles repository**

## Three Layers

| Layer | Scope | `enabled` | Examples |
|-------|-------|-----------|----------|
| Core | All projects | true | docker, github, fetch, context7, excalidraw, playwright |
| Platform | All (opt-in) | false | dagster, loki, minio, prometheus, tempo |
| Connection-Specific | Per-project | per-project | postgres, trino |

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
