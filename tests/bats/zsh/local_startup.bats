#!/usr/bin/env bats
# zsh/90-local.zsh: no global MCP secrets in interactive shells.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	LOCAL_ZSH="${DOTFILES_DIR}/zsh/90-local.zsh"
}

@test "90-local.zsh exists" {
	[[ -f "${LOCAL_ZSH}" ]]
}

@test "90-local.zsh does not source codex.env unconditionally" {
	run grep -E '^\[\[ -f "\$HOME/\.secrets/codex\.env" \]\] && source' "${LOCAL_ZSH}"
	[[ "${status}" -eq 1 ]]
}

@test "90-local.zsh only sources codex.env behind DOTFILES_SOURCE_MCP_SECRETS opt-in" {
	grep -q 'DOTFILES_SOURCE_MCP_SECRETS' "${LOCAL_ZSH}"
	grep -q 'if \[\[ -n "\${DOTFILES_SOURCE_MCP_SECRETS:-}"' "${LOCAL_ZSH}"
	grep -q 'source "$HOME/.secrets/codex.env"' "${LOCAL_ZSH}"
	run grep -E '^\[\[ -f "\$HOME/\.secrets/codex\.env" \]\] && source' "${LOCAL_ZSH}"
	[[ "${status}" -eq 1 ]]
}

@test "90-local.zsh documents gh auth switch precedence" {
	grep -q 'gh auth switch' "${LOCAL_ZSH}"
}

@test "interactive zsh startup does not export GH_TOKEN from dotfiles modules" {
	skip_if_command_missing "zsh"

	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/dotfiles/zsh" "${fake_home}/.cache"
	cp "${DOTFILES_DIR}/zshrc" "${fake_home}/dotfiles/zshrc"
	cp "${DOTFILES_DIR}/zsh/"*.zsh "${fake_home}/dotfiles/zsh/"

	# Stub modules that may probe external paths; 90-local is the real file under test.
	for stub in 00-env 10-path 20-omz 25-zoxide 26-fzf 30-python 50-aliases-dotfiles 55-aliases-azure; do
		printf '# stub\n' >"${fake_home}/dotfiles/zsh/${stub}.zsh"
	done

	run env -u GH_TOKEN -u GITHUB_TOKEN -u GITHUB_PERSONAL_ACCESS_TOKEN \
		HOME="${fake_home}" zsh -fc '
		source "$HOME/dotfiles/zshrc"
		env | grep -E "^(GH_TOKEN|GITHUB_TOKEN)=" && exit 1 || exit 0
	'
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
}
