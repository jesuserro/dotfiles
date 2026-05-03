---
name: agent-workflow
description: Map of the Dotfiles agent workflow family from idea to vault reports, specs, GitHub issue markdown, test-guided implementation, and wiki updates.
---

# Dotfiles Agent Workflow

## When to Use

- Starting or explaining the **end-to-end** method: dotfiles skills as process, vault as knowledge, project repos as execution, GitHub Issues as paste-ready work units
- You need a pointer to the **right sub-skill** without duplicating their content

## Guidelines

- Follow this **canonical flow**:

```text
idea / chat
  -> grill-plan (Grill Report only)
  -> to-spec (PRD | contract | implementation spec | ADR via docs/adr-writer)
  -> to-issues (Markdown for GitHub, manual paste)
  -> test-driven-change (discover Makefile / tests / CI, then implement)
  -> Vault Project Wiki / vault reports (durable notes, optional tdd-notes)
```

- This family lives under **`ops/`** in `ai/assets/skills/ops/`. **Chezmoi** `run_after_11_link_ai_assets` already symlinks category folders to agent surfaces; **no Chezmoi change** is required when adding these skills
- GitHub Issues: **markdown only** in phase 1; do not automate `gh issue create` unless the user explicitly opts in later
- Use `vault-issue-bridge` for path conventions and `AI_PROMPTS_VAULT_ROOT`

## Checklist

- Name the `<project>` and `<repo>` before deep work
- Ensure a Grill Report exists before locking a spec (unless the user waives grilling)
- After implementation, decide if knowledge belongs in `reports/` or wiki/decisions per `Vault Project Wiki`

## Output

- A short routing table in chat pointing to the next skill and artifact type

## Future: /grill command (not implemented)

- A future global **`/grill`** command (OpenCode/Cursor/Codex style) could be an **ergonomic alias** to invoke `grill-plan` and scaffold a Grill Report from a template
- **Not registered** in `ai/assets/commands/registry.yaml` yet: validate the manual flow first, then add a command entry + `COMMAND.md` in a later change if still valuable

## Examples

- “We are post-Grill; switch to `to-spec` with template `prd-outline.md`.”

## Delegation

- Sub-skills: `grill-plan`, `to-spec`, `to-issues`, `test-driven-change`, `architecture-review`, `vault-issue-bridge`
- Vault prompts: `Vault AI Prompt Consumer` and related vault-* skills as needed
- Agent-oriented orchestration guide: [AGENT_WORKFLOW_FOR_AGENTS.md](../../../../AGENT_WORKFLOW_FOR_AGENTS.md) (skill matrix, project and vault delegation, GitHub/CLI policy)
