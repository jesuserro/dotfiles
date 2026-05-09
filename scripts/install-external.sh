#!/usr/bin/env bash
# Non-aggressive guidance for external / Windows-side tooling (no silent installers).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if install_is_truthy "${SKIP_EXTERNAL:-}"; then
	echo "SKIP_EXTERNAL=1 — skipping external recommendations block."
	exit 0
fi

echo "==> External / non-APT dependencies (recommended actions only)"
if install_is_truthy "${DRY_RUN:-}"; then
	echo "[DRY_RUN] No changes or remote installs will be performed."
fi

docker_section() {
	echo ""
	echo "==> Docker (detection only)"
	if install_is_truthy "${SKIP_DOCKER:-}"; then
		install_label WARN "SKIP_DOCKER=1 — skipping Docker guidance"
		return 0
	fi
	if command -v docker >/dev/null 2>&1; then
		install_label OK "docker CLI in PATH"
		if docker info >/dev/null 2>&1; then
			install_label OK "Docker daemon responds (docker info)"
		else
			install_label WARN "Docker CLI present but daemon not reachable — start Docker Desktop / dockerd, or check WSL integration"
		fi
	else
		install_label WARN "docker CLI missing — install Docker Desktop + WSL integration or Docker Engine manually (no auto-install from this script)"
	fi
}

docker_section

echo ""
echo "==> Canonical next steps from declarative inventory (deps-actions)"
ACTIONS_SCRIPT="${DOTFILES_ROOT}/scripts/show-system-deps-actions.sh"
if [[ ! -f "${ACTIONS_SCRIPT}" ]]; then
	install_label FAIL "show-system-deps-actions.sh not found"
	exit 1
fi

set +e
actions_out="$(
	bash "${ACTIONS_SCRIPT}" --include-optional 2>&1
)"
actions_st=$?
set -e

if [[ ${actions_st} -ne 0 ]]; then
	printf '%s\n' "${actions_out}"
	install_label FAIL "deps-actions helper failed"
	exit 1
fi

if install_is_truthy "${SKIP_DOCKER:-}"; then
	printf '%s\n' "${actions_out}" | awk 'BEGIN {RS=""; ORS="\n\n"} !/docker/ && !/Docker/ {print}'
else
	printf '%s\n' "${actions_out}"
fi

if install_is_wsl; then
	echo ""
	echo "==> Windows host tools (from WSL)"
	if command -v wt.exe >/dev/null 2>&1; then
		install_label OK "wt.exe"
	else
		install_label WARN "wt.exe not available — install Windows Terminal on Windows if you want that workflow"
	fi
	if command -v winget.exe >/dev/null 2>&1; then
		install_label OK "winget.exe (do not run winget install from here without review; corporate policy may restrict it)"
	else
		install_label WARN "winget.exe not on PATH from WSL — install App Installer / winget on the Windows host"
	fi
	if command -v powershell.exe >/dev/null 2>&1; then
		install_label OK "powershell.exe"
	else
		install_label WARN "powershell.exe not on PATH from WSL"
	fi
fi

echo ""
install_label OK "install-external finished (guidance only; nothing was installed by this script)"
