---
name: vault-development-acceleration
description: Use when an agent should invoke the canonical development-acceleration vault prompt through ai-prompt without duplicating its wording.
---

# Vault Development Acceleration

## Prompt ID

`development-acceleration`

## When to Use

- When the user wants to identify realistic ways to accelerate development without lowering engineering standards
- When the current workflow has friction and the agent should look for useful next steps, tooling, or automation opportunities
- When the agent should prioritize actions that can unlock more progress with low or medium risk

## Preferred Invocation

- Preferred: `ai-prompt show development-acceleration`
- Optional contextual use: `ai-prompt render development-acceleration --context-file <file>`
- Optional contextual use: `ai-prompt render development-acceleration --stdin`

## Required Context

- The current state of the project, module, or workflow under review
- Current frictions, bottlenecks, or repetitive manual work
- Immediate goals, time constraints, or technical constraints
- Tools, skills, and infrastructure that are already available

## Failure Modes

- `ai-prompt` is not available in `PATH`
- The canonical prompt cannot be resolved from the vault
- The context is too thin to identify concrete and grounded acceleration paths
- Acceleration is confused with rushing, avoidable technical debt, or proposals that are too broad to act on

## Canonical Prompt Boundary

Do not duplicate or paraphrase the canonical prompt here. This skill documents how to use `development-acceleration`; the canonical wording lives in the vault.
