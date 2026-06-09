---
name: gitnexus-cli
description: "Use when the user needs to run GitNexus CLI commands like analyze/index a repo, check status, clean the index, generate a wiki, or list indexed repos. Examples: \"Index this repo\", \"Reanalyze the codebase\", \"Generate a wiki\""
---

# GitNexus CLI Commands

In dotfiles/WSL, agents use read-only status first. Mutating CLI commands require explicit human approval.

## Agent-safe status

```bash
make gitnexus-status
```

Read-only: index freshness (`FRESH`/`STALE`/`NO_INDEX`), lock file, Node runtime, **GitNexus path alignment** (canonical `~/.local/bin/gitnexus` symlink → `~/.npm-global/bin/gitnexus`, PATH vs MCP, version mismatch risk), artifacts. See `docs/GITNEXUS_OPERATIONAL_POLICY.md`.

**Layout dotfiles:** npm install real en `~/.npm-global/bin/gitnexus`; cara agent-first `~/.local/bin/gitnexus` (symlink mantenido por install/update). MCP usa la canónica.

Interpretación rápida de path alignment:

- `OK: GitNexus path alignment is agent-safe` → MCP read-only (`query`, `context`, `impact`, …) es fiable.
- `WARN` de PATH/MCP/version → no refrescar; usar fallback manual. Humano: `scripts/install-gitnexus.sh` o `make update-wsl --section tools`, `exec zsh -l`, reiniciar MCP, `make gitnexus-status`.

## Commands

### Runtime precheck

On dotfiles/WSL, run the read-only precheck before any human-initiated re-index:

```bash
make update-check
```

If it warns that the effective Node runtime comes from Cursor/VS Code and is below the repo policy (`>=22`), but reports a managed compatible runtime, a **human** may use `gnx-analyze-here` (not raw `gitnexus analyze` or `npx gitnexus`). If no managed compatible runtime is available, reconcile Node with `make install-node-stack` before re-indexing.

### analyze — Build or refresh the index (human only)

**Agents:** use `make gitnexus-status` only; do not auto-refresh on STALE.

**Humans (dotfiles default):** refresh index without touching versioned agent blocks:

```bash
make gitnexus-status
# Close Cursor / disable GitNexus MCP if live processes or lock in use; re-run status
gnx-analyze-here --skip-agents-md
make gitnexus-status
```

`gnx-analyze-here` loads the shared Node runtime policy and avoids IDE Node 20 / npx. **`--skip-agents-md`** skips regenerating `AGENTS.md` / `CLAUDE.md`. See `docs/GITNEXUS_OPERATIONAL_POLICY.md`.

| Flag               | Effect                                                           |
| ------------------ | ---------------------------------------------------------------- |
| `--skip-agents-md` | Index only; do not rewrite `AGENTS.md` / `CLAUDE.md` blocks      |
| `--force`          | Force full re-index even if up to date                           |
| `--embeddings`     | Enable embedding generation for semantic search (off by default) |

**Exception:** `gnx-analyze-here` without `--skip-agents-md` may regenerate `<!-- gitnexus:* -->` blocks — review diff and run `agents-claude-gitnexus-blocks.bats` before commit.

**When a human runs it:** After explicit need (not STALE alone), with no live GitNexus MCP processes holding `.gitnexus/lbug`.

### status — Check index freshness

Prefer the dotfiles read-only helper:

```bash
make gitnexus-status
```

Manual fallback (outside IDE agent shells, if CLI installed): `gitnexus status`.

### clean — Delete the index (human only)

**Agents must not run clean.** Manual fallback: `gitnexus clean` from a normal shell after human decision.

| Flag      | Effect                                            |
| --------- | ------------------------------------------------- |
| `--force` | Skip confirmation prompt                          |
| `--all`   | Clean all indexed repos, not just the current one |

### wiki — Generate documentation from the graph (human only)

**Agents must not run wiki.** Human helper: `gnx-wiki-here` (requires API key). Manual fallback: `gitnexus wiki` with `--api-key`.

| Flag                | Effect                                    |
| ------------------- | ----------------------------------------- |
| `--force`           | Force full regeneration                   |
| `--model <model>`   | LLM model (default: minimax/minimax-m2.5) |
| `--base-url <url>`  | LLM API base URL                          |
| `--api-key <key>`   | LLM API key                               |
| `--concurrency <n>` | Parallel LLM calls (default: 3)           |
| `--gist`            | Publish wiki as a public GitHub Gist      |

### list — Show all indexed repos

Manual fallback: `gitnexus list`. The MCP `list_repos` tool provides the same information for agents.

## After Indexing

1. **Read `gitnexus://repo/{name}/context`** to verify the index loaded
2. Use the other GitNexus skills (`exploring`, `debugging`, `impact-analysis`, `refactoring`) for your task

## Troubleshooting

- **"Not inside a git repository"**: Run from a directory inside a git repo
- **Index stale (agents)**: Run `make gitnexus-status`; do not run analyze; ask Jesús for human refresh
- **Human refresh (dotfiles)**: `make gitnexus-status` → close MCP if needed → `gnx-analyze-here --skip-agents-md` → `make gitnexus-status` again
- **Analyze is slow or appears stuck under Cursor**: Run `make update-check`; human uses `gnx-analyze-here`, not `gitnexus analyze` or `npx gitnexus`
- **Index is stale after re-analyzing**: Restart Cursor / MCP client to reload the index
- **Lock on `.gitnexus/lbug`**: Run `make gitnexus-status`; close Cursor or disable GitNexus MCP; never delete `lbug` automatically
- **Embeddings slow**: Omit `--embeddings` (it's off by default) or set `OPENAI_API_KEY` for faster API-based embedding

## npx fallback (exceptional manual use only)

`npx` with the gitnexus package is **not** the default path for agents or IDE shells (may pull packages over network and use IDE Node). Use only from a normal shell with compatible Node when the global CLI is missing.
