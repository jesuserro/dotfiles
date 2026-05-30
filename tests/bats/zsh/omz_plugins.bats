#!/usr/bin/env bats

# Validates the Oh My Zsh plugin list in zsh/20-omz.zsh (source of truth).

setup() {
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	OMZ_CONFIG="${DOTFILES_DIR}/zsh/20-omz.zsh"
}

extract_plugins_block() {
	awk '/^plugins=\(/,/^\)/' "${OMZ_CONFIG}"
}

@test "20-omz.zsh parses with zsh -n" {
	run zsh -n "${OMZ_CONFIG}"
	[[ "${status}" -eq 0 ]]
}

@test "plugins array contains expected entries" {
	local block expected
	block="$(extract_plugins_block)"
	expected=(
		autoupdate azure chezmoi colored-man-pages colorize command-not-found
		debian dirhistory docker docker-compose extract gh git gitignore history
		jsontools npm python rsync systemd tmux urltools uv virtualenv vi-mode z
		zsh-autosuggestions zsh-completions zsh-history-substring-search
		zsh-syntax-highlighting
	)
	for plugin in "${expected[@]}"; do
		echo "$block" | grep -qE "^[[:space:]]+${plugin}[[:space:]]*$" || {
			echo "missing plugin: ${plugin}" >&2
			false
		}
	done
}

@test "plugins array excludes rejected runtime and legacy plugins" {
	local block rejected plugin
	block="$(extract_plugins_block)"
	rejected=(aws composer wp-cli postgres nvm pyenv asdf conda autoenv pip)
	for plugin in "${rejected[@]}"; do
		if echo "$block" | grep -qE "^[[:space:]]+${plugin}[[:space:]]*$"; then
			echo "unexpected plugin: ${plugin}" >&2
			false
		fi
	done
}

@test "zsh-syntax-highlighting is the last plugin in the array" {
	local last
	last="$(extract_plugins_block | grep -E '^[[:space:]]+[a-z0-9-]+[[:space:]]*$' | tail -1 | tr -d '[:space:]')"
	[[ "${last}" == "zsh-syntax-highlighting" ]]
}
