# ADR: Playwright Docker via Chezmoi Bin Symlink

**Date:** 2026-06-07  
**Status:** Accepted  
**Author:** jesus

---

## Context

Playwright browser automation for agents runs in Docker. Earlier approaches used Chezmoi `run_after` scripts to expose the wrapper, which was harder to discover, test, and reuse from external projects.

---

## Decision

### 1. Chezmoi-managed bin symlink

`bin/playwright-docker` is the canonical wrapper script in the repo. Chezmoi materializes it to `~/.local/bin/playwright-docker` via `dot_local/bin/symlink_playwright-docker.tmpl`.

### 2. No run_after for Playwright

Playwright access must not depend on a legacy `run_after_*` hook. The bin symlink pattern matches `dotfiles-update` and other global utilities.

### 3. Stable CLI contract

The wrapper accepts standard Docker mount/env overrides documented in ops skills and tests. External projects invoke `playwright-docker` from PATH after Chezmoi apply.

---

## Consequences

### Positive

- Visible, testable command in `~/.local/bin`
- Consistent Chezmoi pattern with other bin wrappers
- Easier use from non-dotfiles project directories

### Negative

- Requires Chezmoi apply (or bootstrap) for PATH visibility

### Neutral

- Docker image updates remain part of `make update` / maintenance workflow

---

## References

- Chezmoi template: `dot_local/bin/symlink_playwright-docker.tmpl`
- Wrapper: `bin/playwright-docker`
- Docs: `docs/CHEZMOI.md`, `docs/OPERATIONS.md`
- Tests: `tests/bats/system/playwright-docker.bats`, `tests/bats/chezmoi/smoke.bats`
