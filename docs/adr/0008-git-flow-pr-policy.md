# ADR: Git Flow PR Policy

**Date:** 2026-06-07  
**Status:** Accepted — Implemented
**Author:** jesus

---

## Context

The dotfiles repo provides `git feat` and `git rel` helpers for feature branches and releases. Some projects need fast local merges; others need PR-based review, checks, and traceability. A single hardcoded flow does not fit all destination repos.

This ADR records the approved direction documented in detail in `docs/GIT_FLOW_POLICY.md`. All configurable PR modes and merge strategies are implemented.

---

## Decision

### 1. Configurable flow per repo

Evolve `git feat` / `git rel` toward a policy-driven model:

- Preserve local merge for fast iteration where configured
- Optional PR creation for mature projects (`FLOW_MODE_TO_*=pr|pr_auto|pr_immediate`)
- Per-destination behavior for `dev` and `main`
- Merge strategy via `MERGE_STRATEGY_TO_DEV` and `MERGE_STRATEGY_TO_MAIN`
- Integration with project-level `make validate` / `make validate-full` when present
- `--dry-run` for non-mutating inspection

Configuration via `.git-flow-policy.env` per project (see `docs/examples/git-flow-policy.env`).

### 2. PR mode semantics

| Mode | Behavior |
| --- | --- |
| `pr` | Create PR, leave open for manual review |
| `pr_auto` | Create PR, enable auto-merge with configured strategy |
| `pr_immediate` | Create PR, merge immediately with configured strategy |

Merge strategy maps to `gh pr merge` flags: `merge` → `--merge`, `squash` → `--squash`, `rebase` → `--rebase`. Strategy applies only in `pr_auto` and `pr_immediate`.

### 3. Implementation status

Implemented:

- `FLOW_MODE_TO_DEV=pr|pr_auto|pr_immediate` in `git feat`
- `FLOW_MODE_TO_MAIN=pr|pr_auto|pr_immediate` in `git rel`
- `MERGE_STRATEGY_TO_DEV` and `MERGE_STRATEGY_TO_MAIN`
- `git feat --dry-run` and `git rel --dry-run`
- Policy parsing, validation hooks, and bats tests with stub `gh`

---

## Consequences

### Positive

- Each project can choose local or PR-based integration per destination branch
- Manual, auto-merge, and immediate-merge variants share one policy model
- Legacy local defaults preserved when no policy file exists

### Negative

- `pr_immediate` fails when GitHub branch protection or checks block merge; no polling or retry loop is implemented

### Neutral

- Operational detail lives in `docs/GIT_FLOW_POLICY.md`
- Tests stub `gh`; production requires authenticated GitHub CLI

---

## References

- Policy doc: `docs/GIT_FLOW_POLICY.md`
- Example config: `docs/examples/git-flow-policy.env`
- Library: `scripts/lib/git_flow_policy.sh`
- Tests: `tests/bats/git-flow/`
- Dotfiles activation: `.git-flow-policy.env` (manual PR, `make agent-validate`)
