#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_NODE="${DOTFILES_DIR}/scripts/install-node-stack.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "install-node-stack.sh exists and passes bash -n" {
	[[ -f "${INSTALL_NODE}" ]]
	run bash -n "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
}

@test "install-node-stack DRY_RUN does not mutate and prints plan" {
	# Force node/npm "missing" by building a stub PATH that exposes only the
	# external utilities the dry-plan branch needs (dirname) but neither
	# node nor npm, regardless of whether the host already has them.
	local stub_path="${TEST_TEMP_DIR}/stub_bin"
	mkdir -p "${stub_path}"
	ln -s "$(command -v dirname)" "${stub_path}/dirname"
	local bash_abs
	bash_abs="$(command -v bash)"
	run env DRY_RUN=1 PATH="${stub_path}" "${bash_abs}" "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"apt-get install -y nodejs npm"* ]]
	[[ "${output}" == *"Plan:"* ]]
	# Must not claim to have run apt-get.
	[[ "${output}" != *"==> Installing"* ]]
}

@test "install-node-stack skips when node and npm are already present" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat > "${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v22.99.0";; *) exit 0;; esac
EOF
	cat > "${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "10.99.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"already present"* ]]
	[[ "${output}" == *"22.99.0"* ]]
	# Must not attempt to call apt-get.
	[[ "${output}" != *"==> Installing"* ]]
	[[ "${output}" != *"apt-get update"* ]]
}

@test "install-node-stack DRY_RUN with node+npm present still skips the install branch" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat > "${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v22.99.0";; *) exit 0;; esac
EOF
	cat > "${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "10.99.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"already present"* ]]
	[[ "${output}" != *"Plan:"* ]]
}

@test "install-node-stack target exists in install.mk and is NOT part of 'install:'" {
	run grep -E "^install-node-stack:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-node-stack"* ]]
}
