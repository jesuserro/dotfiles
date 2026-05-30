#!/usr/bin/env bats
# store-etl project MCP is owned by the store-etl repo, not dotfiles Chezmoi hooks.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
}

@test "run_after_10_link_store_etl_mcp hook removed from dotfiles" {
	[[ ! -f "${DOTFILES_DIR}/.chezmoiscripts/run_after_10_link_store_etl_mcp.sh.tmpl" ]]
}

@test "chezmoiignore does not whitelist proyectos/store-etl paths" {
	assert_file_not_contains "${DOTFILES_DIR}/.chezmoiignore" 'proyectos/store-etl'
}
