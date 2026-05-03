---
name: to-issues
description: Use when a vault spec should become one or more vertical GitHub Issues as Markdown to paste manually. Does not run gh or create issues automatically.
---

# Dotfiles To Issues

## When to Use

- A PRD, implementation spec, or contract exists (or enough agreed scope) and work must be **sliced for execution**
- The user wants **agent-ready GitHub Issues** as markdown blocks to paste into the GitHub UI
- You must **not** run `gh issue create` or any API unless the user explicitly orders automation outside this skill

## Guidelines

- One **vertical slice** per issue: completable, testable, with clear boundaries
- Use `templates/github-issue-vertical.md` for each issue body
- Include **placeholders** for vault links: `<spec_path>`, `<project>`, `<repo>`, `<issue_id>` (empty until filed)
- Title line: imperative, scoped (e.g. `Add validation for X in module Y`)
- Each issue should cite **acceptance criteria** and **validation** steps tied to the repo's real test entrypoints (discovered via `test-driven-change` when implementing)

## Checklist

- Map spec sections to issues; avoid mega-issues unless the user insists
- Mark dependencies between issues (e.g. “Blocked by: …”) in plain text
- Preserve **out of scope** to prevent scope creep in implementation chats
- Output raw markdown only; no tool calls to GitHub

## Output

- One markdown block per issue, ready to paste into “New issue”
- Optional index list at the top: issue title + one-line intent

## Examples

- Three pasted issues from one implementation spec, each linking back to the same spec path in the vault

## Delegation

- Spec source: `ops/to-spec/`, Grill context: `ops/grill-plan/`
- Bridge paths: `ops/vault-issue-bridge/`
- After coding: `Vault Project Wiki`, `test-driven-change`
