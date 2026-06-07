#!/usr/bin/env bats
# agent-validate-report: Markdown report generation contract.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/agent-validate-report.sh"
	REPORT_PATH="${TEST_TEMP_DIR}/agent-validation/latest.md"
}

teardown() {
	teardown_temp_dir
}

run_report() {
	local cmd="${1:-true}"
	local report_path="${2:-${REPORT_PATH}}"
	run env \
		DOTFILES_DIR="${DOTFILES_DIR}" \
		AGENT_VALIDATE_CMD="${cmd}" \
		AGENT_VALIDATE_REPORT_PATH="${report_path}" \
		bash "${SCRIPT}"
}

@test "agent-validate-report script exists and is executable" {
	[[ -f "${SCRIPT}" ]]
	[[ -x "${SCRIPT}" ]]
}

@test "agent-validate-report script does not invoke destructive commands" {
	run grep -q 'chezmoi apply' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
	run grep -Eq 'make update([^-]|$)' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'git add' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'git commit' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'git push' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
}

@test "agent-validate-report creates report with required sections on PASS" {
	run_report "true"
	[[ "${status}" -eq 0 ]]
	[[ -f "${REPORT_PATH}" ]]
	grep -q '^# Agent Validation Report' "${REPORT_PATH}"
	grep -q '^## Metadata' "${REPORT_PATH}"
	grep -q '^## Verdict' "${REPORT_PATH}"
	grep -q '^## Command' "${REPORT_PATH}"
	grep -q '^## Output' "${REPORT_PATH}"
	grep -q '^## Known Issues' "${REPORT_PATH}"
	grep -q '^## Next Steps' "${REPORT_PATH}"
	grep -q '\*\*PASS\*\*' "${REPORT_PATH}"
	grep -q 'exit code 0' "${REPORT_PATH}"
}

@test "agent-validate-report propagates failure exit code and still writes report" {
	run_report "false"
	[[ "${status}" -ne 0 ]]
	[[ -f "${REPORT_PATH}" ]]
	grep -q '\*\*FAIL\*\*' "${REPORT_PATH}"
	grep -q 'exit code' "${REPORT_PATH}"
}

@test "agent-validate-report records command in report body" {
	run_report "echo fixture-command-marker"
	[[ "${status}" -eq 0 ]]
	grep -q 'echo fixture-command-marker' "${REPORT_PATH}"
}

@test "agent-validate-report mentions ADR 0004 when .claude/skills exists" {
	if [[ ! -d "${DOTFILES_DIR}/.claude/skills" ]]; then
		skip ".claude/skills not present in checkout"
	fi
	run_report "false"
	[[ -f "${REPORT_PATH}" ]]
	grep -q 'ADR 0004' "${REPORT_PATH}"
	grep -q '.claude/skills' "${REPORT_PATH}"
}

@test "gitignore covers build/agent-validation" {
	grep -q 'build/agent-validation/' "${DOTFILES_DIR}/.gitignore"
}

@test "Makefile defines agent-validate-report target" {
	run make -pn -C "${DOTFILES_DIR}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"agent-validate-report:"* ]]
	[[ "${output}" == *"agent-validate-report.sh"* ]]
}
