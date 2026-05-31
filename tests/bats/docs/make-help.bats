#!/usr/bin/env bats
# make help: CLI discoverability contract.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
}

@test "make help runs successfully" {
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	[[ -n "${output}" ]]
}

@test "make help points to OPERATIONS_CHEATSHEET" {
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	grep -q 'OPERATIONS_CHEATSHEET' <<<"${output}"
}

@test "make help mentions critical read-only targets" {
	local target
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	for target in \
		'make chezmoi-drift-report' \
		'make mcp-launcher-contract-check' \
		'make gitnexus-status' \
		'make validate-skills-structure' \
		'make ai-mcp-governance' \
		'make update-check' \
		'make ai-doctor' \
		'make agent-validate-changed' \
		'make test-chezmoi' \
		'make test-bats-ci'; do
		grep -q "${target}" <<<"${output}"
	done
}

@test "make help marks update as human mutating network" {
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	grep -q 'make update' <<<"${output}"
	grep -Eiq 'human|mutating|network' <<<"${output}"
}

@test "make help does not contain test-commands typo" {
	local help_output
	help_output="$(make -C "${DOTFILES_DIR}" help)"
	grep -q 'make test-commands' <<<"${help_output}"
	! grep -q 'test-commands-' <<<"${help_output}"
}

@test "make help has safe for agents section" {
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	grep -Eiq 'safe for agents|read-only' <<<"${output}"
}

@test "make help has human mutating section" {
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	grep -Eiq 'human.*mutating|mutating.*network' <<<"${output}"
}

@test "make help mentions update-ai-skills as human opt-in with DRY_RUN preview" {
	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	grep -q 'make update-ai-skills' <<<"${output}"
	grep -Eiq 'human|opt-in|DRY_RUN' <<<"${output}"
}
