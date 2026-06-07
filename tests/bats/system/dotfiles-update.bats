#!/usr/bin/env bats
# Global dotfiles-update launcher: delegates to make update from any directory.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	LAUNCHER="${DOTFILES_DIR}/bin/dotfiles-update"
	TMPL="${DOTFILES_DIR}/dot_local/bin/symlink_dotfiles-update.tmpl"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

bats_require_minimum_version 1.5.0

@test "bin/dotfiles-update exists" {
	[[ -f "$LAUNCHER" ]]
}

@test "bin/dotfiles-update is executable" {
	[[ -x "$LAUNCHER" ]]
}

@test "script uses set -euo pipefail" {
	grep -q 'set -euo pipefail' "$LAUNCHER"
}

@test "script delegates with exec make update" {
	grep -q 'exec make update "$@"' "$LAUNCHER"
}

@test "fails when DOTFILES_DIR does not exist" {
	local missing="${TEST_TEMP_DIR}/missing-dotfiles"
	run env DOTFILES_DIR="$missing" bash "$LAUNCHER"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"dotfiles directory not found"* ]]
}

@test "fails when DOTFILES_DIR has no Makefile" {
	local no_makefile="${TEST_TEMP_DIR}/no-makefile"
	mkdir -p "$no_makefile"
	run env DOTFILES_DIR="$no_makefile" bash "$LAUNCHER"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"Makefile not found"* ]]
}

@test "runs from outside the repo via DOTFILES_DIR fixture" {
	local fixture="${TEST_TEMP_DIR}/fixture"
	mkdir -p "$fixture"
	cat >"$fixture/Makefile" <<'EOF'
update:
	@pwd > invoked.pwd
EOF
	cd /tmp
	run env DOTFILES_DIR="$fixture" bash "$LAUNCHER"
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$fixture/invoked.pwd")" == "$fixture" ]]
}

@test "propagates Make variables to update target" {
	local fixture="${TEST_TEMP_DIR}/fixture-vars"
	mkdir -p "$fixture"
	cat >"$fixture/Makefile" <<'EOF'
update:
	@pwd > invoked.pwd
	@echo "FOO=$(FOO)" > invoked.args
EOF
	cd /tmp
	run env DOTFILES_DIR="$fixture" bash "$LAUNCHER" FOO=bar
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$fixture/invoked.pwd")" == "$fixture" ]]
	[[ "$(cat "$fixture/invoked.args")" == "FOO=bar" ]]
}

@test "propagates make update failure as non-zero exit" {
	local fixture="${TEST_TEMP_DIR}/fixture-fail"
	mkdir -p "$fixture"
	cat >"$fixture/Makefile" <<'EOF'
update:
	@exit 42
EOF
	cd /tmp
	run env DOTFILES_DIR="$fixture" bash "$LAUNCHER"
	# GNU make reports recipe failures as exit 2, not the recipe's own code.
	[[ "$status" -eq 2 ]]
}

@test "chezmoi symlink template exists" {
	[[ -f "$TMPL" ]]
}

@test "chezmoi symlink template points to bin/dotfiles-update" {
	[[ "$(cat "$TMPL")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/dotfiles-update' ]]
}
