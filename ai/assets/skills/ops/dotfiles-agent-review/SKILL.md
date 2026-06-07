---
name: dotfiles-agent-review
description: Use when reviewing changes in the dotfiles repo — Chezmoi, secrets, MCPs, skills, hooks, tests, docs. Read-only by default; no destructive apply or install unless the user explicitly requests it.
---

# Dotfiles Agent Review

## When to Use

- After a BUILD in `~/dotfiles`, before handoff or merge
- When the user asks for a read-only audit of a diff, branch or working tree
- To validate that changes respect dotfiles contracts (Chezmoi, MCP taxonomy, canonical skills, GitNexus policy)
- **Not** for day-to-day operations → use **`dotfiles-operations`**
- **Not** for cross-project architecture design → use **`architecture-review`** (vault/project scope)
- **Not** for MCP manifest edits → use **`mcp-governance`** during implementation

Default mode: **read-only review**. Do not apply Chezmoi, run `make update`, or install packages unless the user explicitly exits review mode.

## Inputs Expected

Provide or discover before reviewing:

| Input | Source |
|-------|--------|
| Diff or file list | `git diff`, user handoff, or stated paths |
| BUILD objective | Handoff § Objetivo or user message |
| Zones touched | Map to [docs/VALIDATION_MATRIX.md](../../../../docs/VALIDATION_MATRIX.md) |
| Contract docs | [docs/AGENT_FIRST_SUMMARY.md](../../../../docs/AGENT_FIRST_SUMMARY.md), [docs/AGENT_WORKFLOW.md](../../../../docs/AGENT_WORKFLOW.md), [docs/AI_REPO_MAP.md](../../../../docs/AI_REPO_MAP.md) |

If inputs are incomplete, state assumptions explicitly in the report.

## Guidelines

- Separate **facts** (what the diff does) from **risks** (what could break)
- Classify every finding: **critical** / **medium** / **minor**
- Recommend validations from VALIDATION_MATRIX; run read-only checks when possible
- Propose fixes as **next actions**, do not apply them in review mode
- Do not print secrets (`sops -d`, `cat mcp-secrets.env`)

## Checklist

### Chezmoi

- [ ] No unauthorized `chezmoi apply` implied by the change
- [ ] Template changes in `dot_*`, `dot_local/`, `.chezmoiscripts/` have drift/apply implications documented
- [ ] No direct edits to HOME paths recommended without apply acotado
- [ ] Chezmoiscripts hooks order and side effects considered

### Secrets / SOPS / Age

- [ ] No plaintext secrets in diff
- [ ] Changes to `secrets.sops.yaml` note need for `chezmoi apply -i scripts` (human action)
- [ ] No recommendation to decrypt secrets to stdout

### Skills IA

- [ ] Edits only under `ai/assets/skills/` (canonical), not `.claude/skills/` in repo
- [ ] No materialization of skills inside checkout
- [ ] New skills follow [dotfiles-skill-registration](../dotfiles-skill-registration/SKILL.md) conventions
- [ ] Skill index updated if required

### MCPs

- [ ] MANIFEST changes paired with governance check (`make ai-mcp-governance`)
- [ ] Layer/category consistent with [docs/MCP_TAXONOMY.md](../../../../docs/MCP_TAXONOMY.md)
- [ ] No hand-edits to generated agent MCP configs in HOME
- [ ] Runtime-managed MCPs (e.g. fetch via uvx) not installed as persistent tools

### Hooks

- [ ] Git hooks (`scripts/hooks/`, `.githooks/`) preserve treegen and GitNexus post-commit contracts
- [ ] Chezmoiscripts hooks do not introduce silent HOME mutation without documentation

### GitNexus

- [ ] No manual edits to `<!-- gitnexus:* -->` blocks in AGENTS.md / CLAUDE.md
- [ ] No agent-triggered `gnx-analyze-here` without explicit user request
- [ ] Symbol edits considered for `gitnexus_impact` if applicable

### STRUCTURE.md

- [ ] Structural tree changes will be picked up by pre-commit treegen (not hand-edited)
- [ ] New top-level dirs documented in AI_REPO_MAP if they change agent contracts

### Shell scripts

- [ ] shellcheck/shfmt implications for changed `.sh` / `.bash` / launchers
- [ ] No destructive git operations introduced without guardrails
- [ ] `DRY_RUN=1` respected for install scripts in agent workflows

### Tests

- [ ] New behavior has bats or documented manual validation
- [ ] Changed zones have matching entry in VALIDATION_MATRIX
- [ ] Tests wired in Makefile.tests if new `.bats` file added (flag if missing)

### Documentation

- [ ] Docs link to canonical sources (no large duplicate blocks)
- [ ] AGENT_WORKFLOW / VALIDATION_MATRIX / AI_REPO_MAP updated if contracts change
- [ ] OPERATIONS_CHEATSHEET agent policy still consistent

## Output

Deliver a structured report:

1. **Veredicto** — pass / pass with warnings / fail
2. **Riesgos críticos** — must fix before merge or apply
3. **Riesgos medios** — should fix soon
4. **Observaciones menores** — style, nits, doc drift
5. **Validaciones recomendadas** — commands from VALIDATION_MATRIX for zones touched (`make agent-validate-changed`, `make agent-validate`, `make agent-validate-report`)
6. **Validaciones ejecutadas** — if run: command + pass/fail; attach `build/agent-validation/latest.md` when available
7. **Siguiente acción** — BUILD fix, human apply, or approve

Post-BUILD gate mínimo: `make agent-validate` + `make agent-validate-report`. Si hay `.claude/` en checkout: `rm -rf .claude/` (ADR 0004) y revalidar — ver [AGENT_FIRST_SUMMARY.md](../../../../docs/AGENT_FIRST_SUMMARY.md).

State explicitly: "This review is read-only unless the user requested fixes."

## Examples

- Post-BUILD review of docs-only change: run `make bats-docs`, report pass with minor link suggestion
- Diff touching MANIFEST: flag missing `ai-mcp-governance` as medium risk; recommend command before handoff
- Diff adding files under `.claude/skills/`: critical — violates canonical skills contract

## Delegation

- Implement fixes after review: user handoff with [cursor-build.md](../../../handoffs/cursor-build.md) template
- MCP implementation detail: **`mcp-governance`**
- Install/update troubleshooting: **`dotfiles-operations`**, **`system-updates`**
