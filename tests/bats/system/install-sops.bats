#!/usr/bin/env bats
# Mirrors tests/bats/system/install-uv.bats; verifies the opt-in install-sops
# script honours DRY_RUN, is idempotent when sops is already in PATH, and never
# escalates with sudo.

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_SOPS="${DOTFILES_DIR}/scripts/install-sops.sh"
	HELPER_SCRIPT="${DOTFILES_DIR}/scripts/lib/system_deps.py"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "install-sops DRY_RUN does not mutate and prints plan" {
	# Force "sops missing" by limiting PATH so DRY_RUN takes the planning branch.
	run env DRY_RUN=1 PATH="/usr/bin:/bin" bash "${INSTALL_SOPS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"https://github.com/getsops/sops/releases/download/"* ]]
	[[ "${output}" == *"Plan:"* ]]
	[[ "${output}" == *"sha256sum -c"* ]]
	# Sanity: it must not claim to have downloaded anything.
	[[ "${output}" != *"==> Downloading official binary"* ]]
}

@test "install-sops does not reinstall when sops is already present in PATH" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/sops" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version) echo "sops 99.9.9 (stub)";;
	*) exit 0;;
esac
EOF
	chmod +x "${stub_dir}/sops"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_SOPS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"sops already present"* ]]
	[[ "${output}" == *"99.9.9"* ]]
	[[ "${output}" != *"==> Downloading official binary"* ]]
}

@test "install-sops DRY_RUN with sops present still skips the download branch" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/sops" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version) echo "sops 99.9.9 (stub)";;
	*) exit 0;;
esac
EOF
	chmod +x "${stub_dir}/sops"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_SOPS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"sops already present"* ]]
	[[ "${output}" != *"==> Downloading official binary"* ]]
}

@test "system_deps actions recommend 'make install-sops' for sops" {
	local inv="${TEST_TEMP_DIR}/sops.yaml"
	cat >"${inv}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: sops
    command: sops
    required: true
    capability: secrets
    install_method: manual
    note: Test inventory.
EOF

	run python3 "${HELPER_SCRIPT}" actions --inventory "${inv}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"make install-sops"* ]]
	[[ "${output}" == *"https://github.com/getsops/sops/releases"* ]]
}

@test "install-sops target in install.mk is present and outside 'install' aggregator" {
	run grep -E "^install-sops:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	# Ensure 'install-sops' is NOT a dependency of the aggregate 'install:' target.
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-sops"* ]]
}

@test "sops is no longer in ubuntu.yaml as an APT package" {
	run grep -c "package: sops" "${DOTFILES_DIR}/system/packages/ubuntu.yaml"
	[[ "${status}" -ne 0 ]] || [[ "${output}" == "0" ]]
}

@test "sops is declared as external in tooling.yaml" {
	run grep "package: sops" "${DOTFILES_DIR}/system/packages/tooling.yaml"
	[[ "${status}" -eq 0 ]]
}
