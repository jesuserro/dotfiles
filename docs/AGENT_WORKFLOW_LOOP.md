# Agent Workflow Loop

## 1. Purpose

The **Agent Workflow Loop** is the human-oriented name for the dotfiles skill family that takes you from a vague idea to durable knowledge: challenge the idea, write a spec in your vault, slice work as GitHub Issues (Markdown only), implement using the repo’s real tests, then capture what matters in the vault or wiki.

The loop is **native to this dotfiles setup** (skills under `ai/assets/skills/ops/`, templates beside those skills, and your `vault_trabajo` tree). It borrows a familiar shape from public agent-skill patterns (grill → spec → issues → test-guided work), but the **canonical name here is Agent Workflow Loop**, not a third-party product name.

**AI agents:** for orchestration, skill selection, project delegation, and GitHub/CLI policy, read [Agent Workflow for agents](../ai/AGENT_WORKFLOW_FOR_AGENTS.md).

## 2. When to use this workflow

Use it when:

- A feature or change is **not** ready to implement in one shot from chat alone.
- You want **traceable decisions** before a PRD or technical spec.
- You need **vertical GitHub Issues** with clear acceptance criteria, without automating `gh`.
- You will implement in a **project repo** and want tests and CI aligned with that repo’s conventions.

Skip or shorten earlier phases when the scope is trivial (typos, one-line fixes) or a spec already exists and is accepted.

## 3. Mental model

| Layer | Role |
|-------|------|
| **dotfiles** | Method: skills, templates, naming, and how agents should behave. Nothing here is your project’s source of truth. |
| **vault_trabajo** | Knowledge store: real artifacts per project under `projects/<project>/knowledge/...`. Resolve the vault root with **`AI_PROMPTS_VAULT_ROOT`** (see [AI_PROMPTS_SYSTEM.md](AI_PROMPTS_SYSTEM.md)). |
| **GitHub Issues** | Operational tracking: paste-ready Markdown produced in chat or an editor; optional links back to vault paths. |
| **Project repo** | Execution: code, tests, CI, canonical implementation docs. |

Do **not** hardcode personal absolute paths in docs or skills. Use `AI_PROMPTS_VAULT_ROOT` and logical paths such as `projects/<project>/knowledge/...`.

## 4. End-to-end flow

Target pipeline:

```text
idea / chat
  → grill-plan (Grill Report only)
  → to-spec (PRD, contract, implementation spec, or ADR via adr-writer)
  → to-issues (Markdown for GitHub, manual paste)
  → test-driven-change (discover local test workflow, then implement)
  → vault / wiki update (implementation notes, decisions, reports, etc.)
```

Entry skill: [Dotfiles Agent Workflow](../ai/assets/skills/ops/agent-workflow/SKILL.md).

## 5. Phase 1: Grill the idea

**Skill:** [grill-plan](../ai/assets/skills/ops/grill-plan/SKILL.md).

`grill-plan` does **not** output a PRD or GitHub Issue. It runs an interview-style pass: options, tradeoffs, resolved decisions, and risks. The artifact is a **Grill Report** (template under `ai/assets/skills/ops/grill-plan/templates/grill-report.md`).

Save the report under the vault’s reports tree, for example:

`projects/<project>/knowledge/reports/grill/`

Details and path layout: [vault-issue-bridge](../ai/assets/skills/ops/vault-issue-bridge/SKILL.md).

## 6. Phase 2: Convert decisions into a spec

**Skill:** [to-spec](../ai/assets/skills/ops/to-spec/SKILL.md).

Input: an accepted Grill Report (or equivalent agreed context).

Output types:

- **PRD** or product-facing brief — use `to-spec` templates.
- **Contract** (API/data boundaries) — use contract outline.
- **Implementation spec** — technical execution plan.
- **ADR** — do **not** invent a second ADR standard in the spec skill; follow [Dotfiles ADR Writer](../ai/assets/skills/docs/adr-writer/SKILL.md) and store under `projects/<project>/knowledge/decisions/` when appropriate.

Typical vault folder for specs:

`projects/<project>/knowledge/reports/specs/`

## 7. Phase 3: Generate GitHub Issues Markdown

**Skill:** [to-issues](../ai/assets/skills/ops/to-issues/SKILL.md).

Produces **Markdown blocks** you paste into GitHub’s “New issue” UI. One **vertical** issue per block: goal, scope, out of scope, acceptance criteria, validation, links to the spec path (placeholders like `<spec_path>` until filed).

This skill intentionally does **not** run `gh issue create`.

Optional staging folder in the vault (if you keep drafts there):

`projects/<project>/knowledge/reports/issues/`

## 8. Phase 4: Implement with local test discovery

**Skill:** [test-driven-change](../ai/assets/skills/ops/test-driven-change/SKILL.md).

Before naming commands, the agent (or you) should read, in order of availability:

1. `AGENTS.md` (or project agent rules)
2. `README.md` / `CONTRIBUTING.md`
3. `Makefile` and related includes
4. `tests/` and test config (`pytest.ini`, `package.json` scripts, etc.)
5. CI config (e.g. `.github/workflows/`)

Then align implementation and validation with what the repo **actually** runs.

## 9. Phase 5: Update vault/wiki knowledge

After meaningful work, capture distilled knowledge where it belongs:

- **Wiki-style notes** (patterns, incidents, implementation notes): see [Vault Project Wiki Flow](VAULT_PROJECT_WIKI_FLOW.md) and [Vault Project Wiki](../ai/assets/skills/ops/vault-project-wiki/SKILL.md).
- **Workflow artifacts** (optional): short notes under `projects/<project>/knowledge/reports/tdd-notes/` or architecture summaries under `reports/architecture-reviews/` when useful.

Keep the project repo as the **implementation** source of truth; the vault holds **reusable** context that should survive refactors.

## 10. Where artifacts live

Under `vault_trabajo` (logical paths after `${AI_PROMPTS_VAULT_ROOT}`):

| Path | Use |
|------|-----|
| `projects/<project>/knowledge/reports/grill/` | Grill Reports |
| `projects/<project>/knowledge/reports/specs/` | PRDs, contracts, implementation specs |
| `projects/<project>/knowledge/reports/issues/` | Optional drafts of issue bodies |
| `projects/<project>/knowledge/reports/architecture-reviews/` | Read-only review outputs |
| `projects/<project>/knowledge/reports/tdd-notes/` | Durable test-strategy or friction notes |
| `projects/<project>/knowledge/decisions/` | ADRs and decision records |
| `projects/<project>/knowledge/wiki/` | Optional wiki-style pages |

A `_template` project tree can mirror this layout for new projects. Dotfiles ships the **convention**; your vault holds the **files**.

## 11. Recommended human prompts

Copy and adapt these when talking to an agent that has access to these skills:

- “Use **grill-plan** on this idea before we implement it.”
- “Convert this Grill Report into an **implementation spec** using **to-spec**.”
- “Convert this spec into **vertical GitHub Issues Markdown** using **to-issues**.”
- “Use **test-driven-change** for this issue; **first discover** the repo test workflow from AGENTS.md, Makefile, and CI.”
- “Run **architecture-review** in **read-only** mode.”
- “Use **vault-issue-bridge** conventions for paths under `projects/<project>/knowledge/reports/`.”

## 12. What is intentionally not automated yet

- **No `gh issue create`** from these skills by default.
- **No global `/grill` command** in `ai/assets/commands/registry.yaml` yet (may be added later if the manual loop sticks).
- **No Chezmoi changes** required for this family: category `ops/` is already linked to agent surfaces.

## 13. Example: from idea to issue (generic)

**Idea:** Add an isolated fixture environment for integration tests so local runs do not hit shared infrastructure.

**Grill (`grill-plan`):** Grill Report lists constraints (runtime, data volume), rejects “always hit staging API,” chooses “docker-compose profile + seeded DB,” records risks (flaky ports, CI time).

**Spec (`to-spec`):** Implementation spec under `reports/specs/` with setup steps, teardown, and acceptance checks.

**Issues (`to-issues`):** One vertical issue: “Add compose profile and seed script for isolated integration fixtures,” with scope, out of scope, acceptance criteria, and validation commands to be filled after test discovery.

**Implementation (`test-driven-change`):** Read `Makefile` and CI; add the smallest failing test that proves isolation; implement; run the real project test command.

**Closure:** Short implementation note or wiki update in the vault; link to the merged PR in the project repo.

No domain-specific tables or pipelines—only structure you can reuse.

## 14. Checklist

- [ ] Set or confirm `AI_PROMPTS_VAULT_ROOT` points at your vault root.
- [ ] Choose `<project>` slug matching `projects/<project>/` in the vault.
- [ ] Complete Grill Report before locking a spec.
- [ ] Pick spec type (PRD / contract / implementation spec / ADR) explicitly.
- [ ] Generate issue Markdown; paste into GitHub manually.
- [ ] Discover test commands from the repo before implementing.
- [ ] Use `architecture-review` read-only unless you explicitly want edits.
- [ ] Update vault/wiki only when knowledge is worth keeping.

## See also

- [AI_PROMPTS_SYSTEM.md](AI_PROMPTS_SYSTEM.md) — vault resolution and `ai-prompt`.
- [VAULT_PROJECT_WIKI_FLOW.md](VAULT_PROJECT_WIKI_FLOW.md) — when and where wiki notes live.
- [Agent Workflow for agents](../ai/AGENT_WORKFLOW_FOR_AGENTS.md) — matrix, delegation, safety rules for IA.
- Skill index: [ai/assets/skills/README.md](../ai/assets/skills/README.md).
