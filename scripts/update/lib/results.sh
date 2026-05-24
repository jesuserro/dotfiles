#!/usr/bin/env bash
# Shared result writer/reader for dotfiles update runs.
# shellcheck shell=bash

RESULTS_FILE="${RESULTS_FILE:-}"
TOOL_SNAPSHOT_FILE="${TOOL_SNAPSHOT_FILE:-}"

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

tool_snapshot_init() {
	local file="$1"
	mkdir -p "$(dirname "$file")"
	: >"$file"
	TOOL_SNAPSHOT_FILE="$file"
}

tool_snapshot_result() {
	local before="${1:-}" after="${2:-}"
	if [[ -z "$before" && -z "$after" ]]; then
		printf 'unavailable'
	elif [[ -z "$before" && -n "$after" ]]; then
		printf 'installed'
	elif [[ -n "$before" && -z "$after" ]]; then
		printf 'unavailable'
	elif [[ "$before" == "$after" ]]; then
		printf 'unchanged'
	else
		printf 'updated'
	fi
}

tool_snapshot_add() {
	local tool="$1" before="${2:-}" after="${3:-}" result
	[[ -n "${TOOL_SNAPSHOT_FILE:-}" ]] || return 0
	result="$(tool_snapshot_result "$before" "$after")"
	printf '%s\t%s\t%s\t%s\n' "$tool" "$before" "$after" "$result" >>"$TOOL_SNAPSHOT_FILE"
}

result_has_incidents() {
	local file="$1"
	[[ -f "$file" ]] && awk -F '\t' '$1=="WARN" || $1=="FAIL" || $1=="INCIDENT"{found=1} END{exit found ? 0 : 1}' "$file"
}

result_incident_count() {
	local file="$1"
	[[ -f "$file" ]] || {
		printf '0\n'
		return 0
	}
	awk -F '\t' '$1=="WARN" || $1=="FAIL" || $1=="INCIDENT"{count++} END{print count + 0}' "$file"
}

result_skip_count() {
	local file="$1"
	[[ -f "$file" ]] || {
		printf '0\n'
		return 0
	}
	awk -F '\t' '$1=="SKIP"{count++} END{print count + 0}' "$file"
}

result_visible_incident_count() {
	local file="$1" has_specific_winget=0
	[[ -f "$file" ]] || {
		printf '0\n'
		return 0
	}
	if awk -F '\t' '$1 ~ /^(WARN|FAIL|INCIDENT)$/ && $2=="Windows" && $3 ~ /^WinGet package .+\[[^]]+\]$/{found=1} END{exit found ? 0 : 1}' "$file"; then
		has_specific_winget=1
	fi
	awk -F '\t' -v has_specific_winget="$has_specific_winget" '
		$1 ~ /^(WARN|FAIL|INCIDENT)$/ {
			if (has_specific_winget && $2 == "Windows" && ($3 == "WinGet" || $3 == "WinGet packages" || $3 == "WinGet package details")) next
			count++
		}
		END {print count + 0}
	' "$file"
}

result_visible_skip_count() {
	local file="$1"
	[[ -f "$file" ]] || {
		printf '0\n'
		return 0
	}
	awk -F '\t' '$1=="SKIP"{key=$2 "\t" $3; if (!seen[key]++) count++} END{print count + 0}' "$file"
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

result_incident_display_name() {
	local area="$1" name="$2"
	if [[ "$area" == "Windows" && "$name" =~ ^WinGet\ package\ (.+)\ \[[^]]+\]$ ]]; then
		printf 'Windows / WinGet / %s' "${BASH_REMATCH[1]}"
	elif [[ "$area" == "Windows" && "$name" == "WinGet" ]]; then
		printf 'Windows / WinGet'
	elif [[ "$area" == "Windows" && "$name" == "WinGet packages" ]]; then
		printf 'Windows / WinGet'
	else
		printf '%s / %s' "$area" "$name"
	fi
}

result_print_incidents() {
	local file="$1" has_specific_winget=0 winget_log=""
	[[ -f "$file" ]] || return 0
	if awk -F '\t' '$1 ~ /^(WARN|FAIL|INCIDENT)$/ && $2=="Windows" && $3 ~ /^WinGet package .+\[[^]]+\]$/{found=1} END{exit found ? 0 : 1}' "$file"; then
		has_specific_winget=1
		winget_log="$(awk -F '\t' '$2=="Windows" && ($3=="WinGet" || $3=="WinGet packages") && $4 ~ /log: /{sub(/^.*log: /, "", $4); print $4; exit}' "$file")"
	fi
	awk -F '\t' -v has_specific_winget="$has_specific_winget" '
		$1 ~ /^(WARN|FAIL|INCIDENT)$/ {
			if (has_specific_winget && $2 == "Windows" && ($3 == "WinGet" || $3 == "WinGet packages" || $3 == "WinGet package details")) next
			status = ($1 == "INCIDENT" ? "FAIL" : $1)
			printf "%s\t%s\t%s\t%s\n", status, $2, $3, $4
		}
	' "$file" | while IFS=$'\t' read -r status area name message; do
		result_print_status "$status" "$(result_incident_display_name "$area" "$name"): ${message}" "  "
		if [[ -n "$winget_log" && "$area" == "Windows" && "$name" =~ ^WinGet\ package\ .+\[[^]]+\]$ ]]; then
			printf '       log: %s\n' "$winget_log"
		fi
	done
}

result_print_skips() {
	local file="$1"
	[[ -f "$file" ]] || return 0
	awk -F '\t' '$1=="SKIP"{key=$2 "\t" $3; if (!seen[key]++) printf "%s\t%s\t%s\n", $2, $3, $4}' "$file" |
		while IFS=$'\t' read -r area name message; do
			local summary="${message%%;*}"
			result_print_status "SKIP" "${name}: ${summary}" "  "
			if [[ "$name" == "Excalidraw Docker" ]]; then
				printf '       run: make excalidraw-update after starting Docker Desktop\n'
			fi
		done
}

tool_snapshot_print() {
	local file="$1"
	[[ -s "$file" ]] || return 0
	printf '  %-22s %-14s %-14s %s\n' "Tool" "Before" "After" "Result"
	printf '  %-22s %-14s %-14s %s\n' "----------------------" "--------------" "--------------" "----------"
	awk -F '\t' '
		{
			key=$1
			rows[key]=$0
			if (!(key in order)) {
				order[key]=++count
				names[count]=key
			}
		}
		END {
			for (i=1; i<=count; i++) print rows[names[i]]
		}
	' "$file" | while IFS=$'\t' read -r tool before after result; do
		before="${before:-"-"}"
		after="${after:-"-"}"
		if result_colors_enabled && [[ "$result" =~ ^(updated|installed)$ ]]; then
			local green reset
			green=$'\033[0;32m'
			reset=$'\033[0m'
			printf '  %s%-22s %-14s %-14s %s%s\n' "$green" "$tool" "$before" "$after" "$result" "$reset"
		else
			printf '  %-22s %-14s %-14s %s\n' "$tool" "$before" "$after" "$result"
		fi
	done
}

result_print_concise_summary() {
	local windows_file="$1" wsl_file="$2" snapshot_file="$3" log_dir="$4"
	local incidents skips incident_names skip_names
	incidents=$(($(result_visible_incident_count "$windows_file") + $(result_visible_incident_count "$wsl_file")))
	skips=$(($(result_visible_skip_count "$windows_file") + $(result_visible_skip_count "$wsl_file")))

	if [[ "$incidents" -gt 0 ]]; then
		printf '\nIncidents\n'
		result_print_incidents "$windows_file"
		result_print_incidents "$wsl_file"
	fi

	if [[ "$skips" -gt 0 ]]; then
		printf '\nSkipped\n'
		result_print_skips "$windows_file"
		result_print_skips "$wsl_file"
	fi

	if [[ -s "$snapshot_file" ]]; then
		printf '\nTool snapshot\n'
		tool_snapshot_print "$snapshot_file"
	fi

	incident_names="$(
		{
			[[ -f "$windows_file" ]] && cat "$windows_file"
			[[ -f "$wsl_file" ]] && cat "$wsl_file"
		} | awk -F '\t' '
			$1 ~ /^(WARN|FAIL|INCIDENT)$/ {
				if ($2 == "Windows" && $3 ~ /^WinGet package .+\[[^]]+\]$/) {
					name=$3
					sub(/^WinGet package /, "", name)
					sub(/ \[[^]]+\]$/, "", name)
					print "Windows / WinGet / " name
				} else if ($2 == "Windows" && ($3 == "WinGet" || $3 == "WinGet packages" || $3 == "WinGet package details")) {
					if (!specific_winget) pending_winget="Windows / WinGet"
				} else {
					print $2 " / " $3
				}
				if ($2 == "Windows" && $3 ~ /^WinGet package .+\[[^]]+\]$/) specific_winget=1
			}
			END {
				if (pending_winget && !specific_winget) print pending_winget
			}
		' | awk '!seen[$0]++' | awk 'BEGIN{sep=""} {printf "%s%s", sep, $0; sep="; "} END{print ""}'
	)"
	skip_names="$(
		{
			[[ -f "$windows_file" ]] && cat "$windows_file"
			[[ -f "$wsl_file" ]] && cat "$wsl_file"
		} | awk -F '\t' '$1=="SKIP"{print $3}' | awk '!seen[$0]++' | awk 'BEGIN{sep=""} {printf "%s%s", sep, $0; sep="; "} END{print ""}'
	)"

	if [[ "$incidents" -gt 0 ]]; then
		printf '\nCompleted with %d incident%s: %s.\n' "$incidents" "$([[ "$incidents" -eq 1 ]] && printf '' || printf 's')" "${incident_names:-see details above}"
	else
		printf '\nCompleted successfully.'
		if [[ "$skips" -gt 0 ]]; then
			printf ' %d optional step%s skipped' "$skips" "$([[ "$skips" -eq 1 ]] && printf '' || printf 's')"
			[[ -n "$skip_names" ]] && printf ': %s' "$skip_names"
			printf '.'
		fi
		printf '\n'
	fi
	if [[ "$incidents" -gt 0 && "$skips" -gt 0 ]]; then
		printf '%d optional step%s skipped' "$skips" "$([[ "$skips" -eq 1 ]] && printf '' || printf 's')"
		[[ -n "$skip_names" ]] && printf ': %s' "$skip_names"
		printf '.\n'
	fi
	printf 'Logs: %s\n' "$log_dir"
}
