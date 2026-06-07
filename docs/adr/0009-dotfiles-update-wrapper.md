# ADR: dotfiles-update Global Wrapper

**Date:** 2026-06-07  
**Status:** Accepted — Implemented
**Author:** jesus

---

## Context

`make update` is the technical contract for daily dotfiles maintenance (WSL, APT, npm, MCP images, etc.), but it only runs naturally from inside the repo. Operators need a global command callable from any working directory.

---

## Decision

### 1. Two-layer contract

| Layer | Role |
|-------|------|
| `make update` | Internal SSOT — targets, scripts, tests in `update.mk` |
| `dotfiles-update` | Global user-facing wrapper → delegates to `make update` in `$DOTFILES_DIR` |

### 2. Implementation

| Artifact | Location |
|----------|----------|
| Wrapper script | `bin/dotfiles-update` |
| Chezmoi symlink template | `dot_local/bin/symlink_dotfiles-update.tmpl` → `$HOME/dotfiles/bin/dotfiles-update` |
| Global command | `~/.local/bin/dotfiles-update` (via Chezmoi apply) |
| Tests | `tests/bats/system/dotfiles-update.bats` |

The wrapper:

1. Resolves `DOTFILES_DIR` (default `$HOME/dotfiles`).
2. Validates that the directory and its `Makefile` exist.
3. `cd`s into the repo.
4. Runs `exec make update "$@"`, propagating arguments.

It can be invoked from any working directory. Override the repo path with `DOTFILES_DIR` when needed.

### 3. Scope

This ADR does **not** define new update targets or change `make update` semantics. Maintenance logic remains in `update.mk` and `scripts/update/`.

---

## Consequences

### Positive

- Ergonomic daily maintenance from any directory
- Make remains testable and explicit

### Negative

- Two names to document (`dotfiles-update` vs `make update`)

### Neutral

- Chezmoi apply required for `~/.local/bin/dotfiles-update` visibility on a new machine

---

## References

- Wrapper: `bin/dotfiles-update`
- Chezmoi template: `dot_local/bin/symlink_dotfiles-update.tmpl`
- Docs: `docs/UPDATE.md`, `docs/OPERATIONS.md`
- Tests: `tests/bats/system/dotfiles-update.bats`, `tests/bats/system/update-workflow.bats`
