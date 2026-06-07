# ADR: Removal of ups Command

**Date:** 2026-06-07  
**Status:** Accepted — Closed
**Author:** jesus

---

## Context

`ups` was a legacy shell alias/function for combined git pull and system updates. The name was ambiguous (confused with package managers and unrelated tools) and overlapped with the clearer `dotfiles-update` / `make update` contract.

---

## Decision

### 1. Complete removal — no legacy alias

Remove `ups` entirely. Do **not** provide `ups` as an alias, function, or Make target pointing to `dotfiles-update`. Do **not** document `ups` as an alternative in operational docs.

### 2. Replacement

Daily maintenance: `dotfiles-update` (global) or `make update` (from repo). See ADR 0009.

### 3. Allowed residual mentions

The following references to `ups` are acceptable:

- This ADR and the ADR index
- Historical entries in `CHANGELOG.md` and `releases/`
- Anti-regression tests that assert `ups` is absent from aliases, Make targets, and operational docs

Operational docs may state that `ups` is retired and point to `dotfiles-update`.

---

## Consequences

### Positive

- Single clear entry point for updates
- Less cognitive load for agents and humans

### Negative

- Muscle memory migration from `ups` to `dotfiles-update`

### Neutral

- Historical release markdown under `releases/` may still mention `ups` for audit trail

---

## References

- Replacement ADR: `docs/adr/0009-dotfiles-update-wrapper.md`
- Update docs: `docs/UPDATE.md`
- Regression tests: `tests/bats/system/update-workflow.bats`, `tests/bats/zsh/rc_symlinks.bats`, `tests/bats/docs/documentation-consistency.bats`
