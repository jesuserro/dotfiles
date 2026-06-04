#!/usr/bin/env bats
# docs: human GitNexus index refresh procedure (documentation contract).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	POLICY="${DOTFILES_DIR}/docs/GITNEXUS_OPERATIONAL_POLICY.md"
	CHEATSHEET="${DOTFILES_DIR}/docs/OPERATIONS_CHEATSHEET.md"
	MCP_QUICKREF="${DOTFILES_DIR}/docs/MCP_QUICKREF.md"
	CLI_SKILL="${DOTFILES_DIR}/ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md"
}

@test "policy documents canonical human refresh with skip-agents-md" {
	grep -q 'gnx-analyze-here --skip-agents-md' "${POLICY}"
}

@test "policy states agents must not auto-refresh on STALE" {
	grep -qi 'no implica refresh automático' "${POLICY}"
	grep -qi 'agentes' "${POLICY}"
}

@test "policy requires closing Cursor or MCP before analyze when processes are live" {
	grep -qi 'cerrar Cursor' "${POLICY}"
	grep -qi 'gitnexus mcp' "${POLICY}"
}

@test "policy forbids deleting lbug automatically" {
	grep -q '.gitnexus/lbug' "${POLICY}"
	grep -qi 'No borrar' "${POLICY}"
}

@test "cheatsheet contains short human refresh flow with status and skip-agents-md" {
	grep -q '### Refresh humano del índice' "${CHEATSHEET}"
	grep -q 'make gitnexus-status' "${CHEATSHEET}"
	grep -q 'gnx-analyze-here --skip-agents-md' "${CHEATSHEET}"
	grep -q 'make bats-docs' "${CHEATSHEET}"
}

@test "MCP_QUICKREF mentions skip-agents-md for human index refresh" {
	grep -q 'skip-agents-md' "${MCP_QUICKREF}"
	grep -q 'GITNEXUS_OPERATIONAL_POLICY.md' "${MCP_QUICKREF}"
}

@test "gitnexus-cli skill documents skip-agents-md for human refresh" {
	grep -q 'skip-agents-md' "${CLI_SKILL}"
	grep -q 'make gitnexus-status' "${CLI_SKILL}"
}

@test "touched docs and gitnexus-cli skill do not recommend npx gitnexus analyze as default flow" {
	local file
	for file in "${POLICY}" "${CHEATSHEET}" "${MCP_QUICKREF}" "${CLI_SKILL}"; do
		run grep -Ei '(recomend|usar|ejecutar|prefiere|prefer|default|canonical).*npx gitnexus analyze' "$file"
		[[ "${status}" -eq 1 ]]
	done
}
