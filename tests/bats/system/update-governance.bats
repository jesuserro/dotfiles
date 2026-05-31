#!/usr/bin/env bats
# make update governance boundaries: no Chezmoi apply, no Matt Skills in daily flow.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	UPDATE_MK="${DOTFILES_DIR}/update.mk"
	UPDATE_SH="${DOTFILES_DIR}/scripts/update/update.sh"
	UPDATE_WSL="${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	UPDATE_WINDOWS="${DOTFILES_DIR}/scripts/update/update-windows.sh"
	UPDATE_CHECK="${DOTFILES_DIR}/scripts/update/update-check.sh"
}

assert_bash_script_no_chezmoi_apply() {
	local file="$1"
	run grep -E '^\s*chezmoi(\s|$).*apply' "$file"
	[[ "${status}" -eq 1 ]]
	run grep -E '^\s*DOTFILES_APPLY=1' "$file"
	[[ "${status}" -eq 1 ]]
	assert_file_not_matches "$file" 'chezmoi --source=[^#]*apply'
}

assert_bash_script_no_matt_skills_install() {
	local file="$1"
	assert_file_not_matches "$file" 'install-agent-skills\.sh'
	assert_file_not_matches "$file" 'install-mattpocock-skills'
	assert_file_not_matches "$file" 'npx skills'
	assert_file_not_matches "$file" 'mattpocock/skills'
}

@test "update scripts do not run chezmoi apply" {
	local file
	for file in "${UPDATE_SH}" "${UPDATE_WSL}" "${UPDATE_WINDOWS}"; do
		assert_bash_script_no_chezmoi_apply "$file"
	done
}

@test "update.mk primary targets do not invoke chezmoi apply" {
	run grep -E 'chezmoi(\s|$).*apply' "${UPDATE_MK}"
	[[ "${status}" -eq 1 ]]
	run grep 'DOTFILES_APPLY' "${UPDATE_MK}"
	[[ "${status}" -eq 1 ]]
}

@test "make -n update does not reference chezmoi apply" {
	run make -n -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"scripts/update/update.sh"* ]]
	[[ "${output}" != *"chezmoi"* ]]
}

@test "update scripts do not install Matt Pocock Skills" {
	local file
	for file in "${UPDATE_SH}" "${UPDATE_WSL}"; do
		assert_bash_script_no_matt_skills_install "$file"
	done
}

@test "update.mk wires Matt skills only to update-ai-skills target" {
	run grep 'install-agent-skills' "${UPDATE_MK}"
	[[ "${status}" -eq 0 ]]
	[[ "$(grep -c 'install-agent-skills' "${UPDATE_MK}")" -eq 1 ]]
	grep -B1 'install-agent-skills' "${UPDATE_MK}" | grep -q '^update-ai-skills:'
	for target in update update-wsl update-windows update-check update-projects; do
		run awk -v target="${target}:" '
			$0 == target { capture=1; next }
			capture && /^[^[:space:]]/ { exit }
			capture { print }
		' "${UPDATE_MK}"
		[[ "${status}" -eq 0 ]]
		[[ "${output}" != *"install-agent-skills"* ]]
		[[ "${output}" != *"mattpocock"* ]]
		[[ "${output}" != *"npx skills"* ]]
	done
}

@test "make -n update does not reference Matt skills install" {
	run make -n -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-agent-skills"* ]]
	[[ "${output}" != *"mattpocock"* ]]
	[[ "${output}" != *"npx skills"* ]]
}

@test "update-check script stays read-only by contract" {
	assert_bash_script_no_chezmoi_apply "${UPDATE_CHECK}"
	assert_file_not_matches "${UPDATE_CHECK}" 'apt-get'
	assert_file_not_matches "${UPDATE_CHECK}" 'npm install'
	assert_file_not_matches "${UPDATE_CHECK}" 'winget'
	assert_file_not_matches "${UPDATE_CHECK}" 'docker pull'
	assert_file_not_matches "${UPDATE_CHECK}" 'npx skills'
}

@test "make -n update-check does not reference mutating installers" {
	run make -n -C "${DOTFILES_DIR}" update-check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"scripts/update/update-check.sh"* ]]
	[[ "${output}" != *"apt-get"* ]]
	[[ "${output}" != *"npm install"* ]]
	[[ "${output}" != *"winget"* ]]
	[[ "${output}" != *"docker pull"* ]]
	[[ "${output}" != *"chezmoi"* ]]
	[[ "${output}" != *"install-agent-skills"* ]]
}
