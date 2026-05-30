#!/usr/bin/env bats

setup() {
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	P10K_CONFIG="${DOTFILES_DIR}/powerlevel10k/p10k.zsh"
	TEST_HOME="$(mktemp -d)"
	export TEST_HOME
}

teardown() {
	rm -rf "${TEST_HOME}"
}

@test "p10k config parses as zsh" {
	run zsh -n "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "p10k associative cache lookups are safe for path-like keys" {
	run grep -nE '\(\(.*\$\{\+_DOTFILES_P10K_(GH_REMOTE_OWNER|UPSTREAM_OWNER|GIT_AUTHOR)\[[^]]+\]\}' "${P10K_CONFIG}"
	[[ "${status}" -eq 1 ]]

	run grep -F '${_DOTFILES_P10K_GH_REMOTE_OWNER[$cache_key]+x}' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '${_DOTFILES_P10K_UPSTREAM_OWNER[$root]+x}' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '${_DOTFILES_P10K_GIT_AUTHOR[$root]+x}' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "p10k cache clearing preserves associative array types" {
	run grep -F 'unset _DOTFILES_P10K_GH_REMOTE_OWNER' "${P10K_CONFIG}"
	[[ "${status}" -eq 1 ]]
	run grep -F 'unset _DOTFILES_P10K_UPSTREAM_OWNER' "${P10K_CONFIG}"
	[[ "${status}" -eq 1 ]]
	run grep -F 'unset _DOTFILES_P10K_GIT_AUTHOR' "${P10K_CONFIG}"
	[[ "${status}" -eq 1 ]]

	run grep -F '_DOTFILES_P10K_GH_REMOTE_OWNER=()' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '_DOTFILES_P10K_UPSTREAM_OWNER=()' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '_DOTFILES_P10K_GIT_AUTHOR=()' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]
	run grep -F '_DOTFILES_P10K_GIT_AUTHOR_AGENT=()' "${P10K_CONFIG}"
	[[ "${status}" -eq 0 ]]

	run env HOME="${TEST_HOME}" P10K_CONFIG="${P10K_CONFIG}" zsh -fc '
		source "$P10K_CONFIG"
		local key="/tmp/some path/dotfiles::origin"
		_DOTFILES_P10K_GH_REMOTE_OWNER[$key]=before
		_DOTFILES_P10K_UPSTREAM_OWNER[/tmp/some\ path/dotfiles]=before
		_DOTFILES_P10K_GIT_AUTHOR[/tmp/some\ path/dotfiles]=before
		_DOTFILES_P10K_GIT_AUTHOR_AGENT[/tmp/some\ path/dotfiles]=1
		_dotfiles_p10k_clear_git_prompt_cache
		typeset -p _DOTFILES_P10K_GH_REMOTE_OWNER _DOTFILES_P10K_UPSTREAM_OWNER \
			_DOTFILES_P10K_GIT_AUTHOR _DOTFILES_P10K_GIT_AUTHOR_AGENT
		_DOTFILES_P10K_GH_REMOTE_OWNER[$key]=after
		_DOTFILES_P10K_UPSTREAM_OWNER[/tmp/some\ path/dotfiles]=after
		_DOTFILES_P10K_GIT_AUTHOR[/tmp/some\ path/dotfiles]=after
		_DOTFILES_P10K_GIT_AUTHOR_AGENT[/tmp/some\ path/dotfiles]=1
	'
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"typeset -A _DOTFILES_P10K_GH_REMOTE_OWNER"* ]]
	[[ "${output}" == *"typeset -A _DOTFILES_P10K_UPSTREAM_OWNER"* ]]
	[[ "${output}" == *"typeset -A _DOTFILES_P10K_GIT_AUTHOR"* ]]
	[[ "${output}" == *"typeset -A _DOTFILES_P10K_GIT_AUTHOR_AGENT"* ]]
	[[ "${output}" != *"bad math expression"* ]]
}

@test "20-omz loads Powerlevel10k only via ~/.p10k.zsh" {
	run zsh -n "${DOTFILES_DIR}/zsh/20-omz.zsh"
	[[ "${status}" -eq 0 ]]
	run grep -c 'source.*\.p10k\.zsh' "${DOTFILES_DIR}/zsh/20-omz.zsh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" -eq 1 ]]
	run grep -E 'source.*dotfiles/powerlevel10k' "${DOTFILES_DIR}/zsh/20-omz.zsh"
	[[ "${status}" -ne 0 ]]
}
