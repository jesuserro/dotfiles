---
name: vault-review-diff
description: Use when an agent should invoke the canonical review-diff vault prompt through ai-prompt without duplicating its wording.
---

# Vault Review Diff

## Prompt ID

`review-diff`

## When to Use

- When the user needs a structured review prompt for a Git diff
- When `ai-prompt` should provide the canonical review wording instead of ad hoc instructions
- When the current repo state is available and the agent needs the vault-backed review flow

## Preferred Invocation

- Preferred: `ai-prompt task review-diff`
- Alternative: `ai-prompt render review-diff --git-diff --git-status`

## Required Context

- A valid Git repository in the current working directory
- Readable diff and status context from that repository

## Failure Modes

- `ai-prompt` is not available in `PATH`
- The current working directory is not a valid Git repository
- The canonical prompt cannot be resolved from the vault

## Canonical Prompt Boundary

Do not duplicate or paraphrase the canonical prompt here. This skill documents how to use `review-diff`; the canonical wording lives in the vault.
