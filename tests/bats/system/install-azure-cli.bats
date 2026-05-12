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

write_os_release() {
	local codename="$1"
	cat >"${TEST_TEMP_DIR}/os-release" <<EOF
ID=ubuntu
ID_LIKE=debian
VERSION_CODENAME=${codename}
UBUNTU_CODENAME=${codename}
EOF
}

make_install_stubs() {
	local stub_dir="$1"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >>"${AZURE_TEST_LOG}"
case "$*" in
	*"dists/resolute/Release"*)
		exit 22
		;;
	*"dists/noble/Release"*)
		exit 0
		;;
	*"-o "*)
		out=""
		while [[ $# -gt 0 ]]; do
			if [[ "$1" == "-o" ]]; then
				out="$2"
				break
			fi
			shift
		done
		[[ -n "${out}" ]] && printf 'fake-key\n' >"${out}"
		exit 0
		;;
	*)
		exit 0
		;;
esac
EOF
	cat >"${stub_dir}/sudo" <<'EOF'
#!/usr/bin/env bash
echo "sudo $*" >>"${AZURE_TEST_LOG}"
if [[ "$1" == "-n" && "$2" == "true" ]]; then
	exit 0
fi
"$@"
EOF
	cat >"${stub_dir}/apt-get" <<'EOF'
#!/usr/bin/env bash
echo "apt-get $*" >>"${AZURE_TEST_LOG}"
if [[ "$1" == "install" && "$*" == *"azure-cli"* ]]; then
	cat >"${AZURE_TEST_STUB_DIR}/az" <<'AZEOF'
#!/usr/bin/env bash
case "$1" in
	--version)
		echo "azure-cli 99.9.9"
		;;
	*)
		exit 0
		;;
esac
AZEOF
	chmod +x "${AZURE_TEST_STUB_DIR}/az"
fi
exit 0
EOF
	cat >"${stub_dir}/dpkg" <<'EOF'
#!/usr/bin/env bash
echo "dpkg $*" >>"${AZURE_TEST_LOG}"
if [[ "$1" == "--print-architecture" ]]; then
	echo "amd64"
	exit 0
fi
exit 1
EOF
	cat >"${stub_dir}/gpg" <<'EOF'
#!/usr/bin/env bash
echo "gpg $*" >>"${AZURE_TEST_LOG}"
out=""
while [[ $# -gt 0 ]]; do
	if [[ "$1" == "-o" ]]; then
		out="$2"
		break
	fi
	shift
done
[[ -n "${out}" ]] && printf 'fake-gpg\n' >"${out}"
exit 0
EOF
	chmod +x "${stub_dir}/curl" "${stub_dir}/sudo" "${stub_dir}/apt-get" "${stub_dir}/dpkg" "${stub_dir}/gpg"
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
	[[ "${output}" == *"/dists/"*"/Release"* ]]
	[[ "${output}" == *"apt-get install -y azure-cli"* ]]
	[[ "${output}" == *"no se ejecutará login"* ]]
	[[ "${output}" == *"no se hará red"* ]]
	[[ "${output}" != *"==> Instalando azure-cli"* ]]
	[[ "${output}" != *"Azure CLI instalado"* ]]
}

@test "install-azure-cli unsupported codename fails before writing source" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	local source_dir="${TEST_TEMP_DIR}/sources"
	local keyring="${TEST_TEMP_DIR}/keyrings/microsoft.gpg"
	local log="${TEST_TEMP_DIR}/commands.log"
	write_os_release "resolute"
	make_install_stubs "${stub_dir}"
	mkdir -p "${source_dir}" "$(dirname "${keyring}")"
	: >"${log}"

	run env \
		AZURE_TEST_LOG="${log}" \
		AZURE_TEST_STUB_DIR="${stub_dir}" \
		AZURE_CLI_OS_RELEASE_FILE="${TEST_TEMP_DIR}/os-release" \
		AZURE_CLI_SOURCE_DIR="${source_dir}" \
		AZURE_CLI_KEYRING_PATH="${keyring}" \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "${INSTALL_AZURE}"

	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Microsoft no publica Azure CLI"* ]]
	[[ "${output}" == *"resolute"* ]]
	[[ ! -e "${source_dir}/azure-cli.list" ]]
	[[ "$(cat "${log}")" == *"dists/resolute/Release"* ]]
	[[ "$(cat "${log}")" != *"apt-get update"* ]]
	[[ "$(cat "${log}")" != *"apt-get install -y azure-cli"* ]]
}

@test "install-azure-cli supported codename reaches install path with stubs" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	local source_dir="${TEST_TEMP_DIR}/sources"
	local keyring="${TEST_TEMP_DIR}/keyrings/microsoft.gpg"
	local log="${TEST_TEMP_DIR}/commands.log"
	write_os_release "noble"
	make_install_stubs "${stub_dir}"
	mkdir -p "${source_dir}" "$(dirname "${keyring}")"
	: >"${log}"

	run env \
		AZURE_TEST_LOG="${log}" \
		AZURE_TEST_STUB_DIR="${stub_dir}" \
		AZURE_CLI_OS_RELEASE_FILE="${TEST_TEMP_DIR}/os-release" \
		AZURE_CLI_SOURCE_DIR="${source_dir}" \
		AZURE_CLI_KEYRING_PATH="${keyring}" \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "${INSTALL_AZURE}"

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Microsoft publica Azure CLI para 'noble'"* ]]
	[[ "${output}" == *"Azure CLI instalado"* ]]
	[[ -f "${source_dir}/azure-cli.list" ]]
	[[ "$(cat "${source_dir}/azure-cli.list")" == *" noble main"* ]]
	[[ "$(cat "${log}")" == *"dists/noble/Release"* ]]
	[[ "$(cat "${log}")" == *"apt-get install -y azure-cli"* ]]
}

@test "install-azure-cli codename override is explicit and warned" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	local source_dir="${TEST_TEMP_DIR}/sources"
	local keyring="${TEST_TEMP_DIR}/keyrings/microsoft.gpg"
	local log="${TEST_TEMP_DIR}/commands.log"
	write_os_release "resolute"
	make_install_stubs "${stub_dir}"
	mkdir -p "${source_dir}" "$(dirname "${keyring}")"
	: >"${log}"

	run env \
		AZURE_TEST_LOG="${log}" \
		AZURE_TEST_STUB_DIR="${stub_dir}" \
		AZURE_CLI_OS_RELEASE_FILE="${TEST_TEMP_DIR}/os-release" \
		AZURE_CLI_SOURCE_DIR="${source_dir}" \
		AZURE_CLI_KEYRING_PATH="${keyring}" \
		AZURE_CLI_APT_CODENAME_OVERRIDE=noble \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "${INSTALL_AZURE}"

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"AZURE_CLI_APT_CODENAME_OVERRIDE activo"* ]]
	[[ "${output}" == *"Codename detectado: resolute"* ]]
	[[ "${output}" == *"Codename usado para repo: noble"* ]]
	[[ "${output}" == *"mezclando suites APT"* ]]
	[[ "$(cat "${source_dir}/azure-cli.list")" == *" noble main"* ]]
}

@test "install-azure-cli does not contain automatic resolute to noble fallback" {
	run grep -E "resolute.*noble|noble.*resolute" "${INSTALL_AZURE}"
	[[ "${status}" -ne 0 ]]
}

@test "install-azure-cli invalid source cleanup is opt-in and limited" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	local source_dir="${TEST_TEMP_DIR}/sources"
	local keyring="${TEST_TEMP_DIR}/keyrings/microsoft.gpg"
	local log="${TEST_TEMP_DIR}/commands.log"
	write_os_release "resolute"
	make_install_stubs "${stub_dir}"
	mkdir -p "${source_dir}" "$(dirname "${keyring}")"
	printf 'deb https://packages.microsoft.com/repos/azure-cli/ resolute main\n' >"${source_dir}/azure-cli.list"
	printf 'deb https://packages.microsoft.com/repos/edge/ stable main\n' >"${source_dir}/microsoft-edge.list"
	: >"${log}"

	run env \
		AZURE_TEST_LOG="${log}" \
		AZURE_TEST_STUB_DIR="${stub_dir}" \
		AZURE_CLI_OS_RELEASE_FILE="${TEST_TEMP_DIR}/os-release" \
		AZURE_CLI_SOURCE_DIR="${source_dir}" \
		AZURE_CLI_KEYRING_PATH="${keyring}" \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "${INSTALL_AZURE}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"No se limpia sin AZURE_CLI_CLEAN_INVALID_SOURCE=1"* ]]
	[[ -f "${source_dir}/azure-cli.list" ]]
	[[ -f "${source_dir}/microsoft-edge.list" ]]

	run env \
		DRY_RUN=1 \
		AZURE_TEST_LOG="${log}" \
		AZURE_TEST_STUB_DIR="${stub_dir}" \
		AZURE_CLI_OS_RELEASE_FILE="${TEST_TEMP_DIR}/os-release" \
		AZURE_CLI_SOURCE_DIR="${source_dir}" \
		AZURE_CLI_KEYRING_PATH="${keyring}" \
		AZURE_CLI_CLEAN_INVALID_SOURCE=1 \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "${INSTALL_AZURE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN activo: no se borrará nada"* ]]
	[[ -f "${source_dir}/azure-cli.list" ]]

	run env \
		AZURE_TEST_LOG="${log}" \
		AZURE_TEST_STUB_DIR="${stub_dir}" \
		AZURE_CLI_OS_RELEASE_FILE="${TEST_TEMP_DIR}/os-release" \
		AZURE_CLI_SOURCE_DIR="${source_dir}" \
		AZURE_CLI_KEYRING_PATH="${keyring}" \
		AZURE_CLI_CLEAN_INVALID_SOURCE=1 \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "${INSTALL_AZURE}"
	[[ "${status}" -ne 0 ]]
	[[ ! -e "${source_dir}/azure-cli.list" ]]
	[[ -f "${source_dir}/microsoft-edge.list" ]]
}

@test "install-azure-cli does not contain forbidden Azure operations" {
	local forbidden=(
		"az login"
		"az account set"
		"az group create"
		"az group delete"
		"az acr create"
		"az acr delete"
		"az containerapp create"
		"az containerapp delete"
		"az sql"
		"az keyvault"
	)

	local pattern
	for pattern in "${forbidden[@]}"; do
		run grep -F "${pattern}" "${INSTALL_AZURE}"
		[[ "${status}" -ne 0 ]]
	done
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
