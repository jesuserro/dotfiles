#!/usr/bin/env bats
# GitHub token policy docs: gh CLI vs MCP secrets isolation.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TOKEN_DOC="${DOTFILES_DIR}/docs/TOKEN_GITHUB_GH.md"
	CAMBIAR_DOC="${DOTFILES_DIR}/docs/CAMBIAR_TOKEN_GITHUB.md"
}

@test "TOKEN_GITHUB_GH.md exists and forbids global GH_TOKEN for gh CLI" {
	[[ -f "${TOKEN_DOC}" ]]
	grep -q 'gh auth switch' "${TOKEN_DOC}"
	grep -q 'jesuserro' "${TOKEN_DOC}"
	grep -q 'jesus-ixatu' "${TOKEN_DOC}"
	grep -qE 'No.*GH_TOKEN|no exportar.*GH_TOKEN|No debe haber.*GH_TOKEN' "${TOKEN_DOC}"
	run grep -E 'gh CLI.*mcp-secrets\.env|terminal.*mcp-secrets' "${TOKEN_DOC}"
	[[ "${status}" -eq 1 ]]
}

@test "TOKEN_GITHUB_GH.md documents MCP uses GITHUB_PERSONAL_ACCESS_TOKEN only" {
	grep -q 'GITHUB_PERSONAL_ACCESS_TOKEN' "${TOKEN_DOC}"
	grep -q 'MCP' "${TOKEN_DOC}"
}

@test "CAMBIAR_TOKEN_GITHUB.md does not recommend sourcing codex.env for gh" {
	grep -q 'gh auth switch' "${CAMBIAR_DOC}"
	run grep -E 'source ~/.secrets/codex\.env.*(terminal|gh|recargar)' "${CAMBIAR_DOC}"
	[[ "${status}" -eq 1 ]]
}

@test "CAMBIAR_TOKEN_GITHUB.md post-apply bullets omit global GH_TOKEN generation" {
	run grep -E 'Genera.*GH_TOKEN|export GH_TOKEN|export GITHUB_TOKEN' "${CAMBIAR_DOC}"
	[[ "${status}" -eq 1 ]]
}
