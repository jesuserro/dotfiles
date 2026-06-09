#!/usr/bin/env bats
# github-identity-check: read-only identity and remote diagnostics.

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/github-identity-check.sh"
	LAUNCHER="${DOTFILES_DIR}/bin/github-identity-check"
	TMPL="${DOTFILES_DIR}/dot_local/bin/symlink_github-identity-check.tmpl"
	HOME_DIR="${TEST_TEMP_DIR}/home"
	mkdir -p "${HOME_DIR}"
}

teardown() {
	teardown_temp_dir
}

make_repo() {
	local repo="$1"
	local origin="$2"
	local upstream="${3:-}"
	mkdir -p "${repo}"
	git init -q "${repo}"
	git -C "${repo}" config user.name "Test User"
	git -C "${repo}" config user.email "test@example.com"
	git -C "${repo}" remote add origin "${origin}"
	if [[ -n "${upstream}" ]]; then
		git -C "${repo}" remote add upstream "${upstream}"
	fi
}

@test "--help works" {
	run bash "${SCRIPT}" --help
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Usage: github-identity-check"* ]]
	[[ "${output}" == *"--offline"* ]]
}

@test "bin wrapper and chezmoi symlink template exist" {
	[[ -x "${LAUNCHER}" ]]
	grep -q 'exec bash "$SCRIPT" "$@"' "${LAUNCHER}"
	[[ "$(cat "${TMPL}")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/github-identity-check' ]]
}

@test "absence of gh in offline mode does not fail" {
	local repo="${TEST_TEMP_DIR}/repo-no-gh"
	local fakebin="${TEST_TEMP_DIR}/fakebin"
	make_repo "${repo}" "git@github.com:jesuserro/dotfiles.git"
	mkdir -p "${fakebin}"
	ln -s /usr/bin/git "${fakebin}/git"
	ln -s /usr/bin/hostname "${fakebin}/hostname"

	cd "${repo}"
	run env HOME="${HOME_DIR}" PATH="${fakebin}" /usr/bin/bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"gh unavailable"* ]]
	[[ "${output}" == *"offline mode"* ]]
}

@test "tokens are warned without printing values" {
	local repo="${TEST_TEMP_DIR}/repo-tokens"
	make_repo "${repo}" "git@github.com:jesuserro/dotfiles.git"

	cd "${repo}"
	run env HOME="${HOME_DIR}" GH_TOKEN="super-secret-gh" GITHUB_TOKEN="other-secret" bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"GH_TOKEN=<set>"* ]]
	[[ "${output}" == *"GITHUB_TOKEN=<set>"* ]]
	[[ "${output}" != *"super-secret-gh"* ]]
	[[ "${output}" != *"other-secret"* ]]
	[[ "${output}" == *"unset GH_TOKEN GITHUB_TOKEN"* ]]
}

@test "origin jesuserro/dotfiles is classified as personal casa" {
	local repo="${TEST_TEMP_DIR}/repo-personal"
	make_repo "${repo}" "git@github.com:jesuserro/dotfiles.git"

	cd "${repo}"
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Inferred profile: personal/casa"* ]]
}

@test "office fork remotes are classified as oficina fork" {
	local repo="${TEST_TEMP_DIR}/repo-office"
	make_repo "${repo}" "git@github.com:jesus-ixatu/dotfiles.git" "git@github.com:jesuserro/dotfiles.git"

	cd "${repo}"
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Inferred profile: oficina/fork"* ]]
}

@test "IXATU organization remotes are classified as oficina fork" {
	local repo="${TEST_TEMP_DIR}/repo-office-ixatu"
	make_repo "${repo}" "https://github.com/IXATU/dotfiles.git" "https://github.com/jesuserro/dotfiles.git"

	cd "${repo}"
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Inferred profile: oficina/fork"* ]]
	[[ "${output}" != *"Unable to infer profile from remotes"* ]]
}

@test "unexpected remote warns but warn-only exits zero" {
	local repo="${TEST_TEMP_DIR}/repo-unknown"
	make_repo "${repo}" "git@github.com:someone/else.git"

	cd "${repo}"
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Unable to infer profile from remotes"* ]]
}

@test "--strict fails when an explicit expectation fails" {
	local repo="${TEST_TEMP_DIR}/repo-strict"
	make_repo "${repo}" "git@github.com:someone/else.git"
	mkdir -p "${HOME_DIR}/.config/dotfiles"
	printf 'DOTFILES_GITHUB_EXPECTED_ORIGIN=jesuserro/dotfiles\n' >"${HOME_DIR}/.config/dotfiles/github-identity.env"

	cd "${repo}"
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --offline --strict
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"FAIL: origin mismatch"* ]]
}

@test "--offline does not call fake gh api or gh repo view" {
	local repo="${TEST_TEMP_DIR}/repo-fake-gh"
	local fakebin="${TEST_TEMP_DIR}/fake-gh-bin"
	local log="${TEST_TEMP_DIR}/gh.log"
	make_repo "${repo}" "git@github.com:jesuserro/dotfiles.git"
	mkdir -p "${fakebin}"
	cat >"${fakebin}/gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"${log}"
exit 99
EOF
	chmod +x "${fakebin}/gh"

	cd "${repo}"
	run env HOME="${HOME_DIR}" PATH="${fakebin}:${PATH}" bash "${SCRIPT}" --offline --warn-only
	[[ "${status}" -eq 0 ]]
	[[ ! -e "${log}" ]]
	[[ "${output}" == *"offline mode: skipping gh api and gh repo view"* ]]
}

@test "machine config overrides expectations" {
	local repo="${TEST_TEMP_DIR}/repo-config"
	make_repo "${repo}" "https://github.com/jesus-ixatu/dotfiles.git" "https://github.com/jesuserro/dotfiles.git"
	mkdir -p "${HOME_DIR}/.config/dotfiles"
	cat >"${HOME_DIR}/.config/dotfiles/github-identity.env" <<'EOF'
DOTFILES_GITHUB_EXPECTED_ORIGIN=jesus-ixatu/dotfiles
DOTFILES_GITHUB_EXPECTED_UPSTREAM=jesuserro/dotfiles
DOTFILES_GITHUB_IDENTITY_PROFILE=office
EOF

	cd "${repo}"
	run env HOME="${HOME_DIR}" bash "${SCRIPT}" --offline --strict
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Configured profile: office"* ]]
	[[ "${output}" == *"origin matches expectation"* ]]
	[[ "${output}" == *"upstream matches expectation"* ]]
}
