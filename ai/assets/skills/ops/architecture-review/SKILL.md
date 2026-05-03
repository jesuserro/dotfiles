---
name: architecture-review
description: Use for structured architecture assessment in read-only mode by default; no file edits or refactors unless the user explicitly exits review mode.
---

# Dotfiles Architecture Review

## When to Use

- You need a **read-only** architecture pass: boundaries, risks, consistency with stated constraints
- Before a large refactor or platform migration, to surface gaps and questions
- After `to-spec` or a Grill Report, to sanity-check feasibility **without** changing code

## Guidelines

- **Default mode is read-only**: do not modify source files, configs, or vault content unless the user clearly requests implementation
- Use evidence from the repo: entrypoints, module boundaries, data flows, deployment docs
- Separate **facts** (what the code does) from **opinions** (what should change)
- If you recommend changes, list them as **proposals** with impact and optional follow-up issues; do not apply them in this mode
- For deep codebase navigation patterns, optional use of `gitnexus/` skills is allowed when available

## Checklist

- State explicitly: “This review is read-only.”
- Identify system context, trust boundaries, and failure modes
- Call out coupling, drift from spec, and missing tests or observability
- Suggest where to record outcomes: `projects/<project>/knowledge/reports/architecture-reviews/` (logical path)

## Output

- Structured review: context, findings (severity-ordered), open questions, optional proposed next issues (titles only)
- No patches unless the user exits read-only review

## Examples

- A one-page review referencing key packages and risks, saved as a markdown draft for humans to paste into the vault

## Delegation

- Spec inputs: `ops/to-spec/`, `ops/grill-plan/`
- If the user switches to implementation: `test-driven-change` and project-local skills
