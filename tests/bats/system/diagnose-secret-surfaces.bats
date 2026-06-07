#!/usr/bin/env bats
# scripts/diagnose-secret-surfaces.sh — read-only secret surface scan with redaction.

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/diagnose-secret-surfaces.sh"
	FIXTURE_DIR="${TEST_TEMP_DIR}/fixtures"
	mkdir -p "${FIXTURE_DIR}/clean" "${FIXTURE_DIR}/dirty"
	printf '# clean snapshot stub\nexport PATH=/usr/bin\n' >"${FIXTURE_DIR}/clean/ok.sh"
	cat >"${FIXTURE_DIR}/dirty/leak.sh" <<'EOF'
#!/usr/bin/env bash
export GH_TOKEN=ghp_FAKE000000000000000000000000000000
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_FAKE000000000000000000000000000000
export POSTGRES_DSN=postgresql://user:secretpass@localhost:5432/db
export MINIO_SECRET_KEY=fake-minio-secret-value
export API_PASSWORD=not-a-real-password
EOF
	chmod +x "${SCRIPT}"
}

teardown() {
	teardown_temp_dir
}

@test "diagnose-secret-surfaces.sh is executable and passes shellcheck contract" {
	[[ -x "${SCRIPT}" ]]
	head -5 "${SCRIPT}" | grep -q 'set -euo pipefail'
	grep -q 'read-only' "${SCRIPT}"
	grep -q 'Never prints complete secret values' "${SCRIPT}" || grep -q 'Never prints full secret values' "${SCRIPT}"
}

@test "clean fixture exits 0" {
	run "${SCRIPT}" "${FIXTURE_DIR}/clean"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"OK: no sensitive patterns found"* ]]
}

@test "dirty fixture exits 1 and redacts without printing full fake token" {
	local fake_token="ghp_FAKE000000000000000000000000000000"
	run "${SCRIPT}" "${FIXTURE_DIR}/dirty"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"WARN:"* ]]
	[[ "${output}" == *"leak.sh"* ]]
	[[ "${output}" == *"<redacted>"* ]]
	[[ "${output}" != *"${fake_token}"* ]]
	[[ "${output}" != *"secretpass"* ]]
	[[ "${output}" != *"fake-minio-secret-value"* ]]
	[[ "${output}" != *"not-a-real-password"* ]]
}

@test "dirty fixture mentions GH_TOKEN and POSTGRES_DSN labels redacted" {
	run "${SCRIPT}" "${FIXTURE_DIR}/dirty"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"GH_TOKEN"* ]]
	[[ "${output}" == *"POSTGRES_DSN"* ]]
	[[ "${output}" == *"MINIO_SECRET_KEY"* ]]
}

@test "no args with absent default path exits 0" {
	local saved_home="${HOME:-}"
	export HOME="${TEST_TEMP_DIR}/empty_home"
	mkdir -p "${HOME}"
	run "${SCRIPT}"
	export HOME="${saved_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"no default scan path"* || "${output}" == *"OK:"* ]]
}

@test "help exits 0" {
	run "${SCRIPT}" --help
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Read-only"* ]]
}
