# Agent regression index

Meta-test suite that maps **historical dotfiles risks** to existing Bats coverage. It does not re-run every scenario end-to-end; it verifies that the dedicated tests, scripts, and docs still exist and remain wired.

## Purpose

After agent-first BUILDs (workflow docs, validation gates, `dotfiles-apply`, `SCRIPT_CONVENTIONS`, canonical skills cleanup), this index answers:

- Are we still protected against known regressions?
- Where is each risk tested and documented?

Prefer extending the **specific** test file when a scenario breaks. Update this README only when the risk map changes.

## Run

```bash
bats tests/bats/agent/regression.bats
make bats-agent
```

`make agent-validate` includes `bats-agent` (fast index only).

## Policy

| Do | Don't |
|----|-------|
| Add meta-tests when coverage already exists elsewhere | Duplicate full integration logic here |
| Update the scenario table when adding a new historical risk | Rewrite validators or installers in this BUILD |
| Use fixtures/stubs in downstream tests, not real HOME | Run `chezmoi apply` or `make update` from this suite |

## Scenario map

| # | Scenario | Risk | Primary test(s) | Doc |
|---|----------|------|-----------------|-----|
| 1 | Runtime skills in checkout (`.claude/skills/`) | ADR 0004 violation; blocks `agent-validate` | `skills/canonical-skills.bats`, `skills/validate-skills-structure.bats` | `docs/adr/0004-ai-assets-not-materialized.md` |
| 2 | MCP misclassification / taxonomy drift | Wrong runtime contract in MANIFEST | `mcp/validate-governance.bats`, `docs/mcp-taxonomy-consistency.bats`, `system/mcp-manifest.bats` | `docs/MCP_TAXONOMY.md` |
| 3 | Git hooks contract (treegen, GitNexus post-commit) | Broken pre-commit or refresh | `git-hooks/hooks.bats` | `docs/GITNEXUS_OPERATIONAL_POLICY.md` |
| 4 | `STRUCTURE.md` / treegen drift | Hand-edited tree inventory | `git-hooks/hooks.bats` (`treegen --check`) | `docs/AGENT_WORKFLOW.md` § STRUCTURE |
| 5 | Playwright Docker Chezmoi symlink | Legacy hook or missing `~/.local/bin` entry | `system/playwright-docker.bats`, `chezmoi/smoke.bats` | `docs/adr/0007-playwright-docker-via-chezmoi-bin.md` |
| 6 | Node shadowed by Cursor IDE | GitNexus/analyze on Node &lt; 22 | `system/update-workflow.bats`, `system/update-node-runtime.bats`, `zsh/gitnexus_aliases.bats` | `docs/SCRIPT_CONVENTIONS.md`, update scripts |
| 7 | `mcp-server-fetch` persistent uv tool | Drift from uvx runtime-managed contract | `docs/mcp-taxonomy-consistency.bats`, `system/update-workflow.bats` | `docs/MCP_TAXONOMY.md` |
| 8 | `dotfiles-update` global wrapper | Ambiguous maintenance entrypoint | `system/dotfiles-update.bats`, `chezmoi/smoke.bats` | `docs/adr/0009-dotfiles-update-wrapper.md` |
| 9 | `dotfiles-apply` safe Chezmoi | Accidental HOME mutation | `system/dotfiles-apply.bats` | `docs/CHEZMOI.md`, `docs/SCRIPT_CONVENTIONS.md` |
| 10 | `agent-validate-report` | Handoffs without validation evidence | `system/agent-validate-report.bats` | `docs/AGENT_WORKFLOW.md` |
| 11 | `SCRIPT_CONVENTIONS` | Agents run mutating commands without preview | `system/dry-run-guard.bats`, `docs/documentation-consistency.bats` | `docs/SCRIPT_CONVENTIONS.md` |
| 12 | GitNexus `--` separator / `gnanalyze` typo | Broken human refresh CLI | `zsh/gitnexus_aliases.bats`, `git-hooks/hooks.bats`, `gitnexus/gitnexus-status.bats` | `docs/GITNEXUS_OPERATIONAL_POLICY.md` |
