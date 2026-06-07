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
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
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

@test "update-check invokes checkout AI surface diagnostic visibly" {
	grep -q 'diagnose-checkout-ai-surface\.sh' "${UPDATE_CHECK}"
	grep -q 'Checkout AI surface' "${UPDATE_CHECK}"
}

@test "update-check includes github identity diagnostic in offline warn-only mode" {
	grep -q 'github-identity-check\.sh" --offline --warn-only' "${UPDATE_CHECK}"
	assert_file_not_matches "${UPDATE_CHECK}" 'gh api'
	assert_file_not_matches "${UPDATE_CHECK}" 'gh repo view'
}

@test "update-check surfaces .claude diagnostic and does not delete fixture" {
	local fixture="${TEST_TEMP_DIR}/dotfiles-fixture"
	mkdir -p "${fixture}/.claude" "${fixture}/scripts"
	cat >"${fixture}/scripts/diagnose-checkout-ai-surface.sh" <<'EOF'
#!/usr/bin/env bash
printf 'WARN: .claude/ exists in checkout\n'
printf 'rm -rf %s/.claude/\n' "${DOTFILES_DIR}"
exit 1
EOF
	cat >"${fixture}/scripts/github-identity-check.sh" <<'EOF'
#!/usr/bin/env bash
printf 'GitHub identity diagnostic fixture\n'
exit 0
EOF
	chmod +x "${fixture}/scripts/diagnose-checkout-ai-surface.sh" "${fixture}/scripts/github-identity-check.sh"

	run env DOTFILES_DIR="${fixture}" bash "${UPDATE_CHECK}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Checkout AI surface"* ]]
	[[ "${output}" == *".claude/ exists in checkout"* ]]
	[[ "${output}" == *"belongs in HOME runtime"* ]]
	[[ -d "${fixture}/.claude" ]]
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
