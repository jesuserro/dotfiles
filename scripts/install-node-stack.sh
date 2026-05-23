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
#   - If `node` AND `npm` are already >= required major, do not reinstall.
#   - Linux/WSL only. Refuses to run on non-Debian-like systems.
#   - Never edits ~/.zshrc, ~/.bashrc or any rc file.
#   - Uses the NodeSource 24.x APT repository. No NVM/FNM shell initialization.
#   - Keeps Node available in non-interactive Make targets and MCP launchers.
#
# Pairs with: see scripts/install-uv.sh and scripts/install-sops.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

NODE_MAJOR_REQUIRED="${NODE_MAJOR_REQUIRED:-22}"
NODE_MAJOR_TARGET="${NODE_MAJOR_TARGET:-24}"
APT_PACKAGES=(nodejs)

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

print_header() {
	echo "==> install-node-stack (idempotent, opt-in, NodeSource ${NODE_MAJOR_TARGET}.x)"
	echo "    Packages: ${APT_PACKAGES[*]}"
	if dry; then
		echo "[DRY_RUN] No sudo, no apt-get, no writes."
	fi
}

print_already_present() {
	local node_path npm_path node_v npm_v major
	node_path="$(command -v node)"
	npm_path="$(command -v npm)"
	node_v="$(node --version 2>/dev/null || echo 'node (version unknown)')"
	npm_v="$(npm --version 2>/dev/null || echo 'npm (version unknown)')"
	major="${node_v#v}"
	major="${major%%.*}"
	install_label OK "node already present at ${node_path} (${node_v})"
	install_label OK "npm already present at ${npm_path} (${npm_v})"
	if [[ -n "$major" && "$major" -ge "$NODE_MAJOR_REQUIRED" ]]; then
		install_label OK "Node runtime satisfies >=${NODE_MAJOR_REQUIRED} for GitNexus and AI tooling"
	else
		install_label WARN "Node runtime ${node_v} is below required >=${NODE_MAJOR_REQUIRED}; NodeSource ${NODE_MAJOR_TARGET}.x install is needed"
		return 1
	fi
	if command -v npx >/dev/null 2>&1; then
		install_label OK "npx in PATH at $(command -v npx)"
	else
		install_label WARN "npx not in PATH despite node+npm being present (unusual; check 'apt list --installed npm')"
	fi
}

print_dry_plan() {
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. install NodeSource signing key and apt source for ${NODE_MAJOR_TARGET}.x"
	echo "  2. sudo apt-get update"
	echo "  3. sudo apt-get install -y ${APT_PACKAGES[*]}"
	echo "  4. Verify with:"
	echo "       node --version"
	echo "       npm --version"
	echo "       npx --version"
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - This script uses NodeSource because Ubuntu's stock Node may lag below GitNexus engines."
	echo "  - No nvm/fnm shell initialization is required."
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
	echo "==> Installing ${APT_PACKAGES[*]} via NodeSource ${NODE_MAJOR_TARGET}.x APT"
	if ! command -v sudo >/dev/null 2>&1; then
		install_label FAIL "sudo is required to run 'apt-get install'."
		return 1
	fi
	sudo apt-get update
	sudo apt-get install -y ca-certificates curl gnupg
	sudo install -d -m 0755 /etc/apt/keyrings
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
	echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR_TARGET}.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
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
		local node_v major
		node_v="$(node --version 2>/dev/null || true)"
		major="${node_v#v}"
		major="${major%%.*}"
		if [[ -n "$major" && "$major" -ge "$NODE_MAJOR_REQUIRED" ]]; then
			install_label OK "node ${node_v}, npm $(npm --version 2>/dev/null), npx $(npx --version 2>/dev/null) — runtime ready for GitNexus and npx-based MCPs."
		else
			install_label WARN "node ${node_v:-unknown} is still below required >=${NODE_MAJOR_REQUIRED}; check NodeSource apt priority."
		fi
		return 0
	fi
	install_label WARN "node-stack install finished but missing in PATH: ${missing[*]}"
	echo "    Open a new shell or ensure /usr/bin and ~/.local/bin are on PATH."
	return 0
}

main() {
	print_header

	if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
		if print_already_present; then
			return 0
		fi
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
