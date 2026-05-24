#!/usr/bin/env bash
# Minimal logging helpers for update scripts.
# shellcheck shell=bash

RUN_STEP_LAST_EXIT_CODE=0
RUN_STEP_LAST_STREAM_EXIT_CODE=0
# Read by update-wsl.sh after run_step/run_npm_step when rendering version probes.
RUN_STEP_LAST_RESULT_STATUS="OK"
RUN_STEP_LAST_LOG_FILE=""

section_id_for_title() {
	local title="${1:-}"
	case "$title" in
	"Dotfiles update") printf 'dotfiles' ;;
	"WSL update") printf 'wsl' ;;
	"APT") printf 'apt' ;;
	"Node and AI tools") printf 'node' ;;
	"OpenCode") printf 'opencode' ;;
	"Shell") printf 'shell' ;;
	"MCPs and Docker") printf 'mcp' ;;
	"Update summary") printf 'summary' ;;
	*) printf 'default' ;;
	esac
}

section_icon() {
	case "${1:-default}" in
	dotfiles) printf '↻' ;;
	wsl) printf '◆' ;;
	apt) printf '▣' ;;
	node) printf '⬢' ;;
	opencode) printf '⌘' ;;
	shell) printf '⌁' ;;
	mcp) printf '◇' ;;
	summary) printf '☰' ;;
	*) printf '◆' ;;
	esac
}

section_repeat() {
	local char="$1" count="${2:-0}" i
	for ((i = 0; i < count; i++)); do
		printf '%s' "$char"
	done
}

section() {
	local title="${1:-}" id width=64 left right_len
	id="$(section_id_for_title "$title")"
	if result_colors_enabled; then
		local color reset icon icon_part visible_len
		color=$'\033[0;36m'
		reset=$'\033[0m'
		icon_part=""
		if result_icons_enabled; then
			icon="$(section_icon "$id")"
			icon_part="${icon}  "
		fi
		left="━━━ ${icon_part}${title} "
		visible_len=$((${#left} + 1))
		right_len=$((width - visible_len))
		[[ "$right_len" -lt 6 ]] && right_len=6
		printf '\n%s%s%s%s\n' "$color" "$left" "$(section_repeat "━" "$right_len")" "$reset"
	else
		left="=== ${title} "
		visible_len=$((${#left} + 1))
		right_len=$((width - visible_len))
		[[ "$right_len" -lt 6 ]] && right_len=6
		printf '\n%s%s\n' "$left" "$(section_repeat "=" "$right_len")"
	fi
}

info() {
	result_print_status "INFO" "$1"
}

ok() {
	result_print_status "OK" "$1"
}

skip() {
	result_print_status "SKIP" "$1"
}

warn() {
	result_print_status "WARN" "$1"
}

fail() {
	result_print_status "FAIL" "$1"
}

incident() {
	fail "$1"
}

normalize_stream() {
	if command -v perl >/dev/null 2>&1; then
		perl -pe 's/\r/\n/g; s/\e\[[0-9;?]*[ -\/]*[@-~]//g'
	else
		tr '\r' '\n'
	fi
}

normalize_log() {
	local src="$1" dest="$2"
	normalize_stream <"$src" >"$dest"
}

stream_command_to_log() {
	local log_file="$1"
	shift
	local -a pipeline_status=()
	mkdir -p "$(dirname "$log_file")"
	: >"$log_file"
	set +e
	"$@" 2>&1 | normalize_stream | tee "$log_file"
	pipeline_status=("${PIPESTATUS[@]}")
	set -e
	RUN_STEP_LAST_EXIT_CODE="${pipeline_status[0]:-1}"
	RUN_STEP_LAST_STREAM_EXIT_CODE=0
	if [[ "${pipeline_status[1]:-0}" -ne 0 ]]; then
		RUN_STEP_LAST_STREAM_EXIT_CODE="${pipeline_status[1]}"
	elif [[ "${pipeline_status[2]:-0}" -ne 0 ]]; then
		RUN_STEP_LAST_STREAM_EXIT_CODE="${pipeline_status[2]}"
	fi
	RUN_STEP_LAST_LOG_FILE="$log_file"
}

finalize_step_result() {
	local area="$1" name="$2" start="$3"
	local elapsed rc stream_rc
	rc="${RUN_STEP_LAST_EXIT_CODE:-1}"
	stream_rc="${RUN_STEP_LAST_STREAM_EXIT_CODE:-0}"
	elapsed="$(($(date +%s) - start))"

	if [[ "$stream_rc" -ne 0 ]]; then
		fail "${name} log streaming failed with exit ${stream_rc} (${elapsed}s); command exit ${rc}; log: ${RUN_STEP_LAST_LOG_FILE}"
		result_fail "$area" "$name" "log stream exit ${stream_rc}; command exit ${rc}; log: ${RUN_STEP_LAST_LOG_FILE}"
		RUN_STEP_LAST_RESULT_STATUS="FAIL"
		return 0
	fi
	if [[ "$rc" -eq 0 ]]; then
		ok "${name} (${elapsed}s)"
		result_ok "$area" "$name" "completed in ${elapsed}s"
		RUN_STEP_LAST_RESULT_STATUS="OK"
		return 0
	fi
	fail "${name} failed with exit ${rc} (${elapsed}s); log: ${RUN_STEP_LAST_LOG_FILE}"
	result_fail "$area" "$name" "exit ${rc}; log: ${RUN_STEP_LAST_LOG_FILE}"
	RUN_STEP_LAST_RESULT_STATUS="FAIL"
	return 0
}

run_step() {
	local area="$1" name="$2" log_file="$3"
	shift 3
	local start
	start="$(date +%s)"
	stream_command_to_log "$log_file" "$@"
	finalize_step_result "$area" "$name" "$start"
	return 0
}

log_has_npm_warning() {
	local log_file="$1"
	[[ -f "$log_file" ]] && grep -Eiq '(^|[[:space:]])npm[[:space:]]+warn(ing)?([[:space:]]|$)' "$log_file"
}

run_npm_step() {
	local area="$1" name="$2" log_file="$3"
	shift 3
	local start elapsed rc stream_rc
	start="$(date +%s)"
	stream_command_to_log "$log_file" "$@"
	rc="${RUN_STEP_LAST_EXIT_CODE:-1}"
	stream_rc="${RUN_STEP_LAST_STREAM_EXIT_CODE:-0}"
	elapsed="$(($(date +%s) - start))"
	if [[ "$stream_rc" -ne 0 ]]; then
		fail "${name} log streaming failed with exit ${stream_rc} (${elapsed}s); command exit ${rc}; log: ${log_file}"
		result_fail "$area" "$name" "log stream exit ${stream_rc}; command exit ${rc}; log: ${log_file}"
		RUN_STEP_LAST_RESULT_STATUS="FAIL"
		return 0
	fi
	if [[ "$rc" -ne 0 ]]; then
		fail "${name} failed with exit ${rc} (${elapsed}s); log: ${log_file}"
		result_fail "$area" "$name" "exit ${rc}; log: ${log_file}"
		RUN_STEP_LAST_RESULT_STATUS="FAIL"
		return 0
	fi
	if log_has_npm_warning "$log_file"; then
		ok "${name} (${elapsed}s)"
		info "${name} completed with npm warnings; review log if relevant: ${log_file}"
		result_ok "$area" "$name" "completed in ${elapsed}s"
		result_info "$area" "${name} npm warnings" "completed with npm warnings; review log if relevant: ${log_file}"
		RUN_STEP_LAST_RESULT_STATUS="OK"
		return 0
	fi
	ok "${name} (${elapsed}s)"
	result_ok "$area" "$name" "completed in ${elapsed}s"
	RUN_STEP_LAST_RESULT_STATUS="OK"
	return 0
}
