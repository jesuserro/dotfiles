#!/usr/bin/env bats
# agent-validate-dotfiles: orchestrator contract (read-only gate).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/agent-validate-dotfiles.sh"
}

@test "agent-validate-dotfiles script exists and is executable" {
	[[ -f "${SCRIPT}" ]]
	[[ -x "${SCRIPT}" ]]
}

@test "agent-validate-dotfiles script does not invoke chezmoi apply" {
	! grep -q 'chezmoi apply' "${SCRIPT}"
}

@test "agent-validate-dotfiles script does not invoke make update" {
	! grep -Eq 'make update([^-]|$)' "${SCRIPT}"
}

@test "agent-validate-dotfiles script orchestrates expected validators" {
	grep -q 'guard_checkout_ai_surface' "${SCRIPT}"
	grep -q 'validate-skills-structure.sh' "${SCRIPT}"
	grep -q 'ai-mcp-governance' "${SCRIPT}"
	grep -q 'agent-validate-changed.sh' "${SCRIPT}"
	grep -q 'bats-docs' "${SCRIPT}"
	grep -q 'bats-agent' "${SCRIPT}"
	grep -q 'update-check' "${SCRIPT}"
}

@test "Makefile defines agent-validate audit and full targets" {
	run make -pn -C "${DOTFILES_DIR}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"agent-validate:"* ]]
	[[ "${output}" == *"agent-validate-audit:"* ]]
	[[ "${output}" == *"agent-validate-full:"* ]]
	[[ "${output}" == *"agent-validate-dotfiles.sh"* ]]
}

@test "agent-validate-audit remains quality-check plus security-check" {
	run make -pn -C "${DOTFILES_DIR}"
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep '^agent-validate-audit:' | grep -q 'quality-check'
	echo "${output}" | grep '^agent-validate-audit:' | grep -q 'security-check'
}
