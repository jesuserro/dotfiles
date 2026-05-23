#!/usr/bin/env bats
# AI runtime hook prefers uv and uses requirements hash stamp.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TMPL="${DOTFILES_DIR}/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl"
}

@test "ai runtime hook uses uv not pip install -r on every run" {
	grep -q 'command -v uv' "$TMPL"
	grep -q 'uv pip install' "$TMPL"
	grep -q '.requirements.sha256' "$TMPL"
	run ! grep -q 'pip install -r' "$TMPL"
}

@test "ai runtime hook skips when uv missing" {
	grep -q 'uv not in PATH' "$TMPL"
}

@test "ai runtime hook recreates incomplete stamped venv" {
	grep -q 'bin/python' "$TMPL"
	grep -q 'AI runtime venv is incomplete' "$TMPL"
	grep -q "rm -rf \"\${VENV_DIR}\"" "$TMPL"
}
