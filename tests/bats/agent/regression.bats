#!/usr/bin/env bats
# Agent-first regression index — verifies historical risks remain covered by dedicated tests.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	BATS_DIR="${DOTFILES_DIR}/tests/bats"
	MAKEFILE_TESTS="${DOTFILES_DIR}/tests/Makefile.tests"
	AGENT_README="${BATS_DIR}/agent/README.md"
}

assert_test_file() {
	local file="$1"
	[[ -f "${file}" ]] || {
		echo "missing test file: ${file}" >&2
		return 1
	}
}

assert_contains() {
	local file="$1"
	local pattern="$2"
	assert_test_file "${file}"
	grep -qE "${pattern}" "${file}" || {
		echo "pattern not found in ${file}: ${pattern}" >&2
		return 1
	}
}

@test "agent regression README documents scenario map" {
	[[ -f "${AGENT_README}" ]]
	grep -q 'Scenario map' "${AGENT_README}"
	grep -q 'dotfiles-apply' "${AGENT_README}"
	grep -q 'SCRIPT_CONVENTIONS' "${AGENT_README}"
}

@test "regression: canonical skills runtime in checkout is covered" {
	assert_test_file "${BATS_DIR}/skills/canonical-skills.bats"
	assert_contains "${BATS_DIR}/skills/canonical-skills.bats" '\.claude/skills'
	assert_test_file "${BATS_DIR}/skills/validate-skills-structure.bats"
	assert_contains "${BATS_DIR}/skills/validate-skills-structure.bats" 'non-canonical skills directory found: \.claude/skills'
	assert_contains "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" '\.claude/skills'
	grep -q '0004-ai-assets-not-materialized' "${DOTFILES_DIR}/docs/adr/README.md"
}

@test "regression: MCP taxonomy and governance drift is covered" {
	assert_test_file "${BATS_DIR}/mcp/validate-governance.bats"
	assert_test_file "${BATS_DIR}/docs/mcp-taxonomy-consistency.bats"
	assert_contains "${BATS_DIR}/docs/mcp-taxonomy-consistency.bats" 'uvx mcp-server-fetch'
	assert_test_file "${BATS_DIR}/system/mcp-manifest.bats"
	grep -qE 'bats-mcp|bats-governance|mcp-manifest' "${MAKEFILE_TESTS}"
}

@test "regression: git hooks contract is covered" {
	assert_test_file "${BATS_DIR}/git-hooks/hooks.bats"
	assert_contains "${BATS_DIR}/git-hooks/hooks.bats" 'pre-commit'
	assert_contains "${BATS_DIR}/git-hooks/hooks.bats" 'post-commit'
	grep -q 'bats-git-hooks' "${MAKEFILE_TESTS}"
}

@test "regression: treegen and STRUCTURE.md drift is covered" {
	assert_contains "${DOTFILES_DIR}/scripts/treegen.sh" '\-\-check'
	assert_contains "${BATS_DIR}/git-hooks/hooks.bats" 'treegen --check'
	grep -q 'STRUCTURE.md' "${DOTFILES_DIR}/docs/AGENT_WORKFLOW.md"
}

@test "regression: Playwright Docker Chezmoi symlink is covered" {
	assert_test_file "${BATS_DIR}/system/playwright-docker.bats"
	assert_contains "${BATS_DIR}/system/playwright-docker.bats" 'symlink_playwright-docker'
	assert_contains "${BATS_DIR}/chezmoi/smoke.bats" 'playwright-docker'
	[[ -f "${DOTFILES_DIR}/dot_local/bin/symlink_playwright-docker.tmpl" ]]
}

@test "regression: Node shadowing by Cursor is covered" {
	assert_test_file "${BATS_DIR}/system/update-workflow.bats"
	assert_contains "${BATS_DIR}/system/update-workflow.bats" 'shadowing'
	assert_test_file "${BATS_DIR}/system/update-node-runtime.bats"
	assert_contains "${BATS_DIR}/system/update-node-runtime.bats" 'shadowing'
	assert_contains "${DOTFILES_DIR}/scripts/update/lib/node_runtime.sh" 'shadowing'
}

@test "regression: mcp-server-fetch uvx runtime-managed contract is covered" {
	assert_contains "${BATS_DIR}/docs/mcp-taxonomy-consistency.bats" 'uvx mcp-server-fetch'
	assert_contains "${BATS_DIR}/system/update-workflow.bats" 'mcp-server-fetch'
	run grep -q 'uv tool install mcp-server-fetch' "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	[[ "${status}" -eq 1 ]]
}

@test "regression: dotfiles-update global wrapper is covered" {
	assert_test_file "${BATS_DIR}/system/dotfiles-update.bats"
	assert_contains "${BATS_DIR}/system/dotfiles-update.bats" 'make update'
	[[ -f "${DOTFILES_DIR}/bin/dotfiles-update" ]]
	[[ -f "${DOTFILES_DIR}/dot_local/bin/symlink_dotfiles-update.tmpl" ]]
	grep -q 'dotfiles-update\.bats' "${DOTFILES_DIR}/scripts/agent-validate-changed.sh"
}

@test "regression: dotfiles-apply safe Chezmoi wrapper is covered" {
	assert_test_file "${BATS_DIR}/system/dotfiles-apply.bats"
	assert_contains "${BATS_DIR}/system/dotfiles-apply.bats" 'CHEZMOI_STUB_LOG'
	assert_contains "${BATS_DIR}/system/dotfiles-apply.bats" '\-\-apply --yes'
	grep -q 'dotfiles-apply\.bats' "${MAKEFILE_TESTS}"
}

@test "regression: agent-validate-report handoff report is covered" {
	assert_test_file "${BATS_DIR}/system/agent-validate-report.bats"
	assert_contains "${BATS_DIR}/system/agent-validate-report.bats" 'AGENT_VALIDATE_REPORT_PATH'
	assert_contains "${BATS_DIR}/system/agent-validate-report.bats" 'ADR 0004'
	[[ -f "${DOTFILES_DIR}/scripts/agent-validate-report.sh" ]]
	grep -q 'agent-validate-report' "${DOTFILES_DIR}/docs/AGENT_WORKFLOW.md"
}

@test "regression: SCRIPT_CONVENTIONS dry-run/check policy is covered" {
	[[ -f "${DOTFILES_DIR}/docs/SCRIPT_CONVENTIONS.md" ]]
	assert_test_file "${BATS_DIR}/system/dry-run-guard.bats"
	assert_contains "${BATS_DIR}/system/dry-run-guard.bats" 'SCRIPT_CONVENTIONS'
	assert_contains "${BATS_DIR}/docs/documentation-consistency.bats" 'SCRIPT_CONVENTIONS'
	grep -q 'SCRIPT_CONVENTIONS' "${DOTFILES_DIR}/docs/AGENT_WORKFLOW.md"
}

@test "regression: GitNexus double separator and gnanalyze typo are covered" {
	assert_test_file "${BATS_DIR}/zsh/gitnexus_aliases.bats"
	assert_contains "${BATS_DIR}/zsh/gitnexus_aliases.bats" 'gnx-analyze-here -- --skip-agents-md'
	assert_contains "${BATS_DIR}/git-hooks/hooks.bats" 'gnanalyze'
	assert_test_file "${BATS_DIR}/gitnexus/gitnexus-status.bats"
	assert_contains "${BATS_DIR}/gitnexus/gitnexus-status.bats" 'skip-agents-md'
}

@test "Makefile defines bats-agent and agent-validate runs regression index" {
	grep -q '^bats-agent:' "${MAKEFILE_TESTS}"
	grep -q 'agent/regression\.bats' "${MAKEFILE_TESTS}"
	grep -q 'bats-agent' "${DOTFILES_DIR}/scripts/agent-validate-dotfiles.sh"
}
