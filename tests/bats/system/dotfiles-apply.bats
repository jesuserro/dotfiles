#!/usr/bin/env bats
# dotfiles-apply: safe Chezmoi preview/apply wrapper contract.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	LAUNCHER="${DOTFILES_DIR}/bin/dotfiles-apply"
	TMPL="${DOTFILES_DIR}/dot_local/bin/symlink_dotfiles-apply.tmpl"
	setup_temp_dir
	FIXTURE="${TEST_TEMP_DIR}/dotfiles-fixture"
	STUB_BIN="${TEST_TEMP_DIR}/bin"
	STUB_LOG="${TEST_TEMP_DIR}/chezmoi.log"
	mkdir -p "${STUB_BIN}" "${FIXTURE}"
	touch "${FIXTURE}/Makefile"
	cat >"${STUB_BIN}/chezmoi" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${CHEZMOI_STUB_LOG}"
case "$2" in
diff)
	if [[ -n "${CHEZMOI_STUB_DIFF_OUTPUT:-}" ]]; then
		printf '%b' "${CHEZMOI_STUB_DIFF_OUTPUT}"
	fi
	exit 0
	;;
status)
	if [[ -n "${CHEZMOI_STUB_STATUS_OUTPUT:-}" ]]; then
		printf '%b' "${CHEZMOI_STUB_STATUS_OUTPUT}"
	fi
	exit "${CHEZMOI_STUB_STATUS_EXIT:-0}"
	;;
*)
	exit 0
	;;
esac
EOF
	chmod +x "${STUB_BIN}/chezmoi"
}

teardown() {
	teardown_temp_dir
}

run_apply() {
	run env \
		DOTFILES_DIR="${FIXTURE}" \
		CHEZMOI_STUB_LOG="${STUB_LOG}" \
		CHEZMOI_STUB_DIFF_OUTPUT="${CHEZMOI_STUB_DIFF_OUTPUT:-}" \
		CHEZMOI_STUB_STATUS_OUTPUT="${CHEZMOI_STUB_STATUS_OUTPUT:-}" \
		CHEZMOI_STUB_STATUS_EXIT="${CHEZMOI_STUB_STATUS_EXIT:-0}" \
		PATH="${STUB_BIN}:${PATH}" \
		bash "${LAUNCHER}" "$@"
}

stub_invocations() {
	[[ -f "${STUB_LOG}" ]] && cat "${STUB_LOG}" || true
}

stub_has_apply() {
	[[ -f "${STUB_LOG}" ]] || return 1
	grep -qE '(^| )apply( |$)' "${STUB_LOG}"
}

@test "bin/dotfiles-apply exists and is executable" {
	[[ -f "${LAUNCHER}" ]]
	[[ -x "${LAUNCHER}" ]]
}

@test "chezmoi symlink template points to bin/dotfiles-apply" {
	[[ -f "${TMPL}" ]]
	[[ "$(cat "${TMPL}")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/dotfiles-apply' ]]
}

@test "dotfiles-apply script does not invoke destructive commands" {
	run grep -q 'make update' "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'git add' "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'git commit' "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'git push' "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
	run grep -Eq '(apt|apt-get|brew|winget|npm install|pip install)' "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
}

@test "default mode runs diff and status but not apply" {
	run_apply
	[[ "${status}" -eq 0 ]]
	local invocations
	invocations="$(stub_invocations)"
	[[ "${invocations}" == *"diff"* ]]
	[[ "${invocations}" == *"status"* ]]
	! stub_has_apply
}

@test "--check does not run apply" {
	run_apply --check
	[[ "${status}" -eq 0 ]]
	! stub_has_apply
}

@test "--apply without confirmation does not apply" {
	run bash -c "printf 'WRONG\n' | env DOTFILES_DIR='${FIXTURE}' CHEZMOI_STUB_LOG='${STUB_LOG}' PATH='${STUB_BIN}:${PATH}' bash '${LAUNCHER}' --apply"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Aborted"* ]]
	! stub_has_apply
}

@test "--apply with APPLY confirmation runs apply" {
	run bash -c "printf 'APPLY\n' | env DOTFILES_DIR='${FIXTURE}' CHEZMOI_STUB_LOG='${STUB_LOG}' PATH='${STUB_BIN}:${PATH}' bash '${LAUNCHER}' --apply"
	[[ "${status}" -eq 0 ]]
	stub_has_apply
}

@test "--apply --yes runs apply without prompt" {
	run_apply --apply --yes
	[[ "${status}" -eq 0 ]]
	stub_has_apply
}

@test "DOTFILES_DIR override works with fixture" {
	run_apply
	[[ "${status}" -eq 0 ]]
	[[ "$(stub_invocations)" == *"--source=${FIXTURE}"* ]]
}

@test "fails when DOTFILES_DIR does not exist" {
	local missing="${TEST_TEMP_DIR}/missing-dotfiles"
	run env DOTFILES_DIR="${missing}" PATH="${STUB_BIN}:${PATH}" bash "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"dotfiles directory not found"* ]]
}

@test "fails when chezmoi is not available" {
	local empty_path="${TEST_TEMP_DIR}/empty-bin"
	mkdir -p "${empty_path}"
	run env DOTFILES_DIR="${FIXTURE}" PATH="${empty_path}:/usr/bin:/bin" bash "${LAUNCHER}"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"chezmoi not found"* ]]
}

@test "optional paths are forwarded to chezmoi" {
	run_apply --check "${HOME}/.zshrc"
	[[ "${status}" -eq 0 ]]
	[[ "$(stub_invocations)" == *"${HOME}/.zshrc"* ]]
}

@test "--check summarizes only expected chezmoiscripts Run status entries" {
	CHEZMOI_STUB_STATUS_OUTPUT=$' R .chezmoiscripts/00_backup_rc_files.sh\n' run_apply --check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"INFO: Only expected .chezmoiscripts Run entries detected (1)."* ]]
	[[ "${output}" == *"OK: No non-script Chezmoi status entries detected."* ]]
	[[ "${output}" != *$'\n R .chezmoiscripts/00_backup_rc_files.sh\n'* ]]
}

@test "--check keeps real status entries visible" {
	CHEZMOI_STUB_STATUS_OUTPUT=$' M .zshrc\n' run_apply --check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *" M .zshrc"* ]]
	[[ "${output}" != *"Only expected .chezmoiscripts Run entries"* ]]
}

@test "--check suppresses benign Run status but keeps mixed real drift" {
	CHEZMOI_STUB_STATUS_OUTPUT=$' R .chezmoiscripts/00_backup_rc_files.sh\n M .zshrc\n' run_apply --check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *" M .zshrc"* ]]
	[[ "${output}" == *"INFO: Suppressed expected .chezmoiscripts Run entries: 1."* ]]
	[[ "${output}" != *$'\n R .chezmoiscripts/00_backup_rc_files.sh\n'* ]]
}

@test "--check does not filter chezmoiscripts from diff output" {
	CHEZMOI_STUB_DIFF_OUTPUT=$'diff --git a/.chezmoiscripts/00_backup_rc_files.sh b/.chezmoiscripts/00_backup_rc_files.sh\n+script body\n' \
		CHEZMOI_STUB_STATUS_OUTPUT=$' R .chezmoiscripts/00_backup_rc_files.sh\n' \
		run_apply --check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"diff --git a/.chezmoiscripts/00_backup_rc_files.sh b/.chezmoiscripts/00_backup_rc_files.sh"* ]]
	[[ "${output}" == *"+script body"* ]]
	[[ "${output}" == *"INFO: Only expected .chezmoiscripts Run entries detected (1)."* ]]
}

@test "--check preserves status failures and exit code" {
	CHEZMOI_STUB_STATUS_OUTPUT=$'status exploded\n' CHEZMOI_STUB_STATUS_EXIT=42 run_apply --check
	[[ "${status}" -eq 42 ]]
	[[ "${output}" == *"status exploded"* ]]
	[[ "${output}" != *"Only expected .chezmoiscripts Run entries"* ]]
	[[ "${output}" != *"Suppressed expected .chezmoiscripts Run entries"* ]]
}

@test "--apply forwards optional paths to chezmoi apply" {
	run_apply --apply --yes "${HOME}/.zshrc"
	[[ "${status}" -eq 0 ]]
	[[ "$(stub_invocations)" == *"apply ${HOME}/.zshrc"* ]]
}
