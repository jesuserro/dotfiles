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
cleanup_old_update_runs "$(dirname "$RUN_DIR")" "$RUN_DIR"
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
		local mock_done
		mock_done=1
		case "${DOTFILES_UPDATE_MOCK_WINDOWS_RESULT:-winget-failure}" in
		ok)
			printf 'OK\tWindows\tWinGet\tmocked winget success\nOK\tWindows\tWSL update\tmocked wsl --update\n' >"$WINDOWS_RESULTS"
			;;
		winget-fallback-with-parseable-log)
			printf 'WARN\tWindows\tWinGet packages\texit -1978335188 in 19s; log: %s\nWARN\tWindows\tWinGet package details\tcould not parse package-level results; see log: %s\nOK\tWindows\tWSL update\tmocked wsl --update\n' "${LOG_DIR}/windows-winget-upgrade.log" "${LOG_DIR}/windows-winget-upgrade.log" >"$WINDOWS_RESULTS"
			cat >"${LOG_DIR}/windows-winget-upgrade.log" <<'EOF'
(1/2) Encontrado Pandoc [JohnMacFarlane.Pandoc] Versi├│n 3.9.0.2
Error de desinstalaci├│n con el c├│digo de salida: 1603

(2/2) Encontrado Microsoft Teams [Microsoft.Teams] Versi├│n 26106.1911.4707.3286
Se instal├│ correctamente. Reinicie la aplicaci├│n para completar la actualizaci├│n.
EOF
			;;
		winget-failure)
			printf 'WARN\tWindows\tWinGet\tPandoc failed with installer exit code 1603\nOK\tWindows\tWSL update\tmocked wsl --update\n' >"$WINDOWS_RESULTS"
			;;
		wsl-failure)
			printf 'OK\tWindows\tWinGet\tmocked winget success\nWARN\tWindows\tWSL update\twsl --update failed with exit 1\n' >"$WINDOWS_RESULTS"
			;;
		multi-failure)
			printf 'WARN\tWindows\tWinGet\tPandoc failed with installer exit code 1603\nWARN\tWindows\tWSL update\twsl --update failed with exit 1\n' >"$WINDOWS_RESULTS"
			;;
		empty)
			: >"$WINDOWS_RESULTS"
			;;
		missing)
			rm -f "$WINDOWS_RESULTS"
			;;
		missing-no-done)
			rm -f "$WINDOWS_RESULTS"
			mock_done=0
			;;
		partial-no-done)
			printf 'OK\tWindows\tWinGet sources\tmocked partial result before hang\nOK\tWindows\tWinGet packages\tmocked partial result before hang\n' >"$WINDOWS_RESULTS"
			mock_done=0
			;;
		*)
			printf 'WARN\tWindows\tWindows mock\tunknown DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=%s\n' "${DOTFILES_UPDATE_MOCK_WINDOWS_RESULT}" >"$WINDOWS_RESULTS"
			;;
		esac
		if [[ "$mock_done" -eq 1 ]]; then
			: >"$WINDOWS_DONE"
		fi
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
windows_timed_out=0
if [[ ! -f "$WINDOWS_DONE" ]] && is_wsl && ! is_truthy "${DOTFILES_UPDATE_SKIP_WINDOWS:-}"; then
	windows_timeout="${DOTFILES_UPDATE_WINDOWS_TIMEOUT:-600}"
	progress_interval="${DOTFILES_UPDATE_WAIT_PROGRESS_INTERVAL:-30}"
	deadline=$((SECONDS + windows_timeout))
	wait_started="$SECONDS"
	next_progress=$((SECONDS + progress_interval))
	while [[ ! -f "$WINDOWS_DONE" && $SECONDS -lt $deadline ]]; do
		if [[ "$SECONDS" -ge "$next_progress" ]]; then
			info "Waiting for Windows update result... elapsed $((SECONDS - wait_started))s / timeout ${windows_timeout}s; run dir: ${RUN_DIR}"
			next_progress=$((SECONDS + progress_interval))
		fi
		sleep 1
	done
	if [[ ! -f "$WINDOWS_DONE" ]]; then
		windows_timed_out=1
	fi
fi
if [[ ! -s "$WINDOWS_RESULTS" ]]; then
	printf 'WARN\tWindows\tWindows result\tNo structured Windows result was produced before timeout (%ss); run dir: %s; partial logs: %s\n' "${DOTFILES_UPDATE_WINDOWS_TIMEOUT:-600}" "$RUN_DIR" "$LOG_DIR" >"$WINDOWS_RESULTS"
elif [[ "$windows_timed_out" -eq 1 ]]; then
	printf 'WARN\tWindows\tWindows result\tWindows update did not write windows.done before timeout (%ss); using partial results; run dir: %s; partial logs: %s\n' "${DOTFILES_UPDATE_WINDOWS_TIMEOUT:-600}" "$RUN_DIR" "$LOG_DIR" >>"$WINDOWS_RESULTS"
fi
if [[ -f "${LOG_DIR}/windows-winget-upgrade.log" ]] && ! grep -Eq $'\tWindows\tWinGet package .+\\[[^]]+\\]\t' "$WINDOWS_RESULTS"; then
	parsed_winget="$(mktemp)"
	if python3 "${SCRIPT_DIR}/parse-winget-log.py" "${LOG_DIR}/windows-winget-upgrade.log" >"$parsed_winget" && [[ -s "$parsed_winget" ]]; then
		grep -v $'\tWindows\tWinGet package details\tcould not parse package-level results' "$WINDOWS_RESULTS" >"${parsed_winget}.results" || true
		cat "$parsed_winget" >>"${parsed_winget}.results"
		mv "${parsed_winget}.results" "$WINDOWS_RESULTS"
	fi
	rm -f "$parsed_winget" "${parsed_winget}.results"
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
