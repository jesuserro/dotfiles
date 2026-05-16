#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	CHECK_SCRIPT="${DOTFILES_DIR}/scripts/check-azure-tools.sh"
	AZURE_ALIASES="${DOTFILES_DIR}/zsh/55-aliases-azure.zsh"
	AZURE_DOC="${DOTFILES_DIR}/docs/ops/azure-tooling.md"
}

@test "check-azure-tools.sh exists" {
	[[ -f "${CHECK_SCRIPT}" ]]
}

@test "check-azure-tools.sh passes bash -n" {
	run bash -n "${CHECK_SCRIPT}"
	[[ "${status}" -eq 0 ]]
}

@test "azure aliases module exists" {
	[[ -f "${AZURE_ALIASES}" ]]
}

@test "azure aliases module passes bash -n" {
	run bash -n "${AZURE_ALIASES}"
	[[ "${status}" -eq 0 ]]
}

@test "azure tooling docs exist" {
	[[ -f "${AZURE_DOC}" ]]
}

@test "check-azure-tools.sh does not contain forbidden Azure commands" {
	local forbidden=(
		"az login"
		"az account set"
		"az group create"
		"az group delete"
		"az acr create"
		"az acr delete"
		"az containerapp create"
		"az containerapp delete"
		"az sql"
		"az keyvault"
	)

	local pattern
	for pattern in "${forbidden[@]}"; do
		run grep -F "${pattern}" "${CHECK_SCRIPT}"
		[[ "${status}" -ne 0 ]]
	done
}

@test "azure aliases do not contain destructive aliases" {
	run grep -E '^alias .*=(.*delete|.*remove|.*purge)' "${AZURE_ALIASES}"
	[[ "${status}" -ne 0 ]]
}

@test "zshrc loads azure aliases before local overrides" {
	run grep -n '55-aliases-azure.zsh' "${DOTFILES_DIR}/zshrc"
	[[ "${status}" -eq 0 ]]
}
