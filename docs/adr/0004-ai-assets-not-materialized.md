# ADR: AI Assets Not Materialized Inside the Dotfiles Checkout

**Date:** 2026-06-07  
**Status:** Accepted  
**Author:** jesus

---

## Context

AI assets (skills, prompts, rules) are versioned under `ai/assets/` and published to agent surfaces in HOME via Chezmoi. Materializing runtime paths such as `.claude/skills/` inside the dotfiles checkout blurs the boundary between source and deployed surfaces, causes validator false positives, and invites drift.

A checkout-local `.claude/skills/` tree (for example under `gitnexus/`) violates the canonical model even when content mirrors `ai/assets/skills/`.

---

## Decision

### 1. Canonical source only in checkout

All repo-managed AI knowledge assets live under `ai/assets/` (primarily `ai/assets/skills/`). Agent surfaces (`.claude/skills/`, `.cursor/skills-cursor/`, `~/.config/ai/skills/`, etc.) are **HOME paths**, symlinked by Chezmoi — not directories inside the dotfiles git tree.

### 2. No runtime materialization in checkout

The hook `run_after_11_link_ai_assets` must refuse to create agent skill directories inside the Chezmoi source checkout. Validators (`validate-skills-structure.sh`, `canonical-skills.bats`) fail if `.claude/skills/` exists in the repo.

### 3. Explicit exceptions only

Any exception to this rule requires an explicit ADR amendment and a dedicated regression test.

---

## Consequences

### Positive

- Clear separation: `ai/assets/` = source, HOME = surfaces
- Validators and agents share one contract
- Reduced accidental commits of materialized runtime files

### Negative

- Developers must not copy skills into `.claude/skills/` for local experiments inside the repo
- Stale checkout-local trees must be removed manually when they appear (`rm -rf .claude/` from the dotfiles checkout; canonical source remains `ai/assets/skills/`)

### Neutral

- Chezmoi still symlinks into `~/.claude/skills/` on apply; only the **checkout** path is forbidden

---

## References

- Skills ADR: `docs/adr/0003-skills-architecture.md`
- Canonical skills tests: `tests/bats/skills/canonical-skills.bats`
- Link hook: `.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl`
- Agent contract: `docs/AGENT_WORKFLOW.md` § Skills y MCPs
- Skills source: `ai/assets/skills/`
