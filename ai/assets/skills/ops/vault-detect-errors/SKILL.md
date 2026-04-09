---
name: vault-detect-errors
description: Use when an agent should invoke the canonical detect-errors vault prompt through ai-prompt without duplicating its wording.
---

# Vault Detect Errors

## Prompt ID

`detect-errors`

## When to Use

- When the user needs the canonical vault prompt for diagnosing failures or suspicious output
- When a reusable error-analysis prompt is preferable to handwritten guidance
- When extra context may need to be attached to the prompt at runtime

## Preferred Invocation

- Preferred: `ai-prompt show detect-errors`
- Optional contextual use: `ai-prompt render detect-errors --stdin`

## Required Context

- Enough diagnostic context for the case at hand
- Optional stdin, file content, or other explicit context when the base prompt alone is not sufficient

## Failure Modes

- `ai-prompt` is not available in `PATH`
- The canonical prompt cannot be resolved from the vault
- The prompt is invoked without enough surrounding context to analyze the error meaningfully

## Canonical Prompt Boundary

Do not duplicate or paraphrase the canonical prompt here. This skill documents how to use `detect-errors`; the canonical wording lives in the vault.
