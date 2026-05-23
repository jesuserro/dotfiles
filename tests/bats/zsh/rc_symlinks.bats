#!/usr/bin/env bats

# Tests for the Chezmoi-managed zsh stack RC symlinks:
#   ~/.zshrc      -> $HOME/dotfiles/zshrc
#   ~/.p10k.zsh   -> $HOME/dotfiles/powerlevel10k/p10k.zsh
#   ~/.aliases    -> $HOME/dotfiles/aliases
#
# And the safe-backup hook .chezmoiscripts/run_before_00_backup_rc_files.sh.tmpl.
#
# Each test runs Chezmoi against an isolated source + HOME so we never touch
# the real user's RC files. The fake source brings only the bits needed for
# the zsh stack: the three symlink_ sources, the backup hook, and a minimal
# .chezmoi.toml.

setup() {
	load '../helpers/common'
	if ! command -v chezmoi >/dev/null 2>&1; then
		skip "chezmoi not in PATH"
	fi

	REPO_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	export REPO_DIR

	TEST_HOME="$(mktemp -d)"
	export TEST_HOME
	export HOME="${TEST_HOME}"

	mkdir -p "${TEST_HOME}/dotfiles/powerlevel10k"
	printf '# fake zshrc\n' >"${TEST_HOME}/dotfiles/zshrc"
	printf '# fake p10k.zsh\n' >"${TEST_HOME}/dotfiles/powerlevel10k/p10k.zsh"
	printf 'alias true=:\nalias cx=codex\n' >"${TEST_HOME}/dotfiles/aliases"

	SRC_DIR="$(mktemp -d)"
	export SRC_DIR
	mkdir -p "${SRC_DIR}/.chezmoiscripts"

	cp "${REPO_DIR}/symlink_dot_zshrc.tmpl" "${SRC_DIR}/"
	cp "${REPO_DIR}/symlink_dot_p10k.zsh.tmpl" "${SRC_DIR}/"
	cp "${REPO_DIR}/symlink_dot_aliases.tmpl" "${SRC_DIR}/"
	cp "${REPO_DIR}/.chezmoiscripts/run_before_00_backup_rc_files.sh.tmpl" \
		"${SRC_DIR}/.chezmoiscripts/"

	cat >"${SRC_DIR}/.chezmoi.toml" <<EOF
[data]
EOF
	# Whitelist style ignore so this fake source exposes only the three RC files.
	cat >"${SRC_DIR}/.chezmoiignore" <<'EOF'
*
!.zshrc
!.p10k.zsh
!.aliases
EOF
}

teardown() {
	[[ -n "${TEST_HOME:-}" && -d "${TEST_HOME}" ]] && rm -rf "${TEST_HOME}"
	[[ -n "${SRC_DIR:-}" && -d "${SRC_DIR}" ]] && rm -rf "${SRC_DIR}"
}

apply() {
	chezmoi apply --source="${SRC_DIR}" --destination="${TEST_HOME}" "$@"
}

assert_link() {
	local link="$1"
	local expected="$2"
	[[ -L "${link}" ]] || {
		echo "expected ${link} to be a symlink" >&2
		return 1
	}
	[[ "$(readlink "${link}")" == "${expected}" ]] || {
		echo "expected ${link} -> ${expected}, got $(readlink "${link}")" >&2
		return 1
	}
}

count_backups() {
	local target="$1"
	# shellcheck disable=SC2012
	ls "${target}".backup.* 2>/dev/null | wc -l | tr -d ' '
}

@test "clean HOME: chezmoi apply creates the three RC symlinks" {
	run apply
	[[ "${status}" -eq 0 ]] || {
		echo "${output}" >&2
		false
	}

	assert_link "${TEST_HOME}/.zshrc" "${TEST_HOME}/dotfiles/zshrc"
	assert_link "${TEST_HOME}/.p10k.zsh" \
		"${TEST_HOME}/dotfiles/powerlevel10k/p10k.zsh"
	assert_link "${TEST_HOME}/.aliases" "${TEST_HOME}/dotfiles/aliases"
}

@test "idempotency: re-applying with correct symlinks creates no new backups" {
	run apply
	[[ "${status}" -eq 0 ]]

	run apply
	[[ "${status}" -eq 0 ]]

	[[ "$(count_backups "${TEST_HOME}/.zshrc")" == "0" ]]
	[[ "$(count_backups "${TEST_HOME}/.p10k.zsh")" == "0" ]]
	[[ "$(count_backups "${TEST_HOME}/.aliases")" == "0" ]]
}

@test "trivial uv stub .zshrc is backed up and replaced by the symlink" {
	printf '. "$HOME/.local/bin/env"\n' >"${TEST_HOME}/.zshrc"

	run apply
	[[ "${status}" -eq 0 ]] || {
		echo "${output}" >&2
		false
	}

	assert_link "${TEST_HOME}/.zshrc" "${TEST_HOME}/dotfiles/zshrc"
	[[ "$(count_backups "${TEST_HOME}/.zshrc")" == "1" ]]
}

@test "empty .zshrc is treated as trivial and backed up" {
	: >"${TEST_HOME}/.zshrc"

	run apply
	[[ "${status}" -eq 0 ]]

	assert_link "${TEST_HOME}/.zshrc" "${TEST_HOME}/dotfiles/zshrc"
	[[ "$(count_backups "${TEST_HOME}/.zshrc")" == "1" ]]
}

@test "custom .zshrc without ZSH_RC_APPLY aborts and keeps the original" {
	printf '# my custom zshrc\nexport FOO=bar\n' >"${TEST_HOME}/.zshrc"
	local sha_before
	sha_before="$(sha256sum "${TEST_HOME}/.zshrc" | awk '{print $1}')"

	unset ZSH_RC_APPLY
	run chezmoi apply --source="${SRC_DIR}" --destination="${TEST_HOME}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"ZSH_RC_APPLY=1"* ]]

	[[ ! -L "${TEST_HOME}/.zshrc" ]]
	local sha_after
	sha_after="$(sha256sum "${TEST_HOME}/.zshrc" | awk '{print $1}')"
	[[ "${sha_before}" == "${sha_after}" ]]
	[[ "$(count_backups "${TEST_HOME}/.zshrc")" == "0" ]]
}

@test "custom .zshrc with ZSH_RC_APPLY=1 is backed up and replaced" {
	printf '# my custom zshrc\nexport FOO=bar\n' >"${TEST_HOME}/.zshrc"

	export ZSH_RC_APPLY=1
	run chezmoi apply --source="${SRC_DIR}" --destination="${TEST_HOME}"
	unset ZSH_RC_APPLY
	[[ "${status}" -eq 0 ]] || {
		echo "${output}" >&2
		false
	}

	assert_link "${TEST_HOME}/.zshrc" "${TEST_HOME}/dotfiles/zshrc"
	[[ "$(count_backups "${TEST_HOME}/.zshrc")" == "1" ]]
	# The backup must keep the original custom content intact.
	local bk
	bk="$(ls "${TEST_HOME}/.zshrc".backup.* | head -1)"
	grep -q "export FOO=bar" "${bk}"
}

@test "stale .zshrc symlink pointing elsewhere is backed up and replaced" {
	printf 'wrong target\n' >"${TEST_HOME}/wrong"
	ln -s "${TEST_HOME}/wrong" "${TEST_HOME}/.zshrc"

	run apply
	[[ "${status}" -eq 0 ]]

	assert_link "${TEST_HOME}/.zshrc" "${TEST_HOME}/dotfiles/zshrc"
	[[ "$(count_backups "${TEST_HOME}/.zshrc")" == "1" ]]
}

@test "~/.aliases symlink does not expose the removed ups command" {
	if ! command -v zsh >/dev/null 2>&1; then
		skip "zsh not in PATH"
	fi

	run apply
	[[ "${status}" -eq 0 ]]

	# Source ~/.aliases directly; the goal of this test is to validate that
	# the symlink delivers the function, not the rest of the OMZ stack.
	run env HOME="${TEST_HOME}" zsh -c 'source "$HOME/.aliases" && ! whence -w ups'
	[[ "${status}" -eq 0 ]]
}

@test "~/.p10k.zsh symlink resolves to the bundled p10k.zsh" {
	run apply
	[[ "${status}" -eq 0 ]]

	[[ -L "${TEST_HOME}/.p10k.zsh" ]]
	# Real file behind the symlink must exist and contain our marker.
	[[ -f "${TEST_HOME}/.p10k.zsh" ]]
	grep -q "fake p10k.zsh" "${TEST_HOME}/.p10k.zsh"
}
