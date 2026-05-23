#!/usr/bin/env bats
# Canonical skills live under ai/assets/skills only (no duplicate .claude/skills in repo).

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "gitnexus skills exist under ai/assets/skills" {
	[[ -d "${DOTFILES_DIR}/ai/assets/skills/gitnexus" ]]
	[[ -f "${DOTFILES_DIR}/ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md" ]]
}

@test "no duplicate .claude/skills tree in dotfiles repo" {
	[[ ! -d "${DOTFILES_DIR}/.claude/skills" ]]
}

@test "ai assets hook publishes canonical skills to Claude Code personal skills path" {
	local hook="${DOTFILES_DIR}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
	grep -q '{{ .chezmoi.homeDir }}/.claude/skills' "$hook"
	grep -q 'AGENT_DIRS=(' "$hook"
}

@test "rendered ai assets hook symlinks Claude Code skills to canonical source" {
	local fake_home="${TEST_TEMP_DIR}/home"
	local rendered="${TEST_TEMP_DIR}/link-ai-assets.sh"
	mkdir -p "$fake_home"

	sed \
		-e "s|{{ .chezmoi.sourceDir }}|${DOTFILES_DIR}|g" \
		-e "s|{{ .chezmoi.homeDir }}|${fake_home}|g" \
		"${DOTFILES_DIR}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" >"$rendered"

	run bash "$rendered"
	[[ "$status" -eq 0 ]]
	[[ -L "${fake_home}/.config/ai/skills" ]]
	[[ -L "${fake_home}/.claude/skills/gitnexus" ]]
	[[ "$(readlink -f "${fake_home}/.claude/skills/gitnexus")" == "${DOTFILES_DIR}/ai/assets/skills/gitnexus" ]]
}

@test "AGENTS.md references canonical gitnexus skill path" {
	grep -q 'ai/assets/skills/gitnexus/' "${DOTFILES_DIR}/AGENTS.md"
	run ! grep -q '\.claude/skills/gitnexus/' "${DOTFILES_DIR}/AGENTS.md"
}
