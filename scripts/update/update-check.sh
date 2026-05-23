#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"

status() {
	printf '%-6s %s\n' "$1" "$2"
}

echo "==> Dotfiles update readiness"
if is_wsl; then
	status OK "WSL detected"
else
	status WARN "Not running under WSL; make update will skip Windows tab orchestration"
fi
for cmd in make bash; do
	if command -v "$cmd" >/dev/null 2>&1; then status OK "$cmd in PATH"; else status WARN "$cmd missing"; fi
done
for cmd in wt.exe powershell.exe wslpath; do
	if command -v "$cmd" >/dev/null 2>&1; then status OK "$cmd available from WSL"; else status WARN "$cmd unavailable from WSL"; fi
done
if command -v node >/dev/null 2>&1; then
	version="$(node --version 2>/dev/null || true)"
	major="$(node_major "$version")"
	if [[ -n "$major" && "$major" -ge 22 ]]; then
		status OK "Node ${version} satisfies >=22"
	else
		status WARN "Node ${version:-unknown} is below required >=22; run make install-node-stack"
	fi
else
	status WARN "node missing; run make install-node-stack"
fi
if command -v docker >/dev/null 2>&1 || command -v docker.exe >/dev/null 2>&1; then
	status OK "Docker CLI available for Excalidraw image operations"
else
	status WARN "Docker CLI unavailable; Excalidraw image update will be skipped"
fi
if [[ -f "${DOTFILES_ROOT}/ai/assets/mcps/MANIFEST.yaml" ]]; then
	status OK "MCP manifest present"
fi
echo "==> Excalidraw"
"${SCRIPT_DIR}/update-excalidraw.sh" status || true
