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

Read-only: index freshness (`FRESH`/`STALE`/`NO_INDEX`), lock file, Node runtime, artifacts. See `docs/GITNEXUS_OPERATIONAL_POLICY.md`.

## Commands

### Runtime precheck

On dotfiles/WSL, run the read-only precheck before any human-initiated re-index:

```bash
make update-check
```

If it warns that the effective Node runtime comes from Cursor/VS Code and is below the repo policy (`>=22`), but reports a managed compatible runtime, a **human** may use:

```bash
gnx-analyze-here
```

This loads the shared Node runtime policy, respects `DOTFILES_MANAGED_NODE_BIN`, and avoids raw analyze CLI or npx invocations under an IDE-injected Node 20 process. If no managed compatible runtime is available, reconcile Node with `make install-node-stack` before re-indexing.

### analyze — Build or refresh the index (human only)

```bash
gnx-analyze-here
```

**Agents must not run this without explicit user approval.** Run from the project root. Parses source files, builds the knowledge graph, writes `.gitnexus/`, and may regenerate `CLAUDE.md` / `AGENTS.md` context blocks.

| Flag           | Effect                                                           |
| -------------- | ---------------------------------------------------------------- |
| `--force`      | Force full re-index even if up to date                           |
| `--embeddings` | Enable embedding generation for semantic search (off by default) |

**When a human runs it:** First time in a project, after major code changes, or when MCP / `make gitnexus-status` reports STALE — only after closing live GitNexus MCP processes.

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
- **Analyze is slow or appears stuck under Cursor**: Run `make update-check`; if Node is shadowed by Cursor v20, human re-runs with `gnx-analyze-here`
- **Index is stale after re-analyzing**: Restart the IDE to reload the MCP server
- **Lock on `.gitnexus/lbug`**: Run `make gitnexus-status`; wait for MCP processes; never delete `lbug` automatically
- **Embeddings slow**: Omit `--embeddings` (it's off by default) or set `OPENAI_API_KEY` for faster API-based embedding

## npx fallback (exceptional manual use only)

`npx` with the gitnexus package is **not** the default path for agents or IDE shells (may pull packages over network and use IDE Node). Use only from a normal shell with compatible Node when the global CLI is missing.
