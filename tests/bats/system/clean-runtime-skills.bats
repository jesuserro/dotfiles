#!/usr/bin/env bats
# clean-runtime-skills: dry-run by default, prune only broken symlinks on double confirmation.

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/clean-runtime-skills.sh"
	HOME_DIR="${TEST_TEMP_DIR}/home"
	mkdir -p "${HOME_DIR}"
}

teardown() {
	teardown_temp_dir
}

@test "missing roots do not fail" {
	run env HOME="${HOME_DIR}" bash "${SCRIPT}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MISSING-ROOT: ${HOME_DIR}/.claude/skills"* ]]
	[[ "${output}" == *"MISSING-ROOT: ${HOME_DIR}/.config/opencode/skills"* ]]
}

@test "dry-run detects broken symlink and does not delete it" {
	local root="${HOME_DIR}/.claude/skills"
	mkdir -p "${root}"
	ln -s "${HOME_DIR}/missing-target" "${root}/broken"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"BROKEN-SYMLINK: ${root}/broken"* ]]
	[[ "${output}" == *"DRY-RUN"* ]]
	[[ -L "${root}/broken" ]]
}

@test "--prune-broken-symlinks without --yes does not delete" {
	local root="${HOME_DIR}/.claude/skills"
	mkdir -p "${root}"
	ln -s "${HOME_DIR}/missing-target" "${root}/broken"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --prune-broken-symlinks
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"WOULD-PRUNE: ${root}/broken"* ]]
	[[ -L "${root}/broken" ]]
}

@test "--yes without prune does not delete" {
	local root="${HOME_DIR}/.claude/skills"
	mkdir -p "${root}"
	ln -s "${HOME_DIR}/missing-target" "${root}/broken"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --yes
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY-RUN"* ]]
	[[ -L "${root}/broken" ]]
}

@test "double confirmation prunes only broken symlink" {
	local root="${HOME_DIR}/.claude/skills"
	local target="${HOME_DIR}/valid-target"
	mkdir -p "${root}" "${target}"
	ln -s "${HOME_DIR}/missing-target" "${root}/broken"
	ln -s "${target}" "${root}/valid"
	printf 'keep\n' >"${root}/regular-file"
	mkdir -p "${root}/regular-dir"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --prune-broken-symlinks --yes
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"PRUNED: ${root}/broken"* ]]
	[[ ! -e "${root}/broken" && ! -L "${root}/broken" ]]
	[[ -L "${root}/valid" ]]
	[[ -f "${root}/regular-file" ]]
	[[ -d "${root}/regular-dir" ]]
}

@test "opencode root is scanned and valid symlink is conserved" {
	local root="${HOME_DIR}/.config/opencode/skills"
	local target="${HOME_DIR}/skill-target"
	mkdir -p "${root}" "${target}"
	ln -s "${target}" "${root}/valid"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --prune-broken-symlinks --yes
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"VALID-SYMLINK: ${root}/valid"* ]]
	[[ -L "${root}/valid" ]]
}

@test "root symlink is not deleted" {
	local parent="${HOME_DIR}/.claude"
	local target="${HOME_DIR}/actual-skills"
	mkdir -p "${parent}" "${target}"
	ln -s "${target}" "${parent}/skills"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --prune-broken-symlinks --yes
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"ROOT-SYMLINK: ${parent}/skills"* ]]
	[[ -L "${parent}/skills" ]]
}

@test "path outside roots is not touched" {
	local root="${HOME_DIR}/.claude/skills"
	local outside="${HOME_DIR}/outside-broken"
	mkdir -p "${root}"
	ln -s "${HOME_DIR}/missing-outside" "${outside}"

	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --prune-broken-symlinks --yes
	[[ "${status}" -eq 0 ]]
	[[ -L "${outside}" ]]
}

@test "unknown flag fails with help" {
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --wat
	[[ "${status}" -eq 2 ]]
	[[ "${output}" == *"Usage: clean-runtime-skills"* ]]
}

@test "target Make exists and make update does not reference cleaner" {
	run make -n -C "${DOTFILES_DIR}" clean-runtime-skills
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"scripts/clean-runtime-skills.sh --dry-run"* ]]

	run make -n -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"clean-runtime-skills"* ]]
}
