#!/usr/bin/env bash
# Shared helpers for scripts/install-*.sh (sourced, not executed).
# shellcheck shell=bash

install_is_truthy() {
	case "${1:-}" in
	1 | true | TRUE | yes | YES | on | ON) return 0 ;;
	*) return 1 ;;
	esac
}

install_is_wsl() {
	[[ -r /proc/version ]] && grep -qi microsoft /proc/version
}

install_is_debian_like() {
	local os_id="" os_like=""
	if [[ -r /etc/os-release ]]; then
		# shellcheck disable=SC1091
		source /etc/os-release
		os_id="${ID:-}"
		os_like="${ID_LIKE:-}"
	fi
	[[ "${os_id}" == "ubuntu" || "${os_id}" == "debian" || "${os_like}" == *"debian"* ]]
}

install_label() {
	local state="$1"
	local msg="$2"
	printf '%-6s %s\n' "${state}" "${msg}"
}

# Run command unless DRY_RUN is truthy; then print what would run.
install_run_or_echo() {
	if install_is_truthy "${DRY_RUN:-}"; then
		printf '[DRY_RUN] Would run:'
		printf ' %q' "$@"
		printf '\n'
		return 0
	fi
	"$@"
}
