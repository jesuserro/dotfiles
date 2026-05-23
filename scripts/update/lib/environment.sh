#!/usr/bin/env bash
# Environment helpers for update orchestration.
# shellcheck shell=bash

is_truthy() {
	case "${1:-}" in
	1 | true | TRUE | yes | YES | on | ON) return 0 ;;
	*) return 1 ;;
	esac
}

is_wsl() {
	if is_truthy "${DOTFILES_FORCE_WSL:-}"; then
		return 0
	fi
	[[ -r /proc/version ]] && grep -qi microsoft /proc/version
}

default_update_root() {
	if is_wsl && command -v powershell.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
		local win_local
		win_local="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("LocalApplicationData")' 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
		if [[ -n "$win_local" ]]; then
			wslpath -u "${win_local}\\dotfiles\\update-runs" 2>/dev/null && return 0
		fi
	fi
	printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/update-runs"
}

new_run_dir() {
	local root run_id
	root="${DOTFILES_UPDATE_ROOT:-$(default_update_root)}"
	run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$"
	printf '%s/%s\n' "$root" "$run_id"
}

cleanup_old_update_runs() {
	local root="$1" current="${2:-}" keep="${DOTFILES_UPDATE_KEEP_RUNS:-10}" days="${DOTFILES_UPDATE_RETENTION_DAYS:-14}"
	[[ -d "$root" ]] || return 0
	local -A keep_paths=()
	local line rank deleted path current_real root_real
	root_real="$(realpath -m "$root")"
	current_real="$(realpath -m "${current:-/dev/null}")"
	rank=0
	while IFS= read -r line; do
		path="${line#* }"
		rank=$((rank + 1))
		if [[ "$rank" -le "$keep" ]]; then
			keep_paths["$(realpath -m "$path")"]=1
		fi
	done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -rn)

	deleted=0
	while IFS= read -r path; do
		path="$(realpath -m "$path")"
		[[ "$path" == "$current_real" ]] && continue
		[[ "$path" == "$root_real"/* ]] || continue
		[[ -n "${keep_paths[$path]:-}" ]] && continue
		rm -rf -- "$path"
		deleted=$((deleted + 1))
	done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -mtime "+$days" -print 2>/dev/null)
	if [[ "$deleted" -gt 0 ]]; then
		printf 'INFO   Removed %s old update run(s) from %s\n' "$deleted" "$root"
	fi
}

to_windows_path() {
	local path="$1"
	if command -v wslpath >/dev/null 2>&1; then
		wslpath -w "$path"
	else
		printf '%s\n' "$path"
	fi
}

node_major() {
	local version="${1#v}"
	printf '%s\n' "${version%%.*}"
}
