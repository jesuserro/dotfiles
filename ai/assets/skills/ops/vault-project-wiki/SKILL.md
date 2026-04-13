---
name: vault-project-wiki
description: Use when an agent needs to decide whether a completed implementation deserves a distilled knowledge note in vault_trabajo and how to place it canonically by project and note type.
---

# Vault Project Wiki

Operational guide for agents who need to capture durable project knowledge in `vault_trabajo` after a relevant implementation.

## When to Use

- When an implementation, refactor, migration, incident, or design choice leaves reusable knowledge behind
- When the agent needs to decide whether a change deserves a project wiki note instead of only repo documentation
- When the user asks how to register the outcome of important work in the vault without duplicating the repository

## Decision Rules

- Capture knowledge only when the change leaves reusable context for future work
- Prefer the project repo when the content is implementation source of truth, setup detail, API detail, or code-adjacent instructions
- Prefer `vault_trabajo` when the value is distilled operational knowledge that should survive multiple future changes
- Do not create a wiki note for every small edit, typo fix, dependency bump, or purely local cleanup
- Update an existing note when the topic already exists and the new change extends it cleanly

## Separation of Roles

- Project repo: source of truth for code, architecture, scripts, and canonical implementation docs
- `vault_trabajo`: cumulative project wiki with distilled notes that help future agents and humans
- `dotfiles`: transversal operational layer that teaches agents when and how to capture that knowledge

## Canonical Vault Placement

Base path:

```text
vault_trabajo/projects/<project>/knowledge/
```

Choose one subfolder:

- `implementation-notes/` for relevant implementation details, rollout logic, migration behavior, or integration constraints
- `decisions/` for explicit decisions, tradeoffs, or rejected alternatives that matter later
- `patterns/` for reusable ways of solving recurring problems
- `incidents/` for failures, debugging outcomes, mitigations, and lessons learned

## Note Types and Status

Allowed `type` values:

- `implementation-note`
- `decision-note`
- `pattern-note`
- `incident-note`

Allowed `status` values:

- `draft`
- `stable`
- `superseded`

## Minimum Frontmatter

```yaml
---
project: store-etl
type: implementation-note
status: stable
date: 2026-04-13
topics:
  - camino-a
  - hydration
source_of_truth:
  - repo-docs
---
```

Keep the temporal dimension in frontmatter. Do not move technical wiki content into `timeline/`.

## Writing Guidelines

- Write a short note that explains what changed, why it matters, and how to reuse the learning
- Link back to the project repo, repo docs, PR, ADR, or issue when those are the source of truth
- Distill the knowledge; do not paste large diffs, file trees, or full code listings
- Prefer stable language over commit-by-commit narration
- If the note is superseded, update `status` and point to the newer note

## Minimal Workflow

1. Finish the implementation or review the relevant change.
2. Ask whether the outcome leaves durable knowledge for future work.
3. Identify the target project under `vault_trabajo/projects/<project>/knowledge/`.
4. Choose the right folder and `type`.
5. Reuse the minimum frontmatter and set a meaningful `topics` list.
6. Write or update a brief distilled note with links to the repo source of truth.
7. Avoid duplicating repository documentation that already explains the implementation canonically.

## What Not to Capture

- Raw change logs or release notes
- Full implementation walkthroughs already covered in the repo
- Temporary debugging scraps with no reusable lesson
- Mechanical edits with no future operational value

## Example

Example path:

```text
vault_trabajo/projects/store-etl/knowledge/implementation-notes/camino-a-hydration-gate-by-batch.md
```

Use `Vault Update Documentation` if you first need help deciding whether the repo itself also needs documentation updates. The vault wiki note is complementary, not a replacement for repo docs.
