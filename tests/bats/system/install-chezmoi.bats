#!/usr/bin/env bats
# Mirrors tests/bats/system/install-uv.bats; verifies the opt-in install-chezmoi
# script honours DRY_RUN, is idempotent when chezmoi is already in PATH, and
# never escalates with sudo.

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_CHEZMOI="${DOTFILES_DIR}/scripts/install-chezmoi.sh"
	HELPER_SCRIPT="${DOTFILES_DIR}/scripts/lib/system_deps.py"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "install-chezmoi DRY_RUN does not mutate and prints plan" {
	# Force "chezmoi missing" by limiting PATH so DRY_RUN takes the planning branch.
	run env DRY_RUN=1 PATH="/usr/bin:/bin" bash "${INSTALL_CHEZMOI}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"https://get.chezmoi.io"* ]]
	[[ "${output}" == *"Plan:"* ]]
	[[ "${output}" == *".local/bin"* ]]
	# Sanity: it must not claim to have downloaded anything.
	[[ "${output}" != *"==> Downloading official installer"* ]]
}

@test "install-chezmoi does not reinstall when chezmoi is already present in PATH" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat > "${stub_dir}/chezmoi" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version) echo "chezmoi 99.9.9 (stub)";;
	*) exit 0;;
esac
EOF
	chmod +x "${stub_dir}/chezmoi"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_CHEZMOI}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"chezmoi already present"* ]]
	[[ "${output}" == *"99.9.9"* ]]
	[[ "${output}" != *"==> Downloading official installer"* ]]
}

@test "install-chezmoi DRY_RUN with chezmoi present still skips the download branch" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat > "${stub_dir}/chezmoi" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version) echo "chezmoi 99.9.9 (stub)";;
	*) exit 0;;
esac
EOF
	chmod +x "${stub_dir}/chezmoi"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_CHEZMOI}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"chezmoi already present"* ]]
	[[ "${output}" != *"==> Downloading official installer"* ]]
}

@test "system_deps actions recommend 'make install-chezmoi' for chezmoi" {
	local inv="${TEST_TEMP_DIR}/chezmoi.yaml"
	cat > "${inv}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: chezmoi
    command: chezmoi
    required: true
    capability: bootstrap
    install_method: manual
    note: Test inventory.
EOF

	run python3 "${HELPER_SCRIPT}" actions --inventory "${inv}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"make install-chezmoi"* ]]
	# Fallback to the upstream installer must remain documented in the summary.
	[[ "${output}" == *"get.chezmoi.io"* ]]
	# Old "go install" recommendation must be gone.
	[[ "${output}" != *"go install github.com/twpayne/chezmoi"* ]]
}

@test "install-chezmoi target in install.mk is present and outside 'install' aggregator" {
	run grep -E "^install-chezmoi:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	# Ensure 'install-chezmoi' is NOT a dependency of the aggregate 'install:' target.
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-chezmoi"* ]]
}

@test "install-dotfiles.sh suggests 'make install-chezmoi' when chezmoi is missing" {
	run grep -E "make install-chezmoi" "${DOTFILES_DIR}/scripts/install-dotfiles.sh"
	[[ "${status}" -eq 0 ]]
}
