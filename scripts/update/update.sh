#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"
# shellcheck source=scripts/update/lib/results.sh
source "${SCRIPT_DIR}/lib/results.sh"
# shellcheck source=scripts/update/lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"

RUN_DIR="${DOTFILES_UPDATE_RUN_DIR:-$(new_run_dir)}"
LOG_DIR="${RUN_DIR}/logs"
mkdir -p "$LOG_DIR"
WSL_RESULTS="${RUN_DIR}/wsl-results.tsv"
WINDOWS_RESULTS="${RUN_DIR}/windows-results.tsv"
WINDOWS_DONE="${RUN_DIR}/windows.done"
result_init "$WSL_RESULTS"

section "Dotfiles update"
info "Run directory: ${RUN_DIR}"

launch_windows_update() {
	if ! is_wsl; then
		result_info "Windows" "Windows tab" "not WSL; skipping Windows-side update"
		return 0
	fi
	if is_truthy "${DOTFILES_UPDATE_SKIP_WINDOWS:-}"; then
		result_warn "Windows" "Windows tab" "skipped by DOTFILES_UPDATE_SKIP_WINDOWS"
		return 0
	fi
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		printf 'WARN\tWindows\tWinGet\tmocked winget warning\nOK\tWindows\tWSL update\tmocked wsl --update\n' >"$WINDOWS_RESULTS"
		: >"$WINDOWS_DONE"
		result_ok "Windows" "Windows tab" "mocked result written"
		return 0
	fi
	if ! command -v wt.exe >/dev/null 2>&1 || ! command -v powershell.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
		result_warn "Windows" "Windows tab" "wt.exe, powershell.exe or wslpath unavailable; Windows update not launched"
		return 0
	fi
	local ps1 run_win script_win
	ps1="${SCRIPT_DIR}/update-windows.ps1"
	run_win="$(to_windows_path "$RUN_DIR")"
	script_win="$(to_windows_path "$ps1")"
	if wt.exe -w 0 new-tab --title "make update - Windows" powershell.exe -NoExit -ExecutionPolicy Bypass -File "$script_win" -RunDir "$run_win" \; focus-tab -t 0 >/dev/null 2>&1; then
		result_ok "Windows" "Windows tab" "PowerShell tab launched"
	else
		result_warn "Windows" "Windows tab" "could not open PowerShell tab"
	fi
}

launch_windows_update

section "WSL update"
DOTFILES_UPDATE_RUN_DIR="$RUN_DIR" "${SCRIPT_DIR}/update-wsl.sh" || true

if [[ -f "${RUN_DIR}/wsl-results.tsv" ]]; then
	WSL_RESULTS="${RUN_DIR}/wsl-results.tsv"
fi

section "Waiting for Windows result"
if [[ ! -f "$WINDOWS_DONE" ]] && is_wsl && ! is_truthy "${DOTFILES_UPDATE_SKIP_WINDOWS:-}"; then
	deadline=$((SECONDS + ${DOTFILES_UPDATE_WINDOWS_TIMEOUT:-7200}))
	while [[ ! -f "$WINDOWS_DONE" && $SECONDS -lt $deadline ]]; do
		sleep 2
	done
fi
if [[ ! -f "$WINDOWS_RESULTS" ]]; then
	printf 'WARN\tWindows\tWindows result\tNo structured Windows result was produced\n' >"$WINDOWS_RESULTS"
fi

section "Consolidated summary"
result_print_group "Windows" "$WINDOWS_RESULTS" "Windows"
result_print_group "WSL" "$WSL_RESULTS" "WSL"
printf '\nProjects:\n  - INFO Personal projects are not part of make update; use make update-projects\n'

if result_has_incidents "$WINDOWS_RESULTS" || result_has_incidents "$WSL_RESULTS"; then
	printf '\nCompleted with incidents. Logs: %s\n' "$LOG_DIR"
	exit 0
fi
printf '\nCompleted without recorded incidents. Logs: %s\n' "$LOG_DIR"
