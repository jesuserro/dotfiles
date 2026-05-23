#!/usr/bin/env bash
# Shared result writer/reader for dotfiles update runs.
# shellcheck shell=bash

RESULTS_FILE="${RESULTS_FILE:-}"

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
result_warn() { result_add "WARN" "$1" "$2" "$3"; }
result_incident() { result_add "INCIDENT" "$1" "$2" "$3"; }

result_has_incidents() {
	local file="$1"
	[[ -f "$file" ]] && awk -F '\t' '$1=="WARN" || $1=="INCIDENT"{found=1} END{exit found ? 0 : 1}' "$file"
}

result_print_group() {
	local title="$1" file="$2" area="$3"
	printf '\n%s:\n' "$title"
	if [[ ! -f "$file" ]]; then
		printf '  - WARN result file missing: %s\n' "$file"
		return 0
	fi
	awk -F '\t' -v area="$area" '
		$2 == area {
			icon = ($1 == "OK" ? "OK" : ($1 == "INFO" ? "INFO" : "WARN"))
			printf "  - %s %s: %s\n", icon, $3, $4
			seen = 1
		}
		END {
			if (!seen) printf "  - INFO no results recorded\n"
		}
	' "$file"
}
