#!/usr/bin/env bats
# Static tests for bin/tmux-dotfiles

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	LAUNCHER="${DOTFILES_DIR}/bin/tmux-dotfiles"
}

bats_require_minimum_version 1.5.0

@test "launcher script exists and is executable" {
	[[ -f "$LAUNCHER" ]]
	[[ -x "$LAUNCHER" ]]
}

@test "script uses set -euo pipefail" {
	grep -q 'set -euo pipefail' "$LAUNCHER"
}

@test "script defines dotfiles session name" {
	grep -q 'SESSION_NAME="dotfiles"' "$LAUNCHER"
	grep -q 'dotfiles' "$LAUNCHER"
}

@test "script uses tmux has-session for idempotence" {
	grep -q 'tmux has-session' "$LAUNCHER"
}

@test "script uses tmux new-session" {
	grep -q 'tmux new-session' "$LAUNCHER"
}

@test "script uses tmux split-window -h for two columns" {
	grep -q 'tmux split-window -h' "$LAUNCHER"
}

@test "script uses tmux attach-session or tmux switch-client" {
	grep -Eq 'tmux attach-session|tmux switch-client' "$LAUNCHER"
}

@test "help flag -h shows usage" {
	run bash "$LAUNCHER" -h
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"dotfiles"* ]]
	[[ "$output" == *"Ctrl+b"* ]]
	[[ "$output" == *"Detach"* ]]
}

@test "help flag --help shows usage" {
	run bash "$LAUNCHER" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"dotfiles"* ]]
}

@test "script does not contain legacy project paths" {
	! grep -qiE 'ofertas|localidades|nges|cdrst|/var/www' "$LAUNCHER"
}

@test "legacy tmux scripts were removed" {
	[[ ! -f "${DOTFILES_DIR}/tmux/ofertas.sh" ]]
	[[ ! -f "${DOTFILES_DIR}/tmux/localidades.sh" ]]
	[[ ! -f "${DOTFILES_DIR}/tmux/nges.sh" ]]
}

@test "legacy tmux scripts document shellcheck sources" {
	grep -q '# shellcheck source=tmux/common/header.sh' "${DOTFILES_DIR}/tmux/home.sh"
	grep -q '# shellcheck source=tmux/common/footer.sh' "${DOTFILES_DIR}/tmux/home.sh"
	grep -q '# shellcheck source=tmux/common/header.sh' "${DOTFILES_DIR}/tmux/work.sh"
	grep -q '# shellcheck source=tmux/common/footer.sh' "${DOTFILES_DIR}/tmux/work.sh"
}

@test "chezmoi symlink template exists for tmux.conf" {
	[[ -f "${DOTFILES_DIR}/symlink_dot_tmux.conf.tmpl" ]]
	grep -q '{{ .chezmoi.homeDir }}/dotfiles/tmux.conf' "${DOTFILES_DIR}/symlink_dot_tmux.conf.tmpl"
}

@test "chezmoi hook publishes tmux-dotfiles to local bin" {
	local tmpl="${DOTFILES_DIR}/.chezmoiscripts/run_after_15_link_tmux_dotfiles.sh.tmpl"
	[[ -f "$tmpl" ]]
	grep -q 'ln -sf' "$tmpl"
	grep -q 'bin/tmux-dotfiles' "$tmpl"
	grep -q '\.local/bin' "$tmpl"
	grep -q 'LOCAL_BIN}/tmux-dotfiles' "$tmpl"
}
