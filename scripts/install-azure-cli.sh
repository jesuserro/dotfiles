#!/usr/bin/env bash
# Instalador opt-in e idempotente de Azure CLI para Debian/Ubuntu/WSL.
#
# Contrato:
#   - DRY_RUN=1: imprime el plan y no ejecuta sudo, apt-get, curl, gpg, tee ni az.
#   - Si `az` ya existe, no reinstala; solo informa ruta/versión fuera de DRY_RUN.
#   - No instala Docker Engine ni extensiones de Azure CLI.
#   - No inicia sesión, no selecciona suscripción, ni toca ~/.azure.
#   - No crea ni borra recursos Azure, no guarda secretos.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

APT_PREREQS=(ca-certificates curl apt-transport-https lsb-release gnupg)
AZURE_CLI_REPO_BASE="https://packages.microsoft.com/repos/azure-cli"
MICROSOFT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
KEYRING_PATH="${AZURE_CLI_KEYRING_PATH:-/etc/apt/keyrings/microsoft.gpg}"
SOURCE_DIR="${AZURE_CLI_SOURCE_DIR:-/etc/apt/sources.list.d}"
SOURCE_PATH="${SOURCE_DIR}/azure-cli.list"

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

safe_alternatives_hint() {
	echo "    Alternativas seguras:"
	echo "    - esperar soporte oficial de Microsoft para este codename;"
	echo "    - usar una distro WSL2 Ubuntu soportada por el repo Azure CLI;"
	echo "    - usar Azure Cloud Shell;"
	echo "    - usar Azure CLI desde Docker;"
	echo "    - usar AZURE_CLI_APT_CODENAME_OVERRIDE=<codename> solo si aceptas el riesgo."
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
	local os_release_file="${AZURE_CLI_OS_RELEASE_FILE:-/etc/os-release}"
	if [[ -r "${os_release_file}" ]]; then
		# shellcheck disable=SC1090
		source "${os_release_file}"
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

release_url_for_codename() {
	local codename="$1"
	printf '%s/dists/%s/Release' "${AZURE_CLI_REPO_BASE}" "${codename}"
}

select_repo_codename() {
	local detected_codename="$1"
	if [[ -n "${AZURE_CLI_APT_CODENAME_OVERRIDE:-}" ]]; then
		{
			install_label WARN "AZURE_CLI_APT_CODENAME_OVERRIDE activo."
			echo "       Codename detectado: ${detected_codename}"
			echo "       Codename usado para repo: ${AZURE_CLI_APT_CODENAME_OVERRIDE}"
			echo "       Riesgo: estás mezclando suites APT bajo tu responsabilidad."
		} >&2
		printf '%s' "${AZURE_CLI_APT_CODENAME_OVERRIDE}"
		return 0
	fi
	printf '%s' "${detected_codename}"
}

ensure_curl_available() {
	if command -v curl >/dev/null 2>&1; then
		return 0
	fi
	install_label FAIL "Falta 'curl'; no puedo validar el repo oficial Microsoft antes de tocar APT."
	return 1
}

ensure_release_supported() {
	local detected_codename="$1"
	local repo_codename="$2"
	local release_url="$3"

	echo ""
	echo "==> Validando soporte del repo oficial Microsoft Azure CLI"
	echo "    Codename detectado: ${detected_codename}"
	echo "    Codename usado para repo: ${repo_codename}"
	echo "    Release URL: ${release_url}"

	if curl -fsI "${release_url}" >/dev/null 2>&1; then
		install_label OK "Microsoft publica Azure CLI para '${repo_codename}'."
		return 0
	fi

	install_label FAIL "Microsoft no publica Azure CLI para el codename '${repo_codename}' en el repo oficial."
	echo "       Codename real detectado: ${detected_codename}"
	echo "       Codename usado para repo: ${repo_codename}"
	echo "       No se escribirá ${SOURCE_PATH}, no se ejecutará apt-get update contra ese repo"
	echo "       y no se intentará instalar azure-cli."
	safe_alternatives_hint
	return 1
}

is_dedicated_azure_cli_source_name() {
	case "$(basename "$1")" in
	azure-cli.list | azure-cli.sources | microsoft-azure-cli.list | *azure-cli*.list | *azure-cli*.sources)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

find_azure_cli_sources() {
	local source
	for source in "${SOURCE_DIR}"/*.list "${SOURCE_DIR}"/*.sources; do
		[[ -f "${source}" ]] || continue
		if grep -q "packages.microsoft.com/repos/azure-cli" "${source}" 2>/dev/null; then
			printf '%s\n' "${source}"
		fi
	done
}

handle_existing_azure_cli_sources() {
	local found=0 source dedicated=0 manual=0

	while IFS= read -r source; do
		[[ -n "${source}" ]] || continue
		found=1
		if is_dedicated_azure_cli_source_name "${source}"; then
			dedicated=1
			if dry; then
				install_label WARN "Fuente Azure CLI existente: ${source}"
				echo "       DRY_RUN activo: no se borrará nada."
			elif install_is_truthy "${AZURE_CLI_CLEAN_INVALID_SOURCE:-}"; then
				install_label WARN "Limpiando fuente Azure CLI dedicada: ${source}"
				run_as_root rm -f "${source}"
			else
				install_label WARN "Fuente Azure CLI existente: ${source}"
				echo "       No se limpia sin AZURE_CLI_CLEAN_INVALID_SOURCE=1."
			fi
		else
			manual=1
			install_label WARN "Fuente mixta con entrada Azure CLI: ${source}"
			echo "       No se limpiará automáticamente; revisa y elimina solo la entrada Azure CLI si procede."
		fi
	done < <(find_azure_cli_sources)

	if [[ ${found} -eq 0 ]]; then
		return 0
	fi
	if ((dedicated == 1 && manual == 0)) && ! dry && ! install_is_truthy "${AZURE_CLI_CLEAN_INVALID_SOURCE:-}"; then
		echo "       Para limpiar fuentes dedicadas antiguas: AZURE_CLI_CLEAN_INVALID_SOURCE=1 bash scripts/install-azure-cli.sh"
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
	local detected_codename="$1"
	local repo_codename="$2"
	local release_url="$3"
	local arch="${4:-<arquitectura-dpkg>}"
	local apt_cmd
	apt_cmd="$(apt_prefix)"

	echo ""
	echo "[DRY_RUN] Plan previsto:"
	echo "  1. Validar Debian/Ubuntu-like."
	echo "  2. Codename detectado: ${detected_codename}"
	echo "  3. Codename usado para repo: ${repo_codename}"
	echo "  4. Validar soporte del repo Microsoft con:"
	echo "       ${release_url}"
	echo "  5. Revisar fuentes Azure CLI previas en ${SOURCE_DIR}."
	echo "  6. Validar permisos para escribir en /etc."
	echo "  7. ${apt_cmd} update"
	echo "  8. ${apt_cmd} install -y ${APT_PREREQS[*]}"
	echo "  9. Descargar la clave Microsoft desde:"
	echo "       ${MICROSOFT_KEY_URL}"
	echo " 10. Convertirla a keyring GPG y guardarla en:"
	echo "       ${KEYRING_PATH}"
	echo " 11. Crear source dedicado:"
	echo "       deb [arch=${arch} signed-by=${KEYRING_PATH}] ${AZURE_CLI_REPO_BASE}/ ${repo_codename:-<codename>} main"
	echo "       ${SOURCE_PATH}"
	echo " 12. ${apt_cmd} update"
	echo " 13. ${apt_cmd} install -y azure-cli"
	echo " 14. Verificar con: az --version"
	echo ""
	echo "[DRY_RUN] No se instalará Docker Engine, no se instalará containerapp,"
	echo "          no se ejecutará login, no se tocará ~/.azure y no se hará red."
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

	run_as_root install -d -m 0755 "$(dirname "${KEYRING_PATH}")"
	run_as_root install -d -m 0755 "${SOURCE_DIR}"
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
	printf '    Login manual cuando lo necesites: az %s\n' "login"
}

main() {
	print_header

	if command -v az >/dev/null 2>&1; then
		print_already_present
		return 0
	fi

	ensure_debian_like

	local detected_codename repo_codename release_url arch
	detected_codename="$(detect_codename)"
	if [[ -z "${detected_codename}" ]]; then
		install_label FAIL "No pude detectar VERSION_CODENAME/UBUNTU_CODENAME desde /etc/os-release."
		manual_install_hint
		return 1
	fi
	repo_codename="$(select_repo_codename "${detected_codename}")"
	release_url="$(release_url_for_codename "${repo_codename}")"

	arch="<arquitectura-dpkg>"
	if ! dry; then
		ensure_curl_available
		handle_existing_azure_cli_sources
		ensure_release_supported "${detected_codename}" "${repo_codename}" "${release_url}"
		if ! command -v dpkg >/dev/null 2>&1; then
			install_label FAIL "Falta dpkg; este instalador espera un sistema Debian/Ubuntu funcional."
			return 1
		fi
		arch="$(dpkg --print-architecture)"
	else
		handle_existing_azure_cli_sources
	fi

	if dry; then
		print_dry_plan "${detected_codename}" "${repo_codename}" "${release_url}" "${arch}"
		return 0
	fi

	ensure_privilege_tooling
	install_prereqs
	require_runtime_tools
	configure_microsoft_repo "${repo_codename}" "${arch}"
	install_azure_cli
	verify_install
}

main "$@"
