#!/usr/bin/env bash
# Shared result writer/reader for dotfiles update runs.
# shellcheck shell=bash

RESULTS_FILE="${RESULTS_FILE:-}"

result_colors_enabled() {
	if [[ -n "${NO_COLOR:-}" || -n "${DOTFILES_UPDATE_PLAIN:-}" ]]; then
		return 1
	fi
	if [[ -n "${DOTFILES_UPDATE_FORCE_COLOR:-}" ]]; then
		return 0
	fi
	[[ -z "${CI:-}" ]] || return 1
	[[ -t 1 && -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]
}

result_icons_enabled() {
	if [[ -n "${NO_COLOR:-}" || -n "${DOTFILES_UPDATE_PLAIN:-}" ]]; then
		return 1
	fi
	if [[ -n "${DOTFILES_UPDATE_FORCE_COLOR:-}" ]]; then
		return 0
	fi
	[[ -z "${CI:-}" ]] || return 1
	[[ -t 1 && "${TERM:-}" != "dumb" && "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" == *UTF-8* ]]
}

result_status_label() {
	case "${1:-}" in
	INCIDENT) printf 'FAIL' ;;
	*) printf '%s' "${1:-INFO}" ;;
	esac
}

result_status_icon() {
	case "$(result_status_label "${1:-}")" in
	INFO) printf 'ℹ' ;;
	OK) printf '✔' ;;
	SKIP) printf '⏭' ;;
	WARN) printf '⚠' ;;
	FAIL) printf '✖' ;;
	*) printf '?' ;;
	esac
}

result_status_color() {
	case "$(result_status_label "${1:-}")" in
	INFO) printf '\033[0;34m' ;;
	OK) printf '\033[0;32m' ;;
	SKIP) printf '\033[0;36m' ;;
	WARN) printf '\033[1;33m' ;;
	FAIL) printf '\033[0;31m' ;;
	*) printf '' ;;
	esac
}

result_print_status() {
	local status label icon message indent color reset
	status="${1:-INFO}"
	message="${2:-}"
	indent="${3:-}"
	label="$(result_status_label "$status")"
	if result_colors_enabled; then
		color="$(result_status_color "$status")"
		reset=$'\033[0m'
		if result_icons_enabled; then
			icon="$(result_status_icon "$status")"
			printf '%s%s %s%-5s%s %s\n' "$indent" "$icon" "$color" "$label" "$reset" "$message"
		else
			printf '%s%s%-5s%s %s\n' "$indent" "$color" "$label" "$reset" "$message"
		fi
	else
		printf '%s%-5s %s\n' "$indent" "$label" "$message"
	fi
}

result_init() {
	local file="$1"
	mkdir -p "$(dirname "$file")"
	: >"$file"
	RESULTS_FILE="$file"
}

result_add() {
	local status="$1" area="$2" name="$3" message="$4"
	[[ -n "${RESULTS_FILE:-}" ]] || return 0
	printf '%s\t%s\t%s\t%s\n' "$status" "$area" "$name" "$message" >>"$RESULTS_FILE"
}

result_info() { result_add "INFO" "$1" "$2" "$3"; }
result_ok() { result_add "OK" "$1" "$2" "$3"; }
result_skip() { result_add "SKIP" "$1" "$2" "$3"; }
result_warn() { result_add "WARN" "$1" "$2" "$3"; }
result_fail() { result_add "FAIL" "$1" "$2" "$3"; }
result_incident() { result_fail "$1" "$2" "$3"; }

result_has_incidents() {
	local file="$1"
	[[ -f "$file" ]] && awk -F '\t' '$1=="WARN" || $1=="FAIL" || $1=="INCIDENT"{found=1} END{exit found ? 0 : 1}' "$file"
}

result_print_group() {
	local title="$1" file="$2" area="$3"
	printf '\n%s:\n' "$title"
	if [[ ! -f "$file" ]]; then
		result_print_status "WARN" "result file missing: ${file}" "  "
		return 0
	fi
	awk -F '\t' -v area="$area" '
		$2 == area {
			status = ($1 == "INCIDENT" ? "FAIL" : $1)
			printf "%s\t%s\t%s\n", status, $3, $4
			seen = 1
		}
		END {
			if (!seen) printf "INFO\t(no results)\tno results recorded\n"
		}
	' "$file" | while IFS=$'\t' read -r status name message; do
		result_print_status "$status" "${name}: ${message}" "  "
	done
}
