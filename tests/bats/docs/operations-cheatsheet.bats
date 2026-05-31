#!/usr/bin/env bats
# docs/OPERATIONS_CHEATSHEET.md: static documentation contract.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	CHEATSHEET="${DOTFILES_DIR}/docs/OPERATIONS_CHEATSHEET.md"
	OPERATIONS="${DOTFILES_DIR}/docs/OPERATIONS.md"
	README="${DOTFILES_DIR}/README.md"
}

@test "OPERATIONS_CHEATSHEET.md exists" {
	[[ -f "${CHEATSHEET}" ]]
}

@test "cheatsheet mentions critical make targets" {
	local target
	for target in \
		'make update-check' \
		'make update' \
		'make chezmoi-drift-report' \
		'make mcp-launcher-contract-check' \
		'make gitnexus-status' \
		'make validate-skills-structure' \
		'make ai-mcp-governance' \
		'make ai-doctor'; do
		grep -Fq "${target}" "${CHEATSHEET}"
	done
}

@test "cheatsheet does not recommend npx gitnexus as agent workflow" {
	run grep -E 'npx gitnexus' "${CHEATSHEET}"
	[[ "${status}" -eq 0 ]]
	# Must appear only in prohibition context, not as recommended flow.
	grep -q 'Prohibido' "${CHEATSHEET}" || grep -q 'prohibido' "${CHEATSHEET}"
	grep -q 'npx gitnexus' "${CHEATSHEET}"
	run grep -E '(recomend|usar|ejecutar|prefiere|prefer).*npx gitnexus' "${CHEATSHEET}"
	[[ "${status}" -eq 1 ]]
}

@test "cheatsheet states global chezmoi apply is not normal flow" {
	grep -q 'chezmoi apply' "${CHEATSHEET}"
	grep -Eiq 'no es el flujo normal|no es el flujo normal|apply global no es' "${CHEATSHEET}"
}

@test "cheatsheet links to deep docs" {
	grep -q 'CHEZMOI.md' "${CHEATSHEET}"
	grep -q 'GITNEXUS_OPERATIONAL_POLICY.md' "${CHEATSHEET}"
	grep -q 'MCP_QUICKREF.md' "${CHEATSHEET}"
}

@test "cheatsheet includes agent prohibitions section" {
	grep -q 'Política para agentes' "${CHEATSHEET}"
	grep -q 'No' "${CHEATSHEET}"
	grep -q 'make update' "${CHEATSHEET}"
}

@test "docs/OPERATIONS.md links to OPERATIONS_CHEATSHEET" {
	grep -q 'OPERATIONS_CHEATSHEET' "${OPERATIONS}"
}

@test "README.md links to OPERATIONS_CHEATSHEET" {
	grep -q 'OPERATIONS_CHEATSHEET' "${README}"
}
