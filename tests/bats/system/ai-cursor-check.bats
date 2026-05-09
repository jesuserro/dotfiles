#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	AI_CURSOR_CHECK="${DOTFILES_DIR}/scripts/ai-cursor-check.sh"
}

@test "ai-cursor-check.sh exists and passes bash -n" {
	[[ -f "${AI_CURSOR_CHECK}" ]]
	run bash -n "${AI_CURSOR_CHECK}"
	[[ "${status}" -eq 0 ]]
}

@test "Makefile defines ai-cursor-check target" {
	[[ -f "${DOTFILES_DIR}/install.mk" ]]
	run grep -q '^ai-cursor-check:' "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
}

@test "make -n ai-cursor-check references the check script" {
	run make -C "${DOTFILES_DIR}" -n ai-cursor-check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"ai-cursor-check.sh"* ]]
}

@test "ai-cursor-check with empty HOME reports missing Cursor mcp.json (non-strict, exit 0)" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}"
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"mcp.json"* ]] || [[ "${output}" == *"missing"* ]] || [[ "${output}" == *"MISSING"* ]]
}

@test "ai-cursor-check STRICT=1 fails when HOME has no Cursor mcp.json" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}"
	run env HOME="${fake_home}" STRICT=1 bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"FAIL"* ]] || [[ "${output}" == *"STRICT"* ]]
}
