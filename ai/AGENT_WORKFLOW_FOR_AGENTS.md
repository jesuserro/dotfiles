# Agent Workflow Loop — guide for AI agents

## 1. Purpose

This document is for **AI agents** working in environments where:

- **Dotfiles** supplies global skills and conventions (especially under `ai/assets/skills/ops/`).
- The **active project repository** holds code, tests, local CLIs, and often project-specific skills or `AGENTS.md`.
- **vault_trabajo** stores durable artifacts per project (specs, reports, wiki-style notes).
- **GitHub Issues** are used for operational tracking, not as the canonical knowledge store.

Use it together with the human tutorial [Agent Workflow Loop](../docs/AGENT_WORKFLOW_LOOP.md) and the skill [Dotfiles Agent Workflow](assets/skills/ops/agent-workflow/SKILL.md).

## 2. Operating model

| Layer | What it is | Agent behavior |
|-------|------------|----------------|
| **Dotfiles** | Global skills, method, shared templates, naming rules | Apply transversal skills; **do not** embed project-specific internals here. |
| **Active project repo** | Source code, tests, `Makefile`, `AGENTS.md`, CI, local scripts, optional `ai/assets/skills/` | **Inspect first** when implementing, testing, or following project issue/CLI conventions. |
| **vault_trabajo** | Real per-project memory and workflow artifacts | Resolve root with **`AI_PROMPTS_VAULT_ROOT`**; use **logical paths** only (see section 5). |
| **GitHub Issues** | Execution tracking | Prefer **Markdown** produced by global skills; paste manually unless the user and **project** explicitly allow automation. |

Canonical knowledge for “how we build” lives in the **project repo** and **vault**; dotfiles teaches **how to move through the loop**.

## 3. Skill selection matrix

| User intent (examples) | Primary global skill |
|------------------------|----------------------|
| Challenge an idea, surface decisions, **no PRD yet** | `grill-plan` |
| Produce PRD, contract, implementation spec (or ADR via adr-writer) | `to-spec` |
| Produce **GitHub issue body** as Markdown (paste-ready) | `to-issues` |
| Implement with tests; **discover** local test workflow first | `test-driven-change` |
| Architecture pass **read-only by default** | `architecture-review` |
| Where to store grill/spec/issue drafts in the vault | `vault-issue-bridge` |
| Explain or route the **full loop** | `agent-workflow` |

If several apply, follow the pipeline order in section 7 unless the user narrows scope.

External fallback skills, such as the opt-in Matt Pocock full catalog documented
under `ai/assets/external-skills/`, are used only when no local dotfiles skill
covers the task. If a local skill overlaps with an external one, the local
skill wins. `make update` does not install or update external skills.

### Dotfiles operations (this repo)

When the task is **installing**, **updating**, or **troubleshooting** this dotfiles repository (Chezmoi, SOPS, `make update`, MCPs in HOME), use these global skills — not project-local skills:

| Intent | Skill |
|--------|-------|
| Day-to-day: `git pull`, `chezmoi apply`, secrets, `source` vs `apply`, MCP readiness | `dotfiles-operations` |
| New machine bootstrap: `make install*` | `dotfiles-install` |
| MCP manifest, templates, governance chain | `mcp-governance` |
| Extend or debug `make update` (Windows/WSL, APT, npm, MCPs) | `system-updates` |
| Operate Excalidraw MCP Docker | `excalidraw-mcp-operations` |
| Edit/create Excalidraw diagrams | `diagrams/excalidraw` |
| Publish diagrams to SVG/PNG/PDF docs | `docs/excalidraw-publishing` |

Human SSOT: [docs/OPERATIONS.md](../docs/OPERATIONS.md). **Do not** recommend `rcup`/RCM (legacy).

## 4. Project-specific delegation

- **Always inspect the active repository** when work touches implementation, tests, issue workflow, or project-local CLIs.
- Read what exists, in order of relevance: `AGENTS.md`, `README.md`, `docs/`, `Makefile`, `scripts/`, `.github/workflows/`, and **`ai/assets/skills/`** inside the project if present.
- If the project defines a **local** skill or script for GitHub issues, use it **only after** global `to-issues` has produced **reviewed** Markdown (unless the user skips drafting).
- **Do not** invent `gh issue create` automation from dotfiles global skills.
- **Do not** assume conventions from any specific external project (e.g. naming patterns, pipelines, or internal CLIs) inside dotfiles global content.

## 5. Vault delegation

- Resolve vault root with **`AI_PROMPTS_VAULT_ROOT`** (see [AI_PROMPTS_SYSTEM.md](../docs/AI_PROMPTS_SYSTEM.md)).
- Use logical artifact paths under the vault (after the resolved root):

```text
projects/<project>/knowledge/reports/grill/
projects/<project>/knowledge/reports/specs/
projects/<project>/knowledge/reports/issues/
projects/<project>/knowledge/reports/architecture-reviews/
projects/<project>/knowledge/reports/tdd-notes/
```

- If the project or user points to a **project-specific vault skill** or doc for naming and wiki placement, **defer** to it for that project’s conventions.
- Do **not** hardcode personal absolute filesystem paths in outputs meant to be shared across machines.

## 6. GitHub Issues and CLI policy

- **Global** Agent Workflow skills output **Markdown** for issues. They **do not** call `gh` or GitHub APIs by default.
- **Project-specific** skills, scripts, or CLIs may define `gh` or API flows; use them only when the **user explicitly** asks and the project supports it.
- A future global **`/grill`** command may alias `grill-plan`; it is **not** in `registry.yaml` yet.
- A future **generic `agent-flow` CLI** should be considered **only after** repeated successful **manual** orchestration of this skill chain.

## 7. Recommended agent sequence

1. Run **`grill-plan`**; produce a Grill Report (not a PRD).
2. Propose or save path using **`vault-issue-bridge`** conventions under `reports/grill/`.
3. Run **`to-spec`**; store under `reports/specs/` (or ADR under `decisions/` per adr-writer).
4. Run **`to-issues`**; emit vertical issue Markdown.
5. If the project has its own issue CLI or skill, follow **user + project** instructions after Markdown is reviewed.
6. Run **`test-driven-change`** after reading repo context (`AGENTS.md`, `Makefile`, tests, CI).
7. Update vault/wiki using **`Vault Project Wiki`**, **`Vault Update Documentation`**, or related vault skills as appropriate.

Insert **`architecture-review`** when the user wants a read-only architecture pass (before or after spec, as requested).

## 8. Safety rules

- Do not hardcode personal absolute vault paths in dotfiles-owned documentation or global skills.
- Do not create GitHub issues automatically unless the **user explicitly** requests it **and** the **project** workflow supports it.
- Do not modify Chezmoi templates, `registry.yaml`, global commands, or new CLIs unless the user requests that work explicitly.
- Do not mix **project-specific** business or schema details into **global** dotfiles skills.
- Prefer **Markdown artifacts** (Grill Report, spec, issue bodies) before automation.

## 9. Example handoff (generic)

**User goal:** Add an isolated fixture environment for integration tests.

1. Agent applies **`grill-plan`** → Grill Report with decisions and risks.
2. Agent records path under `projects/<project>/knowledge/reports/grill/` (logical).
3. Agent applies **`to-spec`** → implementation spec under `reports/specs/`.
4. Agent applies **`to-issues`** → one vertical issue Markdown block with acceptance criteria.
5. Agent checks project repo for any **issue creation** script or convention; does not auto-run `gh` unless instructed.
6. Agent applies **`test-driven-change`** after discovering real test commands from the repo.
7. Agent updates vault/wiki with a short note if knowledge is durable.

No domain-specific internals in global skills—only this structure.

## 10. CLI decision note

**Current recommendation:** do **not** add a generic cross-repo `agent-flow` (or similar) CLI yet. Manual skill invocation keeps behavior visible and avoids premature abstraction.

**Next possible phase:** add a **`/grill`** entry in `ai/assets/commands/registry.yaml` as a thin alias to **`grill-plan`** after **two to three** successful real cycles with the manual loop.

**Later possible phase:** a dedicated **`agent-flow`** (or equivalent) helper **only if** manual orchestration of the same steps becomes repetitive and the contract is stable.

## See also

- Human tutorial: [docs/AGENT_WORKFLOW_LOOP.md](../docs/AGENT_WORKFLOW_LOOP.md)
- Vault resolution: [docs/AI_PROMPTS_SYSTEM.md](../docs/AI_PROMPTS_SYSTEM.md)
- Wiki capture: [docs/VAULT_PROJECT_WIKI_FLOW.md](../docs/VAULT_PROJECT_WIKI_FLOW.md)
- Skill index: [ai/assets/skills/README.md](assets/skills/README.md)
