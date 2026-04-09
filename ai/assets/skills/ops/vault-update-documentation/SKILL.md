---
name: vault-update-documentation
description: Use when an agent should invoke the canonical update-documentation vault prompt through ai-prompt without duplicating its wording.
---

# Vault Update Documentation

## Prompt ID

`update-documentation`

## When to Use

- When code or architecture changes are likely to require documentation updates
- When a change may affect README files, runbooks, ADRs, architecture docs, operational docs, or usage guides
- When the agent needs the canonical vault prompt to review which documentation should be updated after a relevant modification

## Preferred Invocation

- Preferred: `ai-prompt show update-documentation`
- Optional contextual use: `ai-prompt render update-documentation --context-file <file>`
- Optional contextual use: `ai-prompt render update-documentation --stdin`

## Required Context

- A diff, change summary, or implementation context for the change under review
- Relevant files, modules, or documentation paths affected by that change
- The expected documentation goal, scope, or audience when it is known

## Failure Modes

- `ai-prompt` is not available in `PATH`
- The canonical prompt cannot be resolved from the vault
- The change context is too ambiguous or too thin to decide which documentation should be updated
- The documentation task is treated as a full rewrite instead of a targeted update grounded in the actual change

## Canonical Prompt Boundary

Do not duplicate or paraphrase the canonical prompt here. This skill documents how to use `update-documentation`; the canonical wording lives in the vault.
