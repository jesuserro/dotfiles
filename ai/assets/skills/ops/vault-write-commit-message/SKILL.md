---
name: vault-write-commit-message
description: Use when an agent should invoke the canonical write-commit-message vault prompt through ai-prompt without duplicating its wording.
---

# Vault Write Commit Message

## Prompt ID

`write-commit-message`

## When to Use

- When the user needs a commit message grounded in the canonical vault prompt
- When the agent should rely on the established commit-message workflow instead of improvising one
- When Git diff and status context are available in the current repository

## Preferred Invocation

- Preferred: `ai-prompt task write-commit-message`

## Required Context

- A valid Git repository in the current working directory
- Readable diff and status context from that repository

## Failure Modes

- `ai-prompt` is not available in `PATH`
- The current working directory is not a valid Git repository
- The canonical prompt cannot be resolved from the vault

## Canonical Prompt Boundary

Do not duplicate or paraphrase the canonical prompt here. This skill documents how to use `write-commit-message`; the canonical wording lives in the vault.
