#!/usr/bin/env bats

# Validates zoxide module and OMZ z removal (no coexistence with plugin z).

setup() {
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	ZOXIDE_CONFIG="${DOTFILES_DIR}/zsh/25-zoxide.zsh"
	OMZ_CONFIG="${DOTFILES_DIR}/zsh/20-omz.zsh"
}

extract_plugins_block() {
	awk '/^plugins=\(/,/^\)/' "${OMZ_CONFIG}"
}

@test "25-zoxide.zsh parses with zsh -n" {
	run zsh -n "${ZOXIDE_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "25-zoxide.zsh uses conditional zoxide init" {
	run grep -F 'command -v zoxide' "${ZOXIDE_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F 'zoxide init zsh' "${ZOXIDE_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "25-zoxide.zsh does not define OMZ plugins array" {
	run grep -E 'plugins=\(' "${ZOXIDE_CONFIG}"
	[[ "${status}" -eq 1 ]]
}

@test "20-omz.zsh plugins array does not include z" {
	local block
	block="$(extract_plugins_block)"
	if echo "$block" | grep -qE '^[[:space:]]+z[[:space:]]*$'; then
		echo "unexpected plugin: z" >&2
		false
	fi
}

@test "sourcing 25-zoxide.zsh succeeds when zoxide is not in PATH" {
	local stub_dir="${BATS_TMPDIR}/zoxide-path-stub-$$"
	mkdir -p "$stub_dir"
	run env PATH="${stub_dir}:/usr/bin:/bin" zsh -fc "source '${ZOXIDE_CONFIG}'; true"
	[[ "${status}" -eq 0 ]]
}
