#!/usr/bin/env bash
# Instalador opt-in e idempotente de Azure CLI para Debian/Ubuntu/WSL.
#
# Contrato:
#   - DRY_RUN=1: imprime el plan y no ejecuta sudo, apt-get, curl, gpg, tee ni az.
#   - Si `az` ya existe, no reinstala; solo informa ruta/versión fuera de DRY_RUN.
#   - No instala Docker Engine ni extensiones de Azure CLI.
#   - No ejecuta az login, az account set, ni toca ~/.azure.
#   - No crea ni borra recursos Azure, no guarda secretos.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

APT_PREREQS=(ca-certificates curl apt-transport-https lsb-release gnupg)
MICROSOFT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
KEYRING_PATH="/etc/apt/keyrings/microsoft.gpg"
SOURCE_PATH="/etc/apt/sources.list.d/azure-cli.list"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

az_version_line() {
	az --version 2>/dev/null | sed -n '1p'
}

print_header() {
	echo "==> install-azure-cli (opt-in, idempotente, repo oficial Microsoft)"
	if dry; then
		echo "[DRY_RUN] No se ejecutará sudo, apt-get, curl, gpg, tee ni az."
	fi
}

print_already_present() {
	local path
	path="$(command -v az)"
	if dry; then
		install_label OK "Azure CLI ya está en PATH: ${path}"
		echo "    DRY_RUN activo: no se ejecuta 'az --version'."
		return 0
	fi

	local version
	version="$(az_version_line || echo 'az (versión desconocida)')"
	install_label OK "Azure CLI ya está instalado en ${path} (${version})"
}

manual_install_hint() {
	echo "    Instalación manual recomendada:"
	echo "    https://learn.microsoft.com/cli/azure/install-azure-cli-linux"
}

ensure_debian_like() {
	if install_is_debian_like; then
		return 0
	fi
	install_label FAIL "Este instalador solo soporta Debian/Ubuntu-like."
	manual_install_hint
	return 1
}

detect_codename() {
	local os_id="" os_like="" version_codename="" ubuntu_codename=""
	if [[ -r /etc/os-release ]]; then
		# shellcheck disable=SC1091
		source /etc/os-release
		os_id="${ID:-}"
		os_like="${ID_LIKE:-}"
		version_codename="${VERSION_CODENAME:-}"
		ubuntu_codename="${UBUNTU_CODENAME:-}"
	fi

	if [[ "${os_id}" == "ubuntu" || "${os_like}" == *"ubuntu"* ]]; then
		printf '%s' "${ubuntu_codename:-${version_codename}}"
	else
		printf '%s' "${version_codename}"
	fi
}

apt_prefix() {
	if [[ ${EUID} -eq 0 ]]; then
		printf 'apt-get'
	else
		printf 'sudo apt-get'
	fi
}

ensure_privilege_tooling() {
	if [[ ${EUID} -eq 0 ]]; then
		return 0
	fi
	if ! command -v sudo >/dev/null 2>&1; then
		install_label FAIL "Falta sudo y no se está ejecutando como root; no puedo escribir en /etc ni usar apt-get."
		return 1
	fi
	if sudo -n true 2>/dev/null; then
		install_label OK "sudo disponible sin prompt interactivo."
	else
		install_label WARN "sudo pedirá contraseña si hace falta."
	fi
}

print_dry_plan() {
	local codename="$1"
	local arch="${2:-<arquitectura-dpkg>}"
	local apt_cmd
	apt_cmd="$(apt_prefix)"

	echo ""
	echo "[DRY_RUN] Plan previsto:"
	echo "  1. Validar Debian/Ubuntu-like y permisos para escribir en /etc."
	echo "  2. ${apt_cmd} update"
	echo "  3. ${apt_cmd} install -y ${APT_PREREQS[*]}"
	echo "  4. Descargar la clave Microsoft desde:"
	echo "       ${MICROSOFT_KEY_URL}"
	echo "  5. Convertirla a keyring GPG y guardarla en:"
	echo "       ${KEYRING_PATH}"
	echo "  6. Crear source dedicado:"
	echo "       deb [arch=${arch} signed-by=${KEYRING_PATH}] https://packages.microsoft.com/repos/azure-cli/ ${codename:-<codename>} main"
	echo "       ${SOURCE_PATH}"
	echo "  7. ${apt_cmd} update"
	echo "  8. ${apt_cmd} install -y azure-cli"
	echo "  9. Verificar con: az --version"
	echo ""
	echo "[DRY_RUN] No se instalará Docker Engine, no se instalará containerapp,"
	echo "          no se ejecutará login y no se tocará ~/.azure."
}

require_runtime_tools() {
	local missing=()
	for cmd in curl gpg; do
		if ! command -v "${cmd}" >/dev/null 2>&1; then
			missing+=("${cmd}")
		fi
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		install_label FAIL "Faltan prerequisitos tras instalar paquetes: ${missing[*]}"
		return 1
	fi
}

run_as_root() {
	if [[ ${EUID} -eq 0 ]]; then
		"$@"
	else
		sudo "$@"
	fi
}

install_prereqs() {
	echo ""
	echo "==> Instalando prerequisitos mínimos"
	run_as_root apt-get update
	run_as_root apt-get install -y "${APT_PREREQS[@]}"
}

configure_microsoft_repo() {
	local codename="$1"
	local arch="$2"
	local tmp_dir asc_file gpg_file source_file
	tmp_dir="$(mktemp -d -t install-azure-cli.XXXXXX)"
	# shellcheck disable=SC2064
	trap "rm -rf '${tmp_dir}'" EXIT INT TERM
	asc_file="${tmp_dir}/microsoft.asc"
	gpg_file="${tmp_dir}/microsoft.gpg"
	source_file="${tmp_dir}/azure-cli.list"

	echo ""
	echo "==> Configurando repo oficial Microsoft Azure CLI"
	curl -fsSL "${MICROSOFT_KEY_URL}" -o "${asc_file}"
	gpg --dearmor -o "${gpg_file}" "${asc_file}"
	chmod 0644 "${gpg_file}"
	printf 'deb [arch=%s signed-by=%s] https://packages.microsoft.com/repos/azure-cli/ %s main\n' \
		"${arch}" "${KEYRING_PATH}" "${codename}" >"${source_file}"

	run_as_root install -d -m 0755 /etc/apt/keyrings
	run_as_root install -m 0644 "${gpg_file}" "${KEYRING_PATH}"
	run_as_root install -m 0644 "${source_file}" "${SOURCE_PATH}"
}

install_azure_cli() {
	echo ""
	echo "==> Instalando azure-cli"
	run_as_root apt-get update
	run_as_root apt-get install -y azure-cli
}

verify_install() {
	if ! command -v az >/dev/null 2>&1; then
		install_label FAIL "La instalación terminó, pero 'az' no está en PATH."
		return 1
	fi
	local path version
	path="$(command -v az)"
	version="$(az_version_line || echo 'az (versión desconocida)')"
	install_label OK "Azure CLI instalado en ${path} (${version})"
	echo "    Login manual cuando lo necesites: az login"
}

main() {
	print_header

	if command -v az >/dev/null 2>&1; then
		print_already_present
		return 0
	fi

	ensure_debian_like

	local codename arch
	codename="$(detect_codename)"
	if [[ -z "${codename}" ]]; then
		install_label FAIL "No pude detectar VERSION_CODENAME/UBUNTU_CODENAME desde /etc/os-release."
		manual_install_hint
		return 1
	fi

	arch="<arquitectura-dpkg>"
	if ! dry; then
		if ! command -v dpkg >/dev/null 2>&1; then
			install_label FAIL "Falta dpkg; este instalador espera un sistema Debian/Ubuntu funcional."
			return 1
		fi
		arch="$(dpkg --print-architecture)"
	fi

	if dry; then
		print_dry_plan "${codename}" "${arch}"
		return 0
	fi

	ensure_privilege_tooling
	install_prereqs
	require_runtime_tools
	configure_microsoft_repo "${codename}" "${arch}"
	install_azure_cli
	verify_install
}

main "$@"
