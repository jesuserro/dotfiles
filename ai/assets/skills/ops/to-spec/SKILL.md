---
name: to-spec
description: Use when resolved context (e.g. a Grill Report) should become a PRD, contract, implementation spec, or pointer to an ADR. Does not replace the ADR writer skill for ADR prose.
---

# Dotfiles To Spec

## When to Use

- A Grill Report or equivalent decision record exists and you need a **formal spec artifact** in the vault
- You must produce a **PRD**, **data/API contract outline**, or **implementation specification** as markdown
- The outcome should be an **ADR**: do not duplicate the full ADR template here; follow `Dotfiles ADR Writer` in `docs/adr-writer/`

## Guidelines

- **Read the Grill Report or agreed context first**; do not invent decisions the user did not approve
- Pick one primary artifact type per pass (PRD vs contract vs implementation spec). Split into multiple files if scope is large
- Use the templates in `templates/` for PRD, contract, and implementation spec outlines
- For **ADR**: open `ai/assets/skills/docs/adr-writer/SKILL.md`, apply its structure and quality bar, and store under `projects/<project>/knowledge/decisions/` per vault conventions
- Store outputs under logical paths such as `projects/<project>/knowledge/reports/specs/` (resolve vault root with `AI_PROMPTS_VAULT_ROOT`; see `vault-issue-bridge`)
- Keep specs **project-agnostic in wording** when working from dotfiles: use placeholders `<project>`, `<repo>`, not hardcoded third-party schema names unless the user supplied them

## Checklist

- Confirm spec type and audience (implementers, reviewers, stakeholders)
- Cross-check against Grill Report decisions; flag any drift
- Include acceptance criteria and out-of-scope where applicable
- Link forward to GitHub issue drafting (`to-issues`) with placeholders for `<issue_id>` when not yet created

## Output

- One or more markdown files in the vault following the chosen template or ADR skill
- Short summary block at the top: purpose, spec type, file path (logical)

## Examples

- Turn a ready Grill Report into `prd-outline.md` structure, save as `specs/feature-x-prd.md` under the project knowledge reports tree

## Delegation

- ADR structure and tone: `docs/adr-writer/`
- Placement and wiki lifecycle: `Vault Project Wiki`, `vault-issue-bridge`
- Next workflow step: `ops/to-issues/` for vertical issue markdown
