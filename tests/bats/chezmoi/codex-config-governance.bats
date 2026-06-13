#!/usr/bin/env bats
# Codex config governance: template render, defaults, private source, no inline secrets.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TMPL="${DOTFILES_DIR}/dot_codex/private_config.toml.tmpl"
	REPORT="${DOTFILES_DIR}/scripts/chezmoi-drift-report.sh"
}

_render_codex_config() {
	chezmoi --source="${DOTFILES_DIR}" execute-template <"${TMPL}"
}

@test "dot_codex private_config template renders as valid TOML" {
	skip_if_command_missing chezmoi
	skip_if_command_missing python3

	local rendered
	rendered="$(_render_codex_config)"
	[[ -n "${rendered}" ]]

	run python3 -c "
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
tomllib.loads(sys.stdin.read())
" <<<"${rendered}"
	[[ "${status}" -eq 0 ]]
}

@test "rendered Codex config contains default model gpt-5.5" {
	skip_if_command_missing chezmoi

	run _render_codex_config
	[[ "${status}" -eq 0 ]]
	[[ "${output}" =~ model\ =\ \"gpt-5\.5\" ]]
}

@test "rendered Codex config contains default model_reasoning_effort high" {
	skip_if_command_missing chezmoi

	run _render_codex_config
	[[ "${status}" -eq 0 ]]
	[[ "${output}" =~ model_reasoning_effort\ =\ \"high\" ]]
}

@test "rendered Codex config contains trust_level when data.codex.dotfiles_trust_level is set" {
	skip_if_command_missing chezmoi

	run _render_codex_config
	[[ "${status}" -eq 0 ]]
	[[ "${output}" =~ \[projects\.\" ]]
	[[ "${output}" =~ trust_level\ =\ \"trusted\" ]]
}

@test "dot_codex source uses private_ prefix for mode 600" {
	[[ -f "${TMPL}" ]]
	[[ ! -f "${DOTFILES_DIR}/dot_codex/config.toml.tmpl" ]]
	[[ ! -f "${DOTFILES_DIR}/dot_codex/.chezmoiattributes" ]]
}

@test "no legacy root codex config should exist" {
	[[ ! -f "${DOTFILES_DIR}/codex/config.toml" ]]
}

@test "chezmoi diff for Codex does not propose new mode 100644" {
	skip_if_command_missing chezmoi
	[[ -f "${HOME}/.codex/config.toml" ]] || skip "HOME Codex config absent"

	run chezmoi --source="${DOTFILES_DIR}" diff "${HOME}/.codex/config.toml"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *'new mode 100644'* ]]
}

@test "dot_codex config template has no obvious inline secrets" {
	assert_file_not_matches "${TMPL}" 'ghp_[A-Za-z0-9]'
	assert_file_not_matches "${TMPL}" 'sk-[A-Za-z0-9]'
	assert_file_not_matches "${TMPL}" 'BEGIN RSA PRIVATE'
	assert_file_not_matches "${TMPL}" 'BEGIN OPENSSH PRIVATE'
	assert_file_not_matches "${TMPL}" 'BEGIN PRIVATE'
}

@test "chezmoi-drift-report does not execute chezmoi apply" {
	run grep -E '^\s*chezmoi(\s|$).*apply' "${REPORT}"
	[[ "${status}" -eq 1 ]]
}
