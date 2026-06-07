# ADR: GitNexus Post-Commit Best-Effort Policy

**Date:** 2026-06-07  
**Status:** Accepted  
**Author:** jesus

---

## Context

GitNexus indexes the dotfiles repo for agent tooling. Refreshing the index after commits keeps MCP queries useful, but GitNexus depends on environment factors (writable home paths, running processes, network for some operations). Blocking commits on GitNexus failures would interrupt normal git workflow.

---

## Decision

### 1. Post-commit refresh is best-effort

`scripts/hooks/post-commit-gitnexus.sh` runs synchronously after commit with `--force --skip-agents-md`. Failures due to non-writable registry, permissions, or environment skips must **not** fail the commit.

### 2. Clear operator feedback

The hook logs skip reasons (read-only registry, missing commands) so humans can act. Agents must not auto-trigger full re-index on STALE warnings; see operational policy.

### 3. Agents read-only by default

Agents use GitNexus MCP tools and `make gitnexus-status` read-only. Index refresh (`gnx-analyze-here`) is a **human** action unless explicitly requested.

---

## Consequences

### Positive

- Commits remain unblocked by GitNexus environment issues
- Index stays reasonably fresh on healthy machines

### Negative

- Index may be stale until human refresh
- Skip conditions require operator awareness

### Neutral

- Detailed rules in `docs/GITNEXUS_OPERATIONAL_POLICY.md` supersede hook comments for agent behavior

---

## References

- Operational policy: `docs/GITNEXUS_OPERATIONAL_POLICY.md`
- Hook: `scripts/hooks/post-commit-gitnexus.sh`
- Tests: `tests/bats/git-hooks/hooks.bats`
- GitNexus ADR: `docs/adr/0002-gitnexus-mcp.md`
