#!/usr/bin/env bats
# agent-validate-changed: local vs online security contract.

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/agent-validate-changed.sh"
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	FAKE_REPO="${TEST_TEMP_DIR}/fake-dotfiles"
	TEST_LOG="${TEST_TEMP_DIR}/tool-invocations.log"
	mkdir -p "${FAKE_BIN}" "${FAKE_REPO}/scripts"
	: >"${TEST_LOG}"

	git init -q "${FAKE_REPO}"
	git -C "${FAKE_REPO}" config user.email "test@example.com"
	git -C "${FAKE_REPO}" config user.name "Test User"
	printf 'initial\n' >"${FAKE_REPO}/README.md"
	git -C "${FAKE_REPO}" add README.md
	git -C "${FAKE_REPO}" commit -q -m "initial"

	write_fake_gitleaks 0
	write_fake_osv pass
	write_fake_shellcheck
	write_fake_shfmt
}

teardown() {
	teardown_temp_dir
}

write_fake_gitleaks() {
	local exit_code="$1"
	cat >"${FAKE_BIN}/gitleaks" <<EOF
#!/usr/bin/env bash
printf 'gitleaks\n' >>"${TEST_LOG}"
exit ${exit_code}
EOF
	chmod +x "${FAKE_BIN}/gitleaks"
}

write_fake_osv() {
	local mode="$1"
	cat >"${FAKE_BIN}/osv-scanner" <<EOF
#!/usr/bin/env bash
printf 'osv-scanner %s\n' "${mode}" >>"${TEST_LOG}"
case "${mode}" in
pass) exit 0 ;;
unavailable)
	printf 'osv-scanner service unavailable\n' >&2
	exit 2
	;;
vuln)
	printf 'Vulnerability findings detected\n' >&2
	exit 1
	;;
*) exit 0 ;;
esac
EOF
	chmod +x "${FAKE_BIN}/osv-scanner"
}

write_fake_shellcheck() {
	cat >"${FAKE_BIN}/shellcheck" <<EOF
#!/usr/bin/env bash
printf 'shellcheck\n' >>"${TEST_LOG}"
exit 0
EOF
	chmod +x "${FAKE_BIN}/shellcheck"
}

write_fake_shfmt() {
	cat >"${FAKE_BIN}/shfmt" <<EOF
#!/usr/bin/env bash
printf 'shfmt\n' >>"${TEST_LOG}"
exit 0
EOF
	chmod +x "${FAKE_BIN}/shfmt"
}

write_fake_make() {
	cat >"${FAKE_BIN}/make" <<EOF
#!/usr/bin/env bash
printf 'make %s\n' "\$*" >>"${TEST_LOG}"
exit 0
EOF
	chmod +x "${FAKE_BIN}/make"
}

write_fake_bats() {
	cat >"${FAKE_BIN}/bats" <<EOF
#!/usr/bin/env bash
printf 'bats %s\n' "\$*" >>"${TEST_LOG}"
exit 0
EOF
	chmod +x "${FAKE_BIN}/bats"
}

write_fake_validate_skills() {
	mkdir -p "${FAKE_REPO}/scripts"
	cat >"${FAKE_REPO}/scripts/validate-skills-structure.sh" <<EOF
#!/usr/bin/env bash
printf 'validate-skills-structure\n' >>"${TEST_LOG}"
exit 0
EOF
	chmod +x "${FAKE_REPO}/scripts/validate-skills-structure.sh"
}

add_changed_shell_file() {
	cat >"${FAKE_REPO}/scripts/changed.sh" <<'EOF'
#!/usr/bin/env bash
echo "changed"
EOF
	chmod +x "${FAKE_REPO}/scripts/changed.sh"
}

add_osv_input() {
	printf '{"name":"fixture"}\n' >"${FAKE_REPO}/package-lock.json"
}

run_agent_validate() {
	local security_online="${1:-0}"
	run env \
		DOTFILES_DIR="${FAKE_REPO}" \
		SECURITY_ONLINE="${security_online}" \
		PATH="${FAKE_BIN}:/usr/bin:/bin" \
		bash "${SCRIPT}"
}

@test "agent-validate-changed default mode skips osv-scanner" {
	run_agent_validate 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"osv-scanner online scan skipped"* ]]
	[[ "${output}" == *"SECURITY_ONLINE=1"* ]]
	grep -q '^gitleaks$' "${TEST_LOG}"
	! grep -q '^osv-scanner ' "${TEST_LOG}"
}

@test "agent-validate-changed with SECURITY_ONLINE=1 invokes osv-scanner" {
	add_osv_input
	run_agent_validate 1
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"osv-scanner repository scan (SECURITY_ONLINE=1)"* ]]
	grep -q '^osv-scanner pass$' "${TEST_LOG}"
}

@test "agent-validate-changed reports external failure when osv service is unavailable" {
	add_osv_input
	write_fake_osv unavailable
	run_agent_validate 1
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"External dependency failure: osv-scanner service unavailable"* ]]
	[[ "${output}" == *"osv-scanner service unavailable"* ]]
}

@test "agent-validate-changed still runs local shell checks on changed files" {
	add_changed_shell_file
	run_agent_validate 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"shellcheck changed shell files"* ]]
	[[ "${output}" == *"shfmt changed shell scripts"* ]]
	grep -q '^shellcheck$' "${TEST_LOG}"
	grep -q '^shfmt$' "${TEST_LOG}"
}

@test "agent-validate-changed fails when gitleaks detects a leak" {
	write_fake_gitleaks 1
	run_agent_validate 0
	[[ "${status}" -ne 0 ]]
	grep -q '^gitleaks$' "${TEST_LOG}"
	! grep -q '^osv-scanner ' "${TEST_LOG}"
}

@test "agent-validate-changed online mode fails on vulnerability findings" {
	add_osv_input
	write_fake_osv vuln
	run_agent_validate 1
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Vulnerability findings detected"* ]]
	! grep -q 'External dependency failure' <<<"${output}"
}

@test "agent-validate-changed runs docs bats when docs change" {
	write_fake_make
	mkdir -p "${FAKE_REPO}/docs"
	printf '# doc\n' >"${FAKE_REPO}/docs/touch.md"
	run_agent_validate 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"documentation bats"* ]]
	grep -q 'make.*bats-docs' "${TEST_LOG}"
}

@test "agent-validate-changed runs skills validation when skills change" {
	write_fake_validate_skills
	write_fake_bats
	mkdir -p "${FAKE_REPO}/ai/assets/skills/ops/fixture-skill"
	printf '# Fixture\n\n## When to Use\n\nTest.\n' >"${FAKE_REPO}/ai/assets/skills/ops/fixture-skill/SKILL.md"
	run_agent_validate 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"skills structure and bats"* ]]
	grep -q '^validate-skills-structure$' "${TEST_LOG}"
	grep -q 'bats .*/tests/bats/skills' "${TEST_LOG}"
}

@test "agent-validate-changed runs handoff contract bats when handoffs change" {
	write_fake_bats
	mkdir -p "${FAKE_REPO}/ai/assets/handoffs"
	printf '# Handoff\n' >"${FAKE_REPO}/ai/assets/handoffs/touch.md"
	run_agent_validate 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"handoff template contract bats"* ]]
	grep -q 'documentation-consistency.bats' "${TEST_LOG}"
}
