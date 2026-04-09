---
name: vault-suggest-improvements
description: Use when an agent should invoke the canonical suggest-improvements vault prompt through ai-prompt without duplicating its wording.
---

# Vault Suggest Improvements

## Prompt ID

`suggest-improvements`

## When to Use

- When the code already works but may benefit from prudent technical or design improvements
- When the user wants to review maintainability, clarity, cohesion, or simplification before refactoring
- When the agent should propose concrete improvements with professional judgment instead of rewriting everything

## Preferred Invocation

- Preferred: `ai-prompt show suggest-improvements`
- Optional contextual use: `ai-prompt render suggest-improvements --context-file <file>`
- Optional contextual use: `ai-prompt render suggest-improvements --stdin`

## Required Context

- The module, component, or area under review
- Relevant files or code paths to inspect
- Constraints, limits, or non-goals for the proposed changes
- The desired level of change aggressiveness and any explicit improvement goal when it is known

## Failure Modes

- `ai-prompt` is not available in `PATH`
- The canonical prompt cannot be resolved from the vault
- The context is too vague to produce grounded, useful suggestions
- The review is treated as a broad rewrite instead of a prudent improvement pass

## Canonical Prompt Boundary

Do not duplicate or paraphrase the canonical prompt here. This skill documents how to use `suggest-improvements`; the canonical wording lives in the vault.
