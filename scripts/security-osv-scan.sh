#!/usr/bin/env bash
# Repository osv-scanner gate for make security-osv / security-check.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SECURITY_ONLINE="${SECURITY_ONLINE:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/osv_scan.sh
source "${SCRIPT_DIR}/lib/osv_scan.sh"

if ! has_osv_scan_inputs "${DOTFILES_DIR}"; then
	printf '==> osv-scanner skipped: no supported manifests or lockfiles found\n'
	exit 0
fi

if ! command -v osv-scanner >/dev/null 2>&1; then
	printf 'Missing security dependency: osv-scanner\n' >&2
	printf 'Run: make install-agent-tools\n' >&2
	exit 1
fi

printf '==> osv-scanner repository scan'
if [[ "${SECURITY_ONLINE}" == "1" ]]; then
	printf ' (SECURITY_ONLINE=1 strict)\n'
else
	printf ' (best-effort; set SECURITY_ONLINE=1 to fail on remote outages)\n'
fi

if run_osv_repo_scan "${DOTFILES_DIR}" "${SECURITY_ONLINE}"; then
	printf '==> osv-scanner completed\n'
	exit 0
fi

exit 1
