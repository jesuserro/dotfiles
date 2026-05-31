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

@test "validate-skills fails when a symlink exists under ai/assets/skills" {
	local fixture_root="${TEST_TEMP_DIR}/dotfiles-fixture"
	local category="${fixture_root}/ai/assets/skills/example"
	mkdir -p "${fixture_root}/scripts" "${category}"
	cp "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" "${fixture_root}/scripts/validate-skills-structure.sh"
	write_valid_skill "${category}/valid-skill"
	ln -sf "/tmp/external-skill" "${category}/external-link"

	run bash "${fixture_root}/scripts/validate-skills-structure.sh"

	[[ "$status" -eq 1 ]]
	[[ "$output" == *"Symlinks are not allowed under ai/assets/skills/"* ]]
	[[ "$output" == *"Validation FAILED"* ]]
}

@test "validate-skills fails when ai/assets/skills/mattpocock exists" {
	local fixture_root="${TEST_TEMP_DIR}/dotfiles-fixture"
	local category="${fixture_root}/ai/assets/skills/example"
	mkdir -p "${fixture_root}/scripts" "${category}" "${fixture_root}/ai/assets/skills/mattpocock/demo-skill"
	cp "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" "${fixture_root}/scripts/validate-skills-structure.sh"
	write_valid_skill "${category}/valid-skill"

	run bash "${fixture_root}/scripts/validate-skills-structure.sh"

	[[ "$status" -eq 1 ]]
	[[ "$output" == *"ai/assets/skills/mattpocock/ is not allowed"* ]]
	[[ "$output" == *"Validation FAILED"* ]]
}

@test "validate-skills passes governance checks on clean fixture tree" {
	local fixture_root="${TEST_TEMP_DIR}/dotfiles-fixture"
	local category="${fixture_root}/ai/assets/skills/example"
	mkdir -p "${fixture_root}/scripts" "${category}"
	cp "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" "${fixture_root}/scripts/validate-skills-structure.sh"
	write_valid_skill "${category}/valid-skill"

	run bash "${fixture_root}/scripts/validate-skills-structure.sh"

	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Governance checks"* ]]
	[[ "$output" == *"Validation PASSED"* ]]
}
