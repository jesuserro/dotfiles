#!/usr/bin/env bats
# MCP taxonomy and manifest profile consistency.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TAXONOMY="${DOTFILES_DIR}/docs/MCP_TAXONOMY.md"
	QUICKREF="${DOTFILES_DIR}/docs/MCP_QUICKREF.md"
	MANIFEST="${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml"
}

@test "MCP_TAXONOMY documents fetch as uvx runtime-managed" {
	grep -q 'uvx mcp-server-fetch' "${TAXONOMY}"
	run grep -q 'uv tool install mcp-server-fetch' "${TAXONOMY}"
	[[ "${status}" -eq 1 ]]
}

@test "MANIFEST fetch entry uses uvx runtime" {
	grep -A6 'id: fetch' "${MANIFEST}" | grep -q 'runtime: uvx'
}

@test "MANIFEST reserved profiles are explicitly marked not active" {
	for profile in store-etl ixatu project-local; do
		grep -q "${profile}:" "${MANIFEST}"
	done
	grep -q 'status: reserved' "${MANIFEST}"
	grep -Eiq 'not active|not rendered|reserved placeholder' "${MANIFEST}"
}

@test "update-wsl aligns fetch with uvx runtime contract" {
	SCRIPT="${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	run grep -q 'uv tool install mcp-server-fetch' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
	grep -q 'runtime-managed via uvx' "${SCRIPT}"
}

@test "MCP_QUICKREF explains reserved profiles are not operational" {
	grep -Eiq 'reserved|not rendered|not active' "${QUICKREF}"
	grep -q 'store-etl' "${QUICKREF}"
	grep -q 'STORE_ETL_WORKDIR' "${QUICKREF}"
}
