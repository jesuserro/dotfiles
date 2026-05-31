#!/usr/bin/env bats
# AGENTS.md / CLAUDE.md: GitNexus generated blocks align with operational policy.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	AGENTS="${DOTFILES_DIR}/AGENTS.md"
	CLAUDE="${DOTFILES_DIR}/CLAUDE.md"
}

extract_gitnexus_block() {
	local file="$1"
	awk '/<!-- gitnexus:start -->/,/<!-- gitnexus:end -->/' "$file"
}

@test "AGENTS.md and CLAUDE.md contain gitnexus section markers" {
	grep -q '<!-- gitnexus:start -->' "${AGENTS}"
	grep -q '<!-- gitnexus:end -->' "${AGENTS}"
	grep -q '<!-- gitnexus:start -->' "${CLAUDE}"
	grep -q '<!-- gitnexus:end -->' "${CLAUDE}"
}

@test "AGENTS.md gitnexus block does not recommend npx gitnexus analyze" {
	local block
	block="$(extract_gitnexus_block "${AGENTS}")"
	[[ -n "${block}" ]]
	run grep -F 'npx gitnexus analyze' <<<"${block}"
	[[ "${status}" -eq 1 ]]
}

@test "CLAUDE.md gitnexus block does not recommend npx gitnexus analyze" {
	local block
	block="$(extract_gitnexus_block "${CLAUDE}")"
	[[ -n "${block}" ]]
	run grep -F 'npx gitnexus analyze' <<<"${block}"
	[[ "${status}" -eq 1 ]]
}

@test "AGENTS.md gitnexus block mentions make gitnexus-status" {
	local block
	block="$(extract_gitnexus_block "${AGENTS}")"
	grep -q 'make gitnexus-status' <<<"${block}"
}

@test "CLAUDE.md gitnexus block mentions make gitnexus-status" {
	local block
	block="$(extract_gitnexus_block "${CLAUDE}")"
	grep -q 'make gitnexus-status' <<<"${block}"
}

@test "AGENTS.md gitnexus block references operational policy" {
	local block
	block="$(extract_gitnexus_block "${AGENTS}")"
	grep -q 'GITNEXUS_OPERATIONAL_POLICY.md' <<<"${block}"
}

@test "CLAUDE.md gitnexus block references operational policy" {
	local block
	block="$(extract_gitnexus_block "${CLAUDE}")"
	grep -q 'GITNEXUS_OPERATIONAL_POLICY.md' <<<"${block}"
}

@test "AGENTS.md preserves human Vault Project Wiki section outside block" {
	local after_block
	after_block="$(awk '/<!-- gitnexus:end -->/,0' "${AGENTS}" | tail -n +2)"
	grep -q 'Vault Project Wiki' <<<"${after_block}"
}

@test "gitnexus blocks reference ai/assets/skills not .claude/skills" {
	local agents_block claude_block
	agents_block="$(extract_gitnexus_block "${AGENTS}")"
	claude_block="$(extract_gitnexus_block "${CLAUDE}")"
	grep -q 'ai/assets/skills/gitnexus' <<<"${agents_block}"
	grep -q 'ai/assets/skills/gitnexus' <<<"${claude_block}"
	run grep -F '.claude/skills' <<<"${agents_block}"
	[[ "${status}" -eq 1 ]]
	run grep -F '.claude/skills' <<<"${claude_block}"
	[[ "${status}" -eq 1 ]]
}
