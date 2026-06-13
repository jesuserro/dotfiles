#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"

RUN_DIR="${DOTFILES_UPDATE_RUN_DIR:-$(new_run_dir)}"
mkdir -p "$RUN_DIR"

if [[ "${OS:-}" == "Windows_NT" ]]; then
	echo "Run scripts/update/update-windows.ps1 from PowerShell on Windows."
	exit 1
fi

if command -v powershell.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
	powershell_args=(-NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "${SCRIPT_DIR}/update-windows.ps1")" -RunDir "$(wslpath -w "$RUN_DIR")")
	if is_truthy "${DOTFILES_WINGET_INCLUDE_UNKNOWN:-}"; then
		powershell_args+=(-IncludeUnknown)
	fi
	if [[ -n "${DOTFILES_WINGET_RETRY_FAILED_FROM_TSV:-}" ]]; then
		powershell_args+=(-RetryFailedFromTsv "$(wslpath -w "$DOTFILES_WINGET_RETRY_FAILED_FROM_TSV")")
	fi
	powershell.exe "${powershell_args[@]}"
else
	echo "powershell.exe and wslpath are required to run Windows update from WSL" >&2
	exit 1
fi
