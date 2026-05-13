#!/usr/bin/env bash
# Read-only Azure workstation readiness check for WSL2/Linux.
# This script never logs in, selects subscriptions, creates resources, or deletes
# resources. It only checks local tooling and reports actionable next steps.

set -u

critical_missing=0
warnings=0

section() {
	printf '\n==> %s\n' "$1"
}

line() {
	local state="$1"
	local msg="$2"
	printf '%-6s %s\n' "${state}" "${msg}"
}

warn() {
	warnings=$((warnings + 1))
	line "WARN" "$1"
}

missing_critical() {
	critical_missing=$((critical_missing + 1))
	line "MISS" "$1"
}

first_line() {
	printf '%s\n' "$1" | sed -n '1p'
}

command_version() {
	local cmd="$1"
	shift
	local output
	output="$("$cmd" "$@" 2>&1)"
	first_line "${output}"
}

check_required_command() {
	local label="$1"
	local cmd="$2"
	shift 2

	if command -v "${cmd}" >/dev/null 2>&1; then
		local version
		version="$(command_version "${cmd}" "$@")"
		line "OK" "${label}: ${version:-${cmd} disponible}"
	else
		missing_critical "${label}: falta '${cmd}'"
	fi
}

check_recommended_command() {
	local label="$1"
	local cmd="$2"
	shift 2

	if command -v "${cmd}" >/dev/null 2>&1; then
		local version
		version="$(command_version "${cmd}" "$@")"
		line "OK" "${label}: ${version:-${cmd} disponible}"
	else
		warn "${label}: '${cmd}' no está disponible"
	fi
}

check_any_recommended_command() {
	local label="$1"
	local first="$2"
	local second="$3"
	shift 3

	if command -v "${first}" >/dev/null 2>&1; then
		local version
		version="$(command_version "${first}" "$@")"
		line "OK" "${label}: ${version:-${first} disponible}"
	elif command -v "${second}" >/dev/null 2>&1; then
		local version
		version="$(command_version "${second}" "$@")"
		line "OK" "${label}: ${version:-${second} disponible}"
	else
		warn "${label}: falta '${first}' o '${second}'"
	fi
}

section "Herramientas críticas"
if command -v az >/dev/null 2>&1; then
	az_version="$(az version --query '"azure-cli"' --output tsv 2>/dev/null)"
	if [[ -n "${az_version}" ]]; then
		line "OK" "Azure CLI: az ${az_version}"
	else
		line "OK" "Azure CLI: az disponible"
	fi
else
	missing_critical "Azure CLI: falta 'az'"
fi

check_required_command "Git" git --version
check_required_command "Make" make --version
check_required_command "jq" jq --version
check_required_command "curl" curl --version

if command -v docker >/dev/null 2>&1; then
	docker_version="$(command_version docker --version)"
	line "OK" "Docker CLI: ${docker_version:-docker disponible}"
	if docker compose version >/dev/null 2>&1; then
		compose_version="$(command_version docker compose version)"
		line "OK" "Docker Compose: ${compose_version:-docker compose disponible}"
	else
		missing_critical "Docker Compose: 'docker compose version' no responde"
		warn "En Windows 11 Pro + WSL2 se recomienda Docker Desktop con integración WSL activada."
	fi
else
	missing_critical "Docker CLI: falta 'docker'"
	missing_critical "Docker Compose: no se puede comprobar sin Docker CLI"
	warn "En Windows 11 Pro + WSL2 se recomienda Docker Desktop con integración WSL activada."
fi

section "Herramientas recomendadas"
check_recommended_command "GitHub CLI" gh --version
check_recommended_command "yq" yq --version
check_recommended_command "unzip" unzip -v
check_any_recommended_command "GnuPG" gpg gnupg --version
check_any_recommended_command "lsb-release" lsb_release lsb-release --version

section "Azure CLI"
if command -v az >/dev/null 2>&1; then
	if az account show --output table >/dev/null 2>&1; then
		line "OK" "Sesión Azure activa:"
		az account show --output table 2>/dev/null
	else
		warn "No hay sesión Azure activa o no se pudo leer la cuenta actual."
		printf '       Para iniciar sesión manualmente: az %s\n' "login"
	fi

	if az extension show --name containerapp --output table >/dev/null 2>&1; then
		line "OK" "Extensión Azure CLI 'containerapp' disponible:"
		az extension show --name containerapp --output table 2>/dev/null
	else
		warn "Extensión Azure CLI 'containerapp' no disponible."
		printf '       Recomendación: az extension add --name containerapp --upgrade\n'
	fi
else
	warn "Se omiten checks de sesión y extensión porque 'az' no está instalado."
fi

section "Resumen"
printf 'Críticos faltantes: %d | Avisos: %d\n' "${critical_missing}" "${warnings}"

if [[ ${critical_missing} -gt 0 ]]; then
	line "FAIL" "Faltan herramientas críticas para operar Azure desde estos dotfiles."
	exit 1
fi

line "PASS" "Herramientas críticas disponibles. Revisa los avisos antes de desplegar."
exit 0
