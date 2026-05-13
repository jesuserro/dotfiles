#!/usr/bin/env bash
# Idempotent, explicit installer for the Node.js stack (node + npm) on Debian/Ubuntu.
#
# Why this exists:
#   Several MCPs ship as npm packages and resolve at runtime via `npx -y …`
#   (context7, sequential-thinking, obsidian, playwright, docker, filesystem
#   launcher, etc.). When `node`/`npm`/`npx` are absent from PATH, Cursor /
#   Codex / OpenCode silently fail to activate those MCPs. This target is the
#   thin opt-in helper that brings the runtime up; it is intentionally NOT
#   chained to `make install`.
#
# Contract:
#   - DRY_RUN=1: prints what would happen, runs nothing under sudo.
#   - If `node` AND `npm` are already in PATH, do not reinstall (report versions).
#   - Linux/WSL only. Refuses to run on non-Debian-like systems.
#   - Never edits ~/.zshrc, ~/.bashrc or any rc file.
#   - Uses Ubuntu's stock APT packages (`nodejs`, `npm`). No NodeSource, no NVM/FNM.
#   - If a future MCP needs Node >= 18 and the APT version is older, this
#     script reports the gap and exits 0; it does NOT silently add a third-party
#     repo. The user opts into NodeSource explicitly in a follow-up change.
#
# Pairs with: see scripts/install-uv.sh and scripts/install-sops.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

APT_PACKAGES=(nodejs npm)

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

print_header() {
	echo "==> install-node-stack (idempotent, opt-in, APT only)"
	echo "    Packages: ${APT_PACKAGES[*]}"
	if dry; then
		echo "[DRY_RUN] No sudo, no apt-get, no writes."
	fi
}

print_already_present() {
	local node_path npm_path node_v npm_v
	node_path="$(command -v node)"
	npm_path="$(command -v npm)"
	node_v="$(node --version 2>/dev/null || echo 'node (version unknown)')"
	npm_v="$(npm --version 2>/dev/null || echo 'npm (version unknown)')"
	install_label OK "node already present at ${node_path} (${node_v})"
	install_label OK "npm already present at ${npm_path} (${npm_v})"
	if command -v npx >/dev/null 2>&1; then
		install_label OK "npx in PATH at $(command -v npx)"
	else
		install_label WARN "npx not in PATH despite node+npm being present (unusual; check 'apt list --installed npm')"
	fi
}

print_dry_plan() {
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. sudo apt-get update"
	echo "  2. sudo apt-get install -y ${APT_PACKAGES[*]}"
	echo "  3. Verify with:"
	echo "       node --version"
	echo "       npm --version"
	echo "       npx --version"
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - This script does not add NodeSource or any third-party repo."
	echo "  - If your distro's Node is older than what an MCP needs, this"
	echo "    script will report the gap and stop; install NodeSource manually"
	echo "    or pin a different runtime in a follow-up change."
}

ensure_debian_like() {
	if ! install_is_debian_like; then
		install_label FAIL "install-node-stack is APT-only; this host is not Debian/Ubuntu-like."
		echo "    On other distros install node+npm via your native package manager."
		exit 1
	fi
}

apt_install() {
	echo ""
	echo "==> Installing ${APT_PACKAGES[*]} via APT"
	if ! command -v sudo >/dev/null 2>&1; then
		install_label FAIL "sudo is required to run 'apt-get install'."
		return 1
	fi
	sudo apt-get update
	sudo apt-get install -y "${APT_PACKAGES[@]}"
}

post_install_report() {
	local missing=()
	for cmd in node npm npx; do
		if ! command -v "${cmd}" >/dev/null 2>&1; then
			missing+=("${cmd}")
		fi
	done
	if [[ ${#missing[@]} -eq 0 ]]; then
		install_label OK "node $(node --version 2>/dev/null), npm $(npm --version 2>/dev/null), npx $(npx --version 2>/dev/null) — runtime ready for npx-based MCPs."
		return 0
	fi
	install_label WARN "node-stack install finished but missing in PATH: ${missing[*]}"
	echo "    Open a new shell or ensure /usr/bin and ~/.local/bin are on PATH."
	return 0
}

main() {
	print_header

	if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
		print_already_present
		return 0
	fi

	ensure_debian_like

	if dry; then
		print_dry_plan
		return 0
	fi

	apt_install
	post_install_report
}

main "$@"
