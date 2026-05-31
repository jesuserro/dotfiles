#!/usr/bin/env bats
# Focused tests for validate-skills-structure.sh.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

write_valid_skill() {
	local skill_dir="$1"
	mkdir -p "$skill_dir"
	cat >"${skill_dir}/SKILL.md" <<'EOF'
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
}

@test "validate-skills skips internal dirs without SKILL.md or recursion" {
	local fixture_root="${TEST_TEMP_DIR}/dotfiles-fixture"
	local category="${fixture_root}/ai/assets/skills/example"
	mkdir -p "${fixture_root}/scripts" "${category}/templates/nested" "${category}/.venv/nested"
	cp "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" "${fixture_root}/scripts/validate-skills-structure.sh"
	write_valid_skill "${category}/valid-skill"

	run bash "${fixture_root}/scripts/validate-skills-structure.sh"

	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Validation PASSED"* ]]
	[[ "$output" != *"templates"* ]]
	[[ "$output" != *".venv"* ]]
	[[ "$output" != *"No SKILL.md found"* ]]
}
