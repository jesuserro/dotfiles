#!/usr/bin/env bats
# AI runtime hook prefers uv and uses requirements hash stamp.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TMPL="${DOTFILES_DIR}/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl"
}

@test "ai runtime hook uses uv not pip install -r on every run" {
	grep -q 'command -v uv' "$TMPL"
	grep -q 'uv pip install' "$TMPL"
	grep -q '.requirements.sha256' "$TMPL"
	! grep -q 'pip install -r' "$TMPL"
}

@test "ai runtime hook skips when uv missing" {
	grep -q 'uv not in PATH' "$TMPL"
}
