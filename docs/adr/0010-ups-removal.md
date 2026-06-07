# ADR: Removal of ups Command (Pointer)

**Date:** 2026-06-07  
**Status:** Accepted  
**Author:** jesus

---

## Context

`ups` was a legacy shell alias/function for combined git pull and system updates. The name was ambiguous (confused with package managers and unrelated tools) and overlapped with the clearer `dotfiles-update` / `make update` contract.

---

## Decision

### 1. Complete removal — no legacy alias

Remove `ups` entirely. Do **not** provide `ups` as an alias or function pointing to `dotfiles-update`. Do **not** document `ups` as an alternative in operational docs.

### 2. Replacement

Daily maintenance: `dotfiles-update` (global) or `make update` (from repo). See ADR 0009.

### 3. Pointer ADR — cleanup in separate handoff

Residual references (changelog, release notes, historical branches) may remain in git history. Operational cleanup and alias removal are part of the **dotfiles-update handoff**, not this agent-first ADR BUILD.

This ADR does **not** modify zsh aliases, scripts, or docs beyond recording the decision.

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
- Related handoff: dotfiles-update / ups removal (separate from agent-first BUILD)
