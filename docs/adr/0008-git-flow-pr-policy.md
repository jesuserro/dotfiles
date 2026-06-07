# ADR: Git Flow PR Policy (Pointer)

**Date:** 2026-06-07  
**Status:** Accepted  
**Author:** jesus

---

## Context

The dotfiles repo provides `git feat` and `git rel` helpers for feature branches and releases. Some projects need fast local merges; others need PR-based review, checks, and traceability. A single hardcoded flow does not fit all destination repos.

This ADR records an **approved direction** documented in detail in `docs/GIT_FLOW_POLICY.md`. Implementation is handled in a **separate handoff** — not in the agent-first ADR BUILD.

---

## Decision

### 1. Configurable flow per repo (planned)

Evolve `git feat` / `git rel` toward a policy-driven model:

- Preserve local merge for fast iteration where configured
- Optional automatic or guided PR creation for mature projects
- Per-destination behavior for `dev` and `main`
- Integration with project-level `make validate` / `make validate-full` when present

Configuration via `.git-flow-policy.env` per project (see `docs/examples/git-flow-policy.env`).

### 2. Pointer ADR — no implementation here

This ADR does **not**:

- Modify `scripts/git_feat.sh`, `scripts/git_rel.sh`, or related aliases
- Change `git feat` / `git rel` behavior in the current BUILD
- Implement PR automation

Implementation belongs to the dedicated git-flow policy handoff.

---

## Consequences

### Positive

- Decision recorded for agents and future implementers
- Avoids rediscovering rationale in chat

### Negative

- Behavior until implementation remains the existing git helpers only

### Neutral

- Operational detail lives in `docs/GIT_FLOW_POLICY.md` until code catches up

---

## References

- Policy doc: `docs/GIT_FLOW_POLICY.md`
- Example config: `docs/examples/git-flow-policy.env`
- Library: `scripts/lib/git_flow_policy.sh`
- Tests: `tests/bats/git-flow/`
