# ADR: Git Flow PR Policy

**Date:** 2026-06-07  
**Status:** Accepted — Partially implemented
**Author:** jesus

---

## Context

The dotfiles repo provides `git feat` and `git rel` helpers for feature branches and releases. Some projects need fast local merges; others need PR-based review, checks, and traceability. A single hardcoded flow does not fit all destination repos.

This ADR records an **approved direction** documented in detail in `docs/GIT_FLOW_POLICY.md`. Manual PR flows and `--dry-run` are implemented in BUILD B; automatic variants remain pending.

---

## Decision

### 1. Configurable flow per repo

Evolve `git feat` / `git rel` toward a policy-driven model:

- Preserve local merge for fast iteration where configured
- Optional manual PR creation for mature projects (`FLOW_MODE_TO_*=pr`)
- Per-destination behavior for `dev` and `main`
- Integration with project-level `make validate` / `make validate-full` when present
- `--dry-run` for non-mutating inspection

Configuration via `.git-flow-policy.env` per project (see `docs/examples/git-flow-policy.env`).

### 2. Implementation status (BUILD B)

Implemented:

- `FLOW_MODE_TO_DEV=pr` in `git feat`
- `FLOW_MODE_TO_MAIN=pr` in `git rel`
- `git feat --dry-run` and `git rel --dry-run`
- Policy parsing, validation hooks, and bats tests with stub `gh`

Still pending:

- `pr_auto` and `pr_immediate`
- Merge strategy application
- Full ADR closure

---

## Consequences

### Positive

- Decision recorded for agents and future implementers
- Manual PR paths available without breaking local legacy defaults

### Negative

- Behavior for `pr_auto` / `pr_immediate` remains unimplemented

### Neutral

- Operational detail lives in `docs/GIT_FLOW_POLICY.md`

---

## References

- Policy doc: `docs/GIT_FLOW_POLICY.md`
- Example config: `docs/examples/git-flow-policy.env`
- Library: `scripts/lib/git_flow_policy.sh`
- Tests: `tests/bats/git-flow/`
