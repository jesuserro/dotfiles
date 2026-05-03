---
name: grill-plan
description: Use when an idea or plan needs structured challenge before any PRD or spec. Produces a Grill Report via interview and design branches, not a PRD.
---

# Dotfiles Grill Plan

## When to Use

- You have a rough idea, feature request, or partial plan and need **decisions resolved** before writing a spec
- The user wants adversarial questioning, tradeoff exploration, or hidden-assumption surfacing
- You must **not** skip straight to a PRD or implementation spec; the next step after this skill is `to-spec` using a completed Grill Report

## Guidelines

- Run an **interview loop**: ask clarifying questions, propose alternatives, and record resolved vs open decisions
- Explore **design branches** (options considered, rejected paths, constraints) without committing to final prose for PRD
- **Output is only a Grill Report** (see template under `templates/grill-report.md`). Do not produce a PRD, ADR body, or contract here
- Anchor assumptions in observable context: link to repo docs or vault notes when the user provides them; otherwise label gaps explicitly
- If the user already has a frozen spec, use `to-spec` or `architecture-review` instead of re-grilling unless they explicitly want to invalidate the spec

## Checklist

- Confirm goal, non-goals, and success signals with the user
- List open questions; iterate until each is resolved, deferred with owner, or marked unknown-with-risk
- Capture tradeoffs and rejected options with one-line rationale each
- Name the target `<project>` and where the Grill Report will live under `projects/<project>/knowledge/reports/grill/`
- Save or draft the Grill Report before calling `to-spec`

## Output

- A **Grill Report** document following `templates/grill-report.md`
- Suggested filename pattern: `grill-report-<topic-slug>.md` under the vault reports path (logical path only; resolve vault root via `AI_PROMPTS_VAULT_ROOT` as documented in `Vault AI Prompt Consumer` / `vault-issue-bridge`)

## Examples

- After a brainstorming chat, produce a Grill Report then hand off to `Dotfiles To Spec` with the report as primary input

## Delegation

- Next step in the workflow: `ops/to-spec/` after the Grill Report is accepted
- For vault placement conventions: `ops/vault-issue-bridge/` and `Vault Project Wiki`
