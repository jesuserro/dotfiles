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
TOOL_SNAPSHOT_FILE="${RUN_DIR}/tool-snapshot.tsv"
result_init "$WSL_RESULTS"
tool_snapshot_init "$TOOL_SNAPSHOT_FILE"
export TOOL_SNAPSHOT_FILE

section "Dotfiles update"
info "Run directory: ${RUN_DIR}"

launch_windows_update() {
	if ! is_wsl; then
		result_info "Windows" "Windows tab" "not WSL; skipping Windows-side update"
		return 0
	fi
	if is_truthy "${DOTFILES_UPDATE_SKIP_WINDOWS:-}"; then
		result_skip "Windows" "Windows tab" "skipped by DOTFILES_UPDATE_SKIP_WINDOWS"
		return 0
	fi
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
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
		missing | missing-no-done)
			rm -f "$WINDOWS_RESULTS"
			;;
		partial-no-done)
			printf 'OK\tWindows\tWinGet sources\tmocked partial result before hang\nOK\tWindows\tWinGet packages\tmocked partial result before hang\n' >"$WINDOWS_RESULTS"
			;;
		*)
			printf 'WARN\tWindows\tWindows mock\tunknown DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=%s\n' "${DOTFILES_UPDATE_MOCK_WINDOWS_RESULT}" >"$WINDOWS_RESULTS"
			;;
		esac
		info "Windows update opened in separate PowerShell window; see that window for Windows results."
		return 0
	fi
	if ! command -v wt.exe >/dev/null 2>&1 || ! command -v powershell.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
		info "Windows update not launched: wt.exe, powershell.exe or wslpath unavailable."
		return 0
	fi
	local ps1 run_win script_win retry_tsv_win
	local -a powershell_args
	ps1="${SCRIPT_DIR}/update-windows.ps1"
	run_win="$(to_windows_path "$RUN_DIR")"
	script_win="$(to_windows_path "$ps1")"
	powershell_args=(-NoExit -ExecutionPolicy Bypass -File "$script_win" -RunDir "$run_win")
	if is_truthy "${DOTFILES_WINGET_INCLUDE_UNKNOWN:-}"; then
		powershell_args+=(-IncludeUnknown)
	fi
	if is_truthy "${DOTFILES_WINGET_SHOW_INVENTORY:-}"; then
		powershell_args+=(-ShowInventory)
	fi
	if [[ -n "${DOTFILES_WINGET_RETRY_FAILED_FROM_TSV:-}" ]]; then
		retry_tsv_win="$(to_windows_path "$DOTFILES_WINGET_RETRY_FAILED_FROM_TSV")"
		powershell_args+=(-RetryFailedFromTsv "$retry_tsv_win")
	fi
	if wt.exe -w 0 new-tab --title "make update - Windows" powershell.exe "${powershell_args[@]}" \; focus-tab -t 0 >/dev/null 2>&1; then
		info "Windows update opened in separate PowerShell window; see that window for Windows results."
	else
		info "Windows update not launched: could not open PowerShell tab."
	fi
}

launch_windows_update

section "WSL update"
DOTFILES_UPDATE_RUN_DIR="$RUN_DIR" "${SCRIPT_DIR}/update-wsl.sh" || true

if [[ -f "${RUN_DIR}/wsl-results.tsv" ]]; then
	WSL_RESULTS="${RUN_DIR}/wsl-results.tsv"
fi

section "Update summary"
result_print_concise_summary /dev/null "$WSL_RESULTS" "$TOOL_SNAPSHOT_FILE" "$LOG_DIR"

if result_has_incidents "$WSL_RESULTS"; then
	exit 0
fi
