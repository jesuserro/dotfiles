#!/usr/bin/env bats
# Tests for bin/validate-mcp-governance (manifest-driven governance wrapper)

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	VALIDATOR="$DOTFILES_DIR/bin/validate-mcp-governance"
}

teardown() {
	teardown_temp_dir
}

bats_require_minimum_version 1.5.0

@test "validator script exists" {
	[[ -f "$VALIDATOR" ]]
}

@test "validator is executable" {
	[[ -x "$VALIDATOR" ]] || skip "Validator not executable"
}

@test "validator uses set -euo pipefail" {
	grep -q "set -euo pipefail" "$VALIDATOR"
}

@test "validator resolves DOTFILES_DIR from script location or env" {
	grep -q 'BASH_SOURCE\[0\]' "$VALIDATOR" || grep -q "DOTFILES_DIR" "$VALIDATOR"
}

@test "validator runs make ai-mcp-validate render drift" {
	grep -q "ai-mcp-validate" "$VALIDATOR"
	grep -q "ai-mcp-render" "$VALIDATOR"
	grep -q "ai-mcp-drift" "$VALIDATOR"
}

@test "validator does not contain legacy PLATFORM_MCPS policy" {
	run grep -F "PLATFORM_MCPS" "$VALIDATOR"
	[[ "${status}" -ne 0 ]]
}

@test "validator does not contain disabled by default grep policy" {
	run grep -F "disabled by default" "$VALIDATOR"
	[[ "${status}" -ne 0 ]]
}

@test "validator does not forbid postgres in OpenCode global" {
	run grep -F "postgres found in OpenCode global" "$VALIDATOR"
	[[ "${status}" -ne 0 ]]
	run grep -F "postgres should not be in OpenCode global" "$VALIDATOR"
	[[ "${status}" -ne 0 ]]
}

@test "bin/validate-mcp-governance succeeds on repo (PyYAML required)" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	[[ -x "$VALIDATOR" ]] || skip "Validator not executable"
	run bash "$VALIDATOR" 2>&1
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MCP governance validation: PASS"* ]]
}

@test "install.mk defines ai-mcp-governance target" {
	[[ -f "${DOTFILES_DIR}/install.mk" ]]
	run grep -q '^ai-mcp-governance:' "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
}

@test "make ai-mcp-governance succeeds when PyYAML present" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-governance 2>&1
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MCP governance validation: PASS"* ]]
}
