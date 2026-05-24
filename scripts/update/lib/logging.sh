#!/usr/bin/env bash
# Minimal logging helpers for update scripts.
# shellcheck shell=bash

RUN_STEP_LAST_EXIT_CODE=0
RUN_STEP_LAST_STREAM_EXIT_CODE=0
# Read by update-wsl.sh after run_step/run_npm_step when rendering version probes.
RUN_STEP_LAST_RESULT_STATUS="OK"
RUN_STEP_LAST_LOG_FILE=""

section() {
	printf '\n> %s\n' "$1"
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
