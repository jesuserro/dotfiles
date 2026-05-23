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

run_step() {
	local area="$1" name="$2" log_file="$3"
	shift 3
	local start elapsed rc
	start="$(date +%s)"
	if "$@" > >(tee "$log_file") 2> >(tee -a "$log_file" >&2); then
		elapsed="$(($(date +%s) - start))"
		ok "${name} (${elapsed}s)"
		result_ok "$area" "$name" "completed in ${elapsed}s"
		return 0
	fi
	rc=$?
	elapsed="$(($(date +%s) - start))"
	incident "${name} failed with exit ${rc} (${elapsed}s); log: ${log_file}"
	result_incident "$area" "$name" "exit ${rc}; log: ${log_file}"
	return 0
}
