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
