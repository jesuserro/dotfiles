#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_GH="${DOTFILES_DIR}/scripts/install-mcp-github.sh"
	setup_temp_dir
	FAKE_HOME="${TEST_TEMP_DIR}/home"
	mkdir -p "${FAKE_HOME}"
	WRAPPER="${FAKE_HOME}/.local/bin/codex-mcp-github"
}

teardown() {
	teardown_temp_dir
}

@test "install-mcp-github.sh exists and passes bash -n" {
	[[ -f "${INSTALL_GH}" ]]
	run bash -n "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
}

@test "install-mcp-github DRY_RUN prints wrapper body and does not write" {
	run env DRY_RUN=1 HOME="${FAKE_HOME}" bash "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"BEGIN wrapper body"* ]]
	[[ "${output}" == *"@modelcontextprotocol/server-github"* ]]
	[[ "${output}" == *"GITHUB_PERSONAL_ACCESS_TOKEN"* ]]
	# Must not have written anything.
	[[ ! -e "${WRAPPER}" ]]
}

@test "install-mcp-github writes an executable wrapper under HOME" {
	run env HOME="${FAKE_HOME}" bash "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
	[[ -x "${WRAPPER}" ]]
	# Must contain the canonical exec line.
	grep -q "@modelcontextprotocol/server-github" "${WRAPPER}"
	# Must NOT inline any token value (only the variable names).
	! grep -E "(ghp_[A-Za-z0-9]{10,}|github_pat_[A-Za-z0-9_]{10,})" "${WRAPPER}"
}

@test "install-mcp-github is idempotent (rerun reports already present)" {
	run env HOME="${FAKE_HOME}" bash "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
	run env HOME="${FAKE_HOME}" bash "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"already present and up to date"* ]]
}

@test "wrapper exits 2 with clear message when no token is set" {
	run env HOME="${FAKE_HOME}" bash "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
	[[ -x "${WRAPPER}" ]]

	# Run the wrapper with an empty HOME so the secrets file is absent,
	# and unset any token env vars inherited from the host shell.
	run env -i HOME="${TEST_TEMP_DIR}/empty_home" PATH="/usr/bin:/bin" "${WRAPPER}"
	[[ "${status}" -eq 2 ]]
	[[ "${output}" == *"missing GITHUB_PERSONAL_ACCESS_TOKEN"* ]]
	# Must not leak any token-looking material.
	[[ "${output}" != *"ghp_"* ]]
	[[ "${output}" != *"github_pat_"* ]]
}

@test "wrapper exits 127 with hint when token is set but npx is missing" {
	run env HOME="${FAKE_HOME}" bash "${INSTALL_GH}"
	[[ "${status}" -eq 0 ]]
	[[ -x "${WRAPPER}" ]]

	# Build a PATH that contains bash (so the shebang works) but no npx.
	local stub_path="${TEST_TEMP_DIR}/stub_bin"
	mkdir -p "${stub_path}"
	ln -s "$(command -v bash)" "${stub_path}/bash"
	ln -s "$(command -v env)" "${stub_path}/env"

	# Provide a fake token via env var (NOT via a file we have to write to
	# the user's ~/.secrets). Use the stub PATH so npx is unreachable.
	run -127 env -i HOME="${TEST_TEMP_DIR}/empty_home" PATH="${stub_path}" \
		GITHUB_PERSONAL_ACCESS_TOKEN="ghp_DUMMY_NEVER_USED" "${WRAPPER}"
	[[ "${status}" -eq 127 ]]
	[[ "${output}" == *"npx not in PATH"* ]]
	[[ "${output}" == *"install-node-stack"* ]]
}

@test "install-mcp-github target exists in install.mk and is NOT part of 'install:'" {
	run grep -E "^install-mcp-github:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-mcp-github"* ]]
}
