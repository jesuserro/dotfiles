#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_AZURE="${DOTFILES_DIR}/scripts/install-azure-cli.sh"
	HELPER_SCRIPT="${DOTFILES_DIR}/scripts/lib/system_deps.py"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "install-azure-cli.sh exists and passes bash -n" {
	[[ -f "${INSTALL_AZURE}" ]]
	run bash -n "${INSTALL_AZURE}"
	[[ "${status}" -eq 0 ]]
}

@test "install-azure-cli DRY_RUN prints plan without running installers or az" {
	local stub_path="${TEST_TEMP_DIR}/stub_bin"
	mkdir -p "${stub_path}"
	ln -s "$(command -v dirname)" "${stub_path}/dirname"
	ln -s "$(command -v sed)" "${stub_path}/sed"
	local bash_abs
	bash_abs="$(command -v bash)"

	run env DRY_RUN=1 PATH="${stub_path}" "${bash_abs}" "${INSTALL_AZURE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"packages.microsoft.com/repos/azure-cli"* ]]
	[[ "${output}" == *"apt-get install -y azure-cli"* ]]
	[[ "${output}" == *"no se ejecutará login"* ]]
	[[ "${output}" != *"==> Instalando azure-cli"* ]]
	[[ "${output}" != *"Azure CLI instalado"* ]]
}

@test "install-azure-cli skips when az is already present" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/az" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	--version)
		echo "azure-cli 99.9.9"
		;;
	*)
		exit 0
		;;
esac
EOF
	chmod +x "${stub_dir}/az"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_AZURE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Azure CLI ya está instalado"* ]]
	[[ "${output}" == *"99.9.9"* ]]
	[[ "${output}" != *"==> Instalando azure-cli"* ]]
	[[ "${output}" != *"apt-get update"* ]]
}

@test "install-azure-cli DRY_RUN with az present does not execute az" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/az" <<'EOF'
#!/usr/bin/env bash
echo "az should not run during DRY_RUN" >&2
exit 42
EOF
	chmod +x "${stub_dir}/az"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_AZURE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Azure CLI ya está en PATH"* ]]
	[[ "${output}" == *"no se ejecuta 'az --version'"* ]]
	[[ "${output}" != *"az should not run during DRY_RUN"* ]]
}

@test "install-azure-cli target exists and is NOT part of install aggregator" {
	run grep -E "^install-azure-cli:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-azure-cli"* ]]
}

@test "azure-cli is declared as optional external tooling" {
	run python3 "${HELPER_SCRIPT}" validate --inventory "${DOTFILES_DIR}/system/packages/tooling.yaml"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *'"package": "azure-cli"'* ]]
	[[ "${output}" == *'"command": "az"'* ]]
	[[ "${output}" == *'"required": false'* ]]
	[[ "${output}" == *'"manager": "external"'* ]]
}

@test "deps-check default does not include optional azure-cli" {
	run python3 "${HELPER_SCRIPT}" list --inventory "${DOTFILES_DIR}/system/packages/tooling.yaml"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"azure-cli"* ]]
	[[ "${output}" != *$'\taz\t'* ]]
}

@test "apt package resolution does not include azure-cli from tooling inventory" {
	run python3 "${HELPER_SCRIPT}" packages --manager apt --inventory "${DOTFILES_DIR}/system/packages/tooling.yaml" --include-optional
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"azure-cli"* ]]
}

@test "system_deps actions recommend make install-azure-cli for az" {
	run python3 "${HELPER_SCRIPT}" actions --include-optional --inventory "${DOTFILES_DIR}/system/packages/tooling.yaml"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"azure-cli"* ]]
	[[ "${output}" == *"make install-azure-cli"* ]]
}

@test "install-verify does not fail on az" {
	run grep -E "version_or_fail az|version_or_fail azure-cli" "${DOTFILES_DIR}/scripts/install-verify.sh"
	[[ "${status}" -ne 0 ]]
}
