#!/usr/bin/env bats
# Canonical skills live under ai/assets/skills only (no duplicate .claude/skills in repo).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
}

@test "gitnexus skills exist under ai/assets/skills" {
	[[ -d "${DOTFILES_DIR}/ai/assets/skills/gitnexus" ]]
	[[ -f "${DOTFILES_DIR}/ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md" ]]
}

@test "no duplicate .claude/skills tree in dotfiles repo" {
	[[ ! -d "${DOTFILES_DIR}/.claude/skills" ]]
}

@test "AGENTS.md references canonical gitnexus skill path" {
	grep -q 'ai/assets/skills/gitnexus/' "${DOTFILES_DIR}/AGENTS.md"
	! grep -q '\.claude/skills/gitnexus/' "${DOTFILES_DIR}/AGENTS.md"
}
