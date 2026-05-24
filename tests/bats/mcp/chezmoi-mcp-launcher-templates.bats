#!/usr/bin/env bats
# Chezmoi-managed MCP launcher templates under dot_local/share/chezmoi/bin/

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	BIN="${DOTFILES_DIR}/bin"
	TMPL_DIR="${DOTFILES_DIR}/dot_local/share/chezmoi/bin"
	IGNORE="${DOTFILES_DIR}/.chezmoiignore"
}

bats_require_minimum_version 1.5.0

@test "four executable_mcp-*-launcher.tmpl templates exist" {
	for name in filesystem git gitnexus postgres; do
		f="${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl"
		[[ -f "$f" ]]
	done
}

@test ".chezmoiignore allows dot_local/share/chezmoi/bin" {
	[[ -f "$IGNORE" ]]
	grep -q '!.local/share/chezmoi/bin' "$IGNORE" || grep -q 'chezmoi/bin' "$IGNORE"
}

@test "bash -n passes for bin MCP launchers" {
	for name in filesystem git gitnexus postgres; do
		run bash -n "${BIN}/mcp-${name}-launcher"
		[[ "${status}" -eq 0 ]]
	done
}

@test "bash -n passes for chezmoi launcher templates" {
	for name in filesystem git gitnexus postgres; do
		run bash -n "${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl"
		[[ "${status}" -eq 0 ]]
	done
}

@test "templates do not embed obvious token patterns" {
	# Launchers must not ship secrets; only paths and env var names.
	for name in filesystem git gitnexus postgres; do
		f="${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl"
		run ! grep -qE 'ghp_[A-Za-z0-9]{10,}' "$f"
		run ! grep -qE 'sk-[A-Za-z0-9]{10,}' "$f"
	done
}

@test "git/gitnexus/postgres templates match bin copies (sync contract)" {
	for name in git gitnexus postgres; do
		diff -q "${BIN}/mcp-${name}-launcher" "${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl"
	done
}

@test "filesystem template uses portable chezmoi paths not hardcoded dotfiles user" {
	local f="${TMPL_DIR}/executable_mcp-filesystem-launcher.tmpl"
	run ! grep -qE '"/home/jesus/dotfiles"' "$f"
	grep -q '{{ \.chezmoi\.sourceDir }}' "$f"
	grep -q '{{ \.chezmoi\.homeDir }}' "$f"
	grep -q '{{ \.ai\.obsidian_vault_path }}' "$f"
}

@test "filesystem bin resolves roots without hardcoded dotfiles path" {
	local f="${BIN}/mcp-filesystem-launcher"
	run ! grep -qE '"/home/jesus/dotfiles"' "$f"
	grep -q 'MCP_DOTFILES_ROOT' "$f"
	grep -q '_resolve_dotfiles_root' "$f"
}
