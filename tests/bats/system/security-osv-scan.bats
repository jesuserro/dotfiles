#!/usr/bin/env bats
# security-osv-scan.sh: best-effort vs strict OSV repository scan.

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/security-osv-scan.sh"
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	FAKE_REPO="${TEST_TEMP_DIR}/fake-dotfiles"
	mkdir -p "${FAKE_BIN}" "${FAKE_REPO}"
}

teardown() {
	teardown_temp_dir
}

write_fake_osv() {
	local mode="$1"
	cat >"${FAKE_BIN}/osv-scanner" <<EOF
#!/usr/bin/env bash
case "${mode}" in
pass) exit 0 ;;
unavailable_ok)
	printf 'failed resolution: rpc error: code = Unavailable desc = service unavailable\n' >&2
	printf 'Total 0 packages affected by 0 known vulnerabilities\n'
	exit 0
	;;
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

add_osv_input() {
	printf '{}\n' >"${FAKE_REPO}/package-lock.json"
}

run_security_osv() {
	local security_online="${1:-0}"
	run env \
		DOTFILES_DIR="${FAKE_REPO}" \
		SECURITY_ONLINE="${security_online}" \
		PATH="${FAKE_BIN}:/usr/bin:/bin" \
		bash "${SCRIPT}"
}

@test "security-osv-scan skips when no supported manifests exist" {
	write_fake_osv pass
	run_security_osv 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"osv-scanner skipped: no supported manifests or lockfiles found"* ]]
}

@test "security-osv-scan best-effort mode warns but passes on remote outage with exit zero" {
	add_osv_input
	write_fake_osv unavailable_ok
	run_security_osv 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"best-effort"* ]]
	[[ "${output}" == *"not confirmed clean"* ]]
	[[ "${output}" == *"osv-scanner completed"* ]]
	[[ "${output}" != *"osv-scanner passed"* ]]
}

@test "security-osv-scan strict mode fails on remote outage" {
	add_osv_input
	write_fake_osv unavailable_ok
	run_security_osv 1
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"SECURITY_ONLINE=1 strict"* ]]
	[[ "${output}" == *"External dependency failure: osv-scanner service unavailable"* ]]
}

@test "security-osv-scan fails on vulnerability findings" {
	add_osv_input
	write_fake_osv vuln
	run_security_osv 0
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Vulnerability findings detected"* ]]
}

@test "security-osv-scan completes cleanly on successful scan" {
	add_osv_input
	write_fake_osv pass
	run_security_osv 0
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"osv-scanner completed"* ]]
}
