---
name: test-driven-change
description: Use when implementing work tied to an issue or spec; discover the repo's real test and CI workflow before prescribing TDD steps.
---

# Dotfiles Test Driven Change

## When to Use

- You are about to implement a scoped change (often from a GitHub Issue derived via `to-issues`)
- The user wants a **test-first or test-guided** approach **without** assuming a generic red-green-refactor template
- You need to align with **this repository's** Makefile, scripts, and CI

## Guidelines

- **Discover before prescribe**: inspect the project repo in this order (skip missing files only after confirming absence):
  1. `AGENTS.md` (or project agent rules)
  2. `README.md` (or CONTRIBUTING if present)
  3. `Makefile` and included makefiles
  4. `tests/` tree and any `pytest.ini`, `tox.ini`, `package.json` scripts
  5. CI config under `.github/workflows/`, `.gitlab-ci.yml`, or equivalent
- Summarize **actual commands** the implementer should run (e.g. `make test-fast`, `pytest path`, `npm test`) with evidence from files read
- Prefer the **smallest** failing test that proves the issue acceptance criteria before broad refactors
- Do not embed domain-specific examples from external projects in this skill; stay generic

## Checklist

- Document which files were read to justify the chosen test commands
- Map each acceptance criterion from the issue to at least one test or check
- Note flakiness risks or env prerequisites if discovered in CI/README
- After implementation, point to `Vault Project Wiki` or vault reports under `projects/<project>/knowledge/reports/tdd-notes/` for durable lessons (optional)

## Output

- A short **test plan**: commands, order, expected signals (pass/fail/lint)
- Optional: suggested test file locations only when grounded in repo layout you inspected

## Examples

- Issue says “add parser guard”; you open Makefile, find `make test-fast`, propose a unit test path under `tests/` matching existing layout

## Delegation

- Issue markdown: `ops/to-issues/`
- Code intelligence optional: GitNexus skills in `gitnexus/`
- Post-merge knowledge: `Vault Project Wiki`
