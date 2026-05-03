---
name: vault-issue-bridge
description: Use to connect vault logical paths for reports, specs, and issue drafts with placeholders. No absolute machine paths in outputs.
---

# Dotfiles Vault Issue Bridge

## When to Use

- You need a **single mental model** for where Grill Reports, specs, issue drafts, architecture reviews, and TDD notes live relative to the vault root
- You are handoffs between `grill-plan`, `to-spec`, `to-issues`, and wiki updates
- You must avoid hardcoding personal filesystem paths in artifacts

## Guidelines

- Resolve the vault root only via documented environment variables: prefer **`AI_PROMPTS_VAULT_ROOT`** (see `docs/AI_PROMPTS_SYSTEM.md` and `Vault AI Prompt Consumer`). Do not bake alternate absolute roots into dotfiles skills
- Use **logical paths** only in templates and examples:

```text
<vault_root>/projects/<project>/knowledge/reports/grill/
<vault_root>/projects/<project>/knowledge/reports/specs/
<vault_root>/projects/<project>/knowledge/reports/issues/
<vault_root>/projects/<project>/knowledge/reports/architecture-reviews/
<vault_root>/projects/<project>/knowledge/reports/tdd-notes/
<vault_root>/projects/<project>/knowledge/decisions/
<vault_root>/projects/<project>/knowledge/wiki/
```

- Treat `projects/_template/knowledge/...` as a **copy pattern** for new projects; real projects mirror that structure under `projects/<project>/knowledge/`
- GitHub Issues remain **execution surface**: link from issue body to vault spec path using the logical `projects/...` form
- Existing wiki types under `implementation-notes/`, `patterns/`, etc. remain valid per `Vault Project Wiki`; `reports/` is an **additional** workspace for workflow artifacts

## Checklist

- Replace `<vault_root>` mentally with the resolved env var when writing files locally; in shared markdown for GitHub, omit host paths—use repo-relative or vault-relative logical links as agreed by the team
- Confirm `<project>` slug matches `vault_trabajo/projects/<project>/`
- Keep Grill → spec → issues ordering explicit in handoff notes

## Output

- Path snippets and naming conventions for the current task, no `gh` commands

## Examples

- “Save Grill Report to `projects/my-service/knowledge/reports/grill/grill-report-auth.md`”

## Delegation

- Wiki capture: `Vault Project Wiki`
- Prompts: `Vault AI Prompt Consumer`
- Full flow map: `ops/agent-workflow/`
