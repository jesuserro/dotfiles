#!/usr/bin/env bats
# agent-validate-report: Markdown report generation contract.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/agent-validate-report.sh"
	REPORT_PATH="${TEST_TEMP_DIR}/agent-validation/latest.md"
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	MAKE_LOG="${TEST_TEMP_DIR}/make.log"
	mkdir -p "${FAKE_BIN}"
	cat >"${FAKE_BIN}/make" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_MAKE_LOG}"
printf 'fake make called: %s\n' "$*"
if [[ -n "${FAKE_MAKE_STATUS:-}" ]]; then
	exit "${FAKE_MAKE_STATUS}"
fi
EOF
	chmod +x "${FAKE_BIN}/make"
}

teardown() {
	teardown_temp_dir
}

run_report() {
	run env \
		-u AGENT_VALIDATE_TARGET \
		-u AGENT_VALIDATE_CMD \
		DOTFILES_DIR="${DOTFILES_DIR}" \
		AGENT_VALIDATE_REPORT_PATH="${REPORT_PATH}" \
		FAKE_MAKE_LOG="${MAKE_LOG}" \
		PATH="${FAKE_BIN}:${PATH}" \
		"$@" \
		bash "${SCRIPT}"
}

assert_make_called_with() {
	[[ -f "${MAKE_LOG}" ]]
	[[ "$(cat "${MAKE_LOG}")" == "$1" ]]
}

assert_make_not_called() {
	[[ ! -f "${MAKE_LOG}" ]]
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

@test "agent-validate-report default safely calls agent-validate" {
	run_report
	[[ "${status}" -eq 0 ]]
	assert_make_called_with "agent-validate"
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
	grep -q 'make agent-validate' "${REPORT_PATH}"
	grep -q 'fake make called: agent-validate' "${REPORT_PATH}"
}

@test "agent-validate-report calls allowed target" {
	run_report AGENT_VALIDATE_TARGET="agent-validate-changed"
	[[ "${status}" -eq 0 ]]
	assert_make_called_with "agent-validate-changed"
	[[ -f "${REPORT_PATH}" ]]
	grep -q 'make agent-validate-changed' "${REPORT_PATH}"
}

@test "agent-validate-report propagates target failure and still writes report" {
	run_report AGENT_VALIDATE_TARGET="test-fast" FAKE_MAKE_STATUS="7"
	[[ "${status}" -eq 7 ]]
	assert_make_called_with "test-fast"
	[[ -f "${REPORT_PATH}" ]]
	grep -q '\*\*FAIL\*\*' "${REPORT_PATH}"
	grep -q 'exit code 7' "${REPORT_PATH}"
	grep -q 'fake make called: test-fast' "${REPORT_PATH}"
}

@test "agent-validate-report rejects unsupported target without calling make" {
	run_report AGENT_VALIDATE_TARGET="agent-validate-changed; echo pwned"
	[[ "${status}" -eq 2 ]]
	assert_make_not_called
	[[ -f "${REPORT_PATH}" ]]
	[[ "${output}" == *"unsupported validation selector"* ]]
	grep -q '\*\*FAIL\*\*' "${REPORT_PATH}"
	grep -q 'exit code 2' "${REPORT_PATH}"
	grep -q 'unsupported validation selector' "${REPORT_PATH}"
	grep -q '(not run: unsupported selector)' "${REPORT_PATH}"
}

@test "agent-validate-report supports deprecated exact AGENT_VALIDATE_CMD values" {
	run_report AGENT_VALIDATE_CMD="make test-fast"
	[[ "${status}" -eq 0 ]]
	assert_make_called_with "test-fast"
	grep -q 'make test-fast' "${REPORT_PATH}"
	grep -q 'AGENT_VALIDATE_CMD is deprecated' "${REPORT_PATH}"
}

@test "agent-validate-report rejects unsafe AGENT_VALIDATE_CMD without calling make" {
	run_report AGENT_VALIDATE_CMD="make agent-validate; rm -rf x"
	[[ "${status}" -eq 2 ]]
	assert_make_not_called
	[[ "${output}" == *"unsupported validation selector"* ]]
	grep -q '\*\*FAIL\*\*' "${REPORT_PATH}"
	grep -q 'exit code 2' "${REPORT_PATH}"
	grep -q 'unsupported validation selector' "${REPORT_PATH}"
}

@test "agent-validate-report target takes precedence over deprecated command" {
	run_report AGENT_VALIDATE_TARGET="agent-validate-changed" AGENT_VALIDATE_CMD="make test-fast"
	[[ "${status}" -eq 0 ]]
	assert_make_called_with "agent-validate-changed"
	grep -q 'make agent-validate-changed' "${REPORT_PATH}"
}

@test "agent-validate-report script does not contain shell command evaluation" {
	run grep -q 'eval' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
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
