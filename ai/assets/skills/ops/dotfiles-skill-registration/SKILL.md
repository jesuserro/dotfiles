---
name: dotfiles-skill-registration
description: Use when a human or agent needs to add a new skill to the dotfiles skill system and must decide family, placement, naming, and minimal validation.
---

# Dotfiles Skill Registration

## Purpose

Provide a short operational guide for adding a new skill to the dotfiles skill system with the right family, placement, naming, and minimal validation.

## When to Use

- When a vault prompt needs discoverability as a `Vault ...` skill
- When a new transversal operational need appears directly in `dotfiles`
- When a human or agent must decide whether something should be a skill, a prompt, or a command
- When a new capability should be registered cleanly without opening a larger architecture phase

## Decision Rules

- Do not create a new skill if an existing prompt, skill, or command already covers the need
- If the vault prompt alone is enough, keep it as a prompt and do not add a skill
- If the need is wrapper guidance or discoverability, consider a skill
- Do not convert every prompt into a skill by default
- Do not mix the role of a skill with a command or with the canonical prompt itself

## Naming and Family Selection

- Use `Vault ...` for skills derived from the canonical vault prompt system
- Use `Dotfiles ...` for transversal skills maintained in this repo and not clearly vault-derived
- Keep the original brand for third-party skills such as `GitNexus ...`
- Reserve project families such as `Store ETL ...` for the corresponding project repo, not this one

## Minimal Registration Workflow

1. Identify the origin and the real need.
2. Decide whether a new skill is justified.
3. Choose the visible family and name.
4. Create the folder under `ai/assets/skills/<category>/<skill-name>/`.
5. Add `SKILL.md` with frontmatter, title, and the minimum useful sections.
6. Update the skill indexes only where needed.
7. Validate structure and confirm the published surfaces if necessary.

## Validation

- Run `./scripts/validate-skills-structure.sh`
- Check the published surfaces if discoverability matters right away
- If the UI still does not reflect the change, run `chezmoi apply` or refresh the linked surfaces
- Avoid broad audits unless the change is part of a larger registration phase

## Failure Modes

- Creating a skill that is not justified by the actual need
- Duplicating a canonical prompt inside the skill instead of wrapping it
- Choosing the wrong family (`Vault`, `Dotfiles`, third-party, or project)
- Touching too many files or too much documentation for a small skill
- Assuming the new canon will appear in the UI immediately without refresh or republish
