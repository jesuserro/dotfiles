#!/usr/bin/env bats

# Validates fzf module: conditional APT shell integration without hard dependency.

setup() {
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	FZF_CONFIG="${DOTFILES_DIR}/zsh/26-fzf.zsh"
}

@test "26-fzf.zsh parses with zsh -n" {
	run zsh -n "${FZF_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "26-fzf.zsh uses conditional fzf guard" {
	run grep -F 'command -v fzf' "${FZF_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "26-fzf.zsh sources APT example scripts when readable" {
	run grep -F '/usr/share/doc/fzf/examples/key-bindings.zsh' "${FZF_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '/usr/share/doc/fzf/examples/completion.zsh' "${FZF_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '[[ -r "$fzf_script" ]]' "${FZF_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "26-fzf.zsh does not define OMZ plugins array" {
	run grep -E 'plugins=\(' "${FZF_CONFIG}"
	[[ "${status}" -eq 1 ]]
}

@test "sourcing 26-fzf.zsh succeeds when fzf is not in PATH" {
	local stub_dir="${BATS_TMPDIR}/fzf-path-stub-$$"
	mkdir -p "$stub_dir"
	run env PATH="${stub_dir}:/usr/bin:/bin" zsh -fc "source '${FZF_CONFIG}'; true"
	[[ "${status}" -eq 0 ]]
}

@test "zshrc registers 26-fzf.zsh after zoxide and before python module" {
	run grep -F '25-zoxide.zsh' "${DOTFILES_DIR}/zshrc"
	[[ "${status}" -eq 0 ]]
	run grep -F '26-fzf.zsh' "${DOTFILES_DIR}/zshrc"
	[[ "${status}" -eq 0 ]]
	run grep -F '30-python.zsh' "${DOTFILES_DIR}/zshrc"
	[[ "${status}" -eq 0 ]]
}
