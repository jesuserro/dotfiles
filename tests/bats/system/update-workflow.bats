#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "update scripts pass bash syntax checks" {
	run bash -n "${DOTFILES_DIR}/scripts/update/update.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-projects.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh"
	[[ "${status}" -eq 0 ]]
}

@test "Make exposes public update and Excalidraw targets" {
	for target in update update-windows update-wsl update-projects update-check excalidraw-start excalidraw-stop excalidraw-status excalidraw-update; do
		run make -n -C "${DOTFILES_DIR}" "$target"
		[[ "${status}" -eq 0 ]]
	done
}

@test "make update mock run records Windows warning and excludes projects" {
	run env DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"mocked winget warning"* ]]
	[[ "${output}" == *"Personal projects are not part of make update"* ]]
	[[ -f "${TEST_TEMP_DIR}/run/windows-results.tsv" ]]
	[[ -f "${TEST_TEMP_DIR}/run/wsl-results.tsv" ]]
}

@test "update PowerShell script invokes wsl --update and never wsl --shutdown" {
	grep -q 'wsl --update' "${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	! grep -Eq '^.*Run-Logged.*wsl --shutdown|^[[:space:]]*wsl --shutdown' "${DOTFILES_DIR}/scripts/update/update-windows.ps1"
}

@test "ups command is absent from aliases and Make targets" {
	run grep -Eq '(^|[[:space:]])ups\\(\\)' "${DOTFILES_DIR}/aliases"
	[[ "${status}" -ne 0 ]]
	run grep -Eq '^ups:' "${DOTFILES_DIR}/Makefile" "${DOTFILES_DIR}"/*.mk
	[[ "${status}" -ne 0 ]]
}
