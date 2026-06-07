# ADR: dotfiles-update Global Wrapper (Pointer)

**Date:** 2026-06-07  
**Status:** Accepted  
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

### 2. Implementation status

The wrapper `bin/dotfiles-update` and Chezmoi symlink `dot_local/bin/symlink_dotfiles-update.tmpl` implement this decision. This ADR records the architecture; it does **not** modify wrapper or Makefile in the agent-first BUILD.

### 3. Pointer scope for agent-first BUILD

This ADR does **not**:

- Change `bin/dotfiles-update` or `make update` behavior
- Add new update targets

Further enhancements belong to the dedicated dotfiles-update handoff if needed.

---

## Consequences

### Positive

- Ergonomic daily maintenance from any directory
- Make remains testable and explicit

### Negative

- Two names to document (`dotfiles-update` vs `make update`)

### Neutral

- Chezmoi apply required for `~/.local/bin/dotfiles-update` visibility

---

## References

- Wrapper: `bin/dotfiles-update`
- Chezmoi template: `dot_local/bin/symlink_dotfiles-update.tmpl`
- Docs: `docs/UPDATE.md`, `docs/OPERATIONS.md`
- Tests: `tests/bats/system/dotfiles-update.bats`, `tests/bats/system/update-workflow.bats`
