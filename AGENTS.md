<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **dotfiles** (3154 symbols, 3648 relationships, 60 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `make gitnexus-status`. Agents must not auto-refresh; ask Jesús before `gnx-analyze-here`. See `docs/GITNEXUS_OPERATIONAL_POLICY.md`.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/dotfiles/context` | Codebase overview, check index freshness |
| `gitnexus://repo/dotfiles/clusters` | All functional areas |
| `gitnexus://repo/dotfiles/processes` | All execution flows |
| `gitnexus://repo/dotfiles/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `ai/assets/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `ai/assets/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `ai/assets/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `ai/assets/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `ai/assets/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

## Vault Project Wiki

When a relevant implementation leaves durable knowledge behind, use `ai/assets/skills/ops/vault-project-wiki/SKILL.md` and `docs/VAULT_PROJECT_WIKI_FLOW.md` to decide whether it belongs in `vault_trabajo/projects/<project>/knowledge/...`.

- Keep the project repo as the source of truth for code and implementation docs
- Use the vault for distilled, reusable project knowledge
- Use `dotfiles` as the transversal operational layer that teaches agents when and how to capture that knowledge
