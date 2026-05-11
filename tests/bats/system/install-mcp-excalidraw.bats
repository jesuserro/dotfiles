#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_EX="${DOTFILES_DIR}/scripts/install-mcp-excalidraw.sh"
	setup_temp_dir
	FAKE_HOME="${TEST_TEMP_DIR}/home"
	mkdir -p "${FAKE_HOME}"
}

teardown() {
	teardown_temp_dir
}

@test "install-mcp-excalidraw.sh exists and passes bash -n" {
	[[ -f "${INSTALL_EX}" ]]
	run bash -n "${INSTALL_EX}"
	[[ "${status}" -eq 0 ]]
}

@test "install-mcp-excalidraw DRY_RUN prints repo, target and build plan" {
	run env DRY_RUN=1 HOME="${FAKE_HOME}" bash "${INSTALL_EX}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"https://github.com/yctimlin/mcp_excalidraw"* ]]
	[[ "${output}" == *"${FAKE_HOME}/mcp-servers/excalidraw-mcp"* ]]
	[[ "${output}" == *"npm install"* ]]
	[[ "${output}" == *"npm run build"* ]]
	[[ "${output}" == *"dist/index.js"* ]]
	# Must not clone anything.
	[[ ! -d "${FAKE_HOME}/mcp-servers" ]]
}

@test "install-mcp-excalidraw DRY_RUN honors EXCALIDRAW_MCP_REPO_URL override" {
	run env DRY_RUN=1 HOME="${FAKE_HOME}" \
		EXCALIDRAW_MCP_REPO_URL="https://example.invalid/custom/excalidraw" \
		bash "${INSTALL_EX}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"https://example.invalid/custom/excalidraw"* ]]
	[[ "${output}" != *"yctimlin/mcp_excalidraw"* ]]
}

@test "install-mcp-excalidraw target exists in install.mk and is NOT part of 'install:'" {
	run grep -E "^install-mcp-excalidraw:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-mcp-excalidraw"* ]]
}
