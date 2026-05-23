#!/usr/bin/env bats
# AI assets hook warns on non-symlink blocking paths.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TMPL="${DOTFILES_DIR}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
}

@test "link ai assets warns when destination is not a symlink" {
	grep -q 'WARNING:.*not a symlink' "$TMPL"
	grep -q 'AI_ASSETS_FORCE' "$TMPL"
}
