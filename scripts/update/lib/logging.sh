#!/usr/bin/env bash
# Minimal logging helpers for update scripts.
# shellcheck shell=bash

section() {
	printf '\n==> %s\n' "$1"
}

info() {
	printf 'INFO   %s\n' "$1"
}

ok() {
	printf 'OK     %s\n' "$1"
}

warn() {
	printf 'WARN   %s\n' "$1"
}

incident() {
	printf 'WARN   %s\n' "$1"
}

normalize_log() {
	local src="$1" dest="$2"
	if command -v perl >/dev/null 2>&1; then
		perl -pe 's/\r/\n/g; s/\e\[[0-9;?]*[ -\/]*[@-~]//g' "$src" >"$dest"
	else
		tr '\r' '\n' <"$src" >"$dest"
	fi
}

run_step() {
	local area="$1" name="$2" log_file="$3"
	shift 3
	local start elapsed rc raw_log
	start="$(date +%s)"
	mkdir -p "$(dirname "$log_file")"
	raw_log="${log_file}.raw"
	set +e
	"$@" >"$raw_log" 2>&1
	rc=$?
	set -e
	normalize_log "$raw_log" "$log_file"
	rm -f "$raw_log"
	[[ -s "$log_file" ]] && cat "$log_file"
	elapsed="$(($(date +%s) - start))"
	if [[ "$rc" -eq 0 ]]; then
		elapsed="$(($(date +%s) - start))"
		ok "${name} (${elapsed}s)"
		result_ok "$area" "$name" "completed in ${elapsed}s"
		return 0
	fi
	incident "${name} failed with exit ${rc} (${elapsed}s); log: ${log_file}"
	result_incident "$area" "$name" "exit ${rc}; log: ${log_file}"
	return 0
}

log_has_npm_warning() {
	local log_file="$1"
	[[ -f "$log_file" ]] && grep -Eiq '(^|[[:space:]])npm[[:space:]]+warn(ing)?([[:space:]]|$)' "$log_file"
}

run_npm_step() {
	local area="$1" name="$2" log_file="$3"
	shift 3
	local start elapsed rc raw_log
	start="$(date +%s)"
	mkdir -p "$(dirname "$log_file")"
	raw_log="${log_file}.raw"
	set +e
	"$@" >"$raw_log" 2>&1
	rc=$?
	set -e
	normalize_log "$raw_log" "$log_file"
	rm -f "$raw_log"
	[[ -s "$log_file" ]] && cat "$log_file"
	elapsed="$(($(date +%s) - start))"
	if [[ "$rc" -ne 0 ]]; then
		incident "${name} failed with exit ${rc} (${elapsed}s); log: ${log_file}"
		result_incident "$area" "$name" "exit ${rc}; log: ${log_file}"
		return 0
	fi
	if log_has_npm_warning "$log_file"; then
		warn "${name} completed with npm warnings (${elapsed}s); log: ${log_file}"
		result_warn "$area" "$name" "completed with npm warnings; log: ${log_file}"
		return 0
	fi
	ok "${name} (${elapsed}s)"
	result_ok "$area" "$name" "completed in ${elapsed}s"
	return 0
}
