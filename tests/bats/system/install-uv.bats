#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_UV="${DOTFILES_DIR}/scripts/install-uv.sh"
	HELPER_SCRIPT="${DOTFILES_DIR}/scripts/lib/system_deps.py"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "install-uv DRY_RUN does not mutate and prints plan" {
	# Force "uv missing" by limiting PATH so DRY_RUN takes the planning branch.
	run env DRY_RUN=1 PATH="/usr/bin:/bin" bash "${INSTALL_UV}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"https://astral.sh/uv/install.sh"* ]]
	[[ "${output}" == *"Plan:"* ]]
	[[ "${output}" == *"UV_NO_MODIFY_PATH=1"* ]]
	# Sanity: it must not claim to have downloaded anything.
	[[ "${output}" != *"==> Downloading official installer"* ]]
}

@test "install-uv does not reinstall when uv is already present in PATH" {
	# Stub a fake uv binary that responds to --version.
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat > "${stub_dir}/uv" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version) echo "uv 99.9.9 (stub)";;
	*) exit 0;;
esac
EOF
	chmod +x "${stub_dir}/uv"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_UV}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"uv already present"* ]]
	[[ "${output}" == *"99.9.9"* ]]
	# It must not attempt to download anything when uv is already present.
	[[ "${output}" != *"==> Downloading official installer"* ]]
}

@test "install-uv DRY_RUN with uv present still skips the download branch" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat > "${stub_dir}/uv" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version) echo "uv 99.9.9 (stub)";;
	*) exit 0;;
esac
EOF
	chmod +x "${stub_dir}/uv"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_UV}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"uv already present"* ]]
	[[ "${output}" != *"==> Downloading official installer"* ]]
}

@test "system_deps actions recommend 'make install-uv' for uv" {
	local inv="${TEST_TEMP_DIR}/uv.yaml"
	cat > "${inv}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: uv
    command: uv
    required: false
    capability: python
    install_method: manual
    note: Test inventory.
EOF

	run python3 "${HELPER_SCRIPT}" actions --include-optional --inventory "${inv}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"make install-uv"* ]]
	# Fallback to the official installer must remain documented in the summary.
	[[ "${output}" == *"https://astral.sh/uv/install.sh"* ]]
}

@test "install-uv target in install.mk is present and outside 'install' aggregator" {
	run grep -E "^install-uv:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	# Ensure 'install-uv' is NOT a dependency of the aggregate 'install:' target.
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-uv"* ]]
}
