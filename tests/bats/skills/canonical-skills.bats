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
	[[ ! -d "${DOTFILES_DIR}/.claude" ]]
}

@test "gitignore blocks checkout-local .claude runtime surface" {
	grep -qE '^\.claude/?$' "${DOTFILES_DIR}/.gitignore"
}

@test "agent-validate guard rejects checkout .claude with remediation hint" {
	local script="${DOTFILES_DIR}/scripts/agent-validate-dotfiles.sh"
	grep -q 'guard_checkout_ai_surface' "${script}"
	grep -q 'checkout AI surface guard' "${script}"
	grep -q 'rm -rf' "${script}"
	grep -q 'ADR 0004' "${script}"
}

@test "validate-skills-structure fails when fixture has .claude/skills" {
	local fixture_root="${TEST_TEMP_DIR}/dotfiles-fixture"
	local category="${fixture_root}/ai/assets/skills/example"
	mkdir -p "${fixture_root}/scripts" "${category}/valid-skill" "${fixture_root}/.claude/skills/gitnexus"
	cp "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" "${fixture_root}/scripts/validate-skills-structure.sh"
	cat >"${category}/valid-skill/SKILL.md" <<'EOF'
# Fixture Skill

## Guidelines

Line 1
Line 2
Line 3
Line 4
Line 5
Line 6
Line 7
Line 8
Line 9
Line 10
Line 11
Line 12
EOF

	run bash "${fixture_root}/scripts/validate-skills-structure.sh"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"non-canonical skills directory found: .claude/skills"* ]]
}

@test "ai assets hook publishes canonical skills to Claude Code personal skills path" {
	local hook="${DOTFILES_DIR}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
	grep -q 'HOME_DIR="{{ .chezmoi.homeDir }}"' "$hook"
	grep -q '"${HOME_DIR}/.claude/skills"' "$hook"
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

@test "rendered ai assets hook refuses to create agent skills inside source checkout" {
	local fixture_root="${TEST_TEMP_DIR}/dotfiles-fixture"
	local rendered="${TEST_TEMP_DIR}/link-ai-assets-repo-local.sh"
	mkdir -p "${fixture_root}/.chezmoiscripts" "${fixture_root}/scripts/lib" "${fixture_root}/ai/assets/skills/example-skill"
	cp "${DOTFILES_DIR}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" "${fixture_root}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
	cp "${DOTFILES_DIR}/scripts/lib/install_common.sh" "${fixture_root}/scripts/lib/install_common.sh"
	touch "${fixture_root}/ai/assets/skills/example-skill/SKILL.md"

	sed \
		-e "s|{{ .chezmoi.sourceDir }}|${fixture_root}|g" \
		-e "s|{{ .chezmoi.homeDir }}|${fixture_root}|g" \
		"${fixture_root}/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" >"$rendered"

	run bash "$rendered"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"refusing to materialize AI assets inside dotfiles checkout"* ]]
	[[ ! -e "${fixture_root}/.claude/skills" ]]
	[[ ! -e "${fixture_root}/.config/ai" ]]
}

@test "AGENTS.md references canonical gitnexus skill path" {
	grep -q 'ai/assets/skills/gitnexus/' "${DOTFILES_DIR}/AGENTS.md"
	assert_file_not_matches "${DOTFILES_DIR}/AGENTS.md" '\.claude/skills/gitnexus/'
}

@test "Matt Pocock skills are documented as external fallback only" {
	[[ -f "${DOTFILES_DIR}/ai/assets/external-skills/mattpocock/POLICY.md" ]]
	[[ -f "${DOTFILES_DIR}/ai/assets/external-skills/mattpocock/selected-skills.md" ]]
	[[ ! -d "${DOTFILES_DIR}/ai/assets/skills/mattpocock" ]]
	grep -q 'Prefer local dotfiles skills under `ai/assets/skills/`' "${DOTFILES_DIR}/ai/assets/external-skills/mattpocock/POLICY.md"
	grep -q 'When a local skill and a Matt skill overlap, the local skill wins' "${DOTFILES_DIR}/ai/assets/external-skills/mattpocock/POLICY.md"
	grep -q 'full `mattpocock/skills` catalog' "${DOTFILES_DIR}/ai/assets/external-skills/mattpocock/selected-skills.md"
	grep -q 'npx skills add mattpocock/skills -y -g' "${DOTFILES_DIR}/ai/assets/external-skills/mattpocock/selected-skills.md"
}
