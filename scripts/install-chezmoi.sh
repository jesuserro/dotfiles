#!/usr/bin/env bash
# Idempotent, explicit installer for chezmoi (twpayne/chezmoi).
#
# Contract:
#   - Never edits ~/.zshrc, ~/.bashrc or any rc file.
#   - DRY_RUN=1: prints what would happen, downloads nothing, installs nothing.
#   - If `chezmoi` is already present in PATH, do not reinstall (just report version).
#   - If missing, download the official installer (get.chezmoi.io) to a temp file,
#     show the URL explicitly, then run it with `-b "$HOME/.local/bin"` so the
#     binary lands user-level. No sudo, no apt-get, no Go toolchain required.
#   - Never installs Windows-side / host-side tooling. Linux/WSL only.
#
# Notes:
#   - The official upstream installer is documented at https://www.chezmoi.io and
#     served via the canonical short URL https://get.chezmoi.io. It supports
#     `-b <bindir>` to control the install directory. We always pass
#     `-b "$HOME/.local/bin"` to keep the install user-level and never touch
#     system paths.
#   - This script never modifies $HOME outside of $HOME/.local/bin/chezmoi.
#   - Intentionally NOT pinned to a version (mirrors install-uv style). The
#     upstream installer fetches the latest release. If reproducible installs are
#     ever required, switch to a pinned-binary + sha256 pattern (mirror of
#     install-sops).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

CHEZMOI_INSTALLER_URL="https://get.chezmoi.io"
CHEZMOI_BIN_DIR="${HOME}/.local/bin"
CHEZMOI_DEFAULT_PATH="${CHEZMOI_BIN_DIR}/chezmoi"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

print_header() {
	echo "==> Installing chezmoi (idempotent, explicit, never edits rc files, no sudo)"
	echo "    Source URL: ${CHEZMOI_INSTALLER_URL}"
	echo "    Target binary (user-level): ${CHEZMOI_DEFAULT_PATH}"
	if dry; then
		echo "[DRY_RUN] No download, no install, no writes."
	fi
}

print_already_present() {
	local path="$1"
	local version
	version="$("${path}" --version 2>/dev/null | head -n1 || echo 'chezmoi (version unknown)')"
	install_label OK "chezmoi already present at ${path} (${version}) — not reinstalling."
	echo "    To force a re-install, remove the binary first:"
	echo "      rm -f \"${path}\""
	echo "    Or refresh in-place with:"
	echo "      chezmoi upgrade"
}

print_present_not_on_path() {
	local path="$1"
	local version
	version="$("${path}" --version 2>/dev/null | head -n1 || echo 'chezmoi (version unknown)')"
	install_label OK "chezmoi already installed at ${path} (${version}) — not reinstalling."
	install_label WARN "${path} is NOT in your current PATH."
	echo "    This repo already prepends \$HOME/.local/bin via zsh/10-path.zsh."
	echo "    Open a new shell, or for the current session run:"
	echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
	echo "    To force a re-install, remove the binary first:"
	echo "      rm -f \"${path}\""
}

print_dry_plan() {
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. mkdir -p \"${CHEZMOI_BIN_DIR}\""
	echo "  2. Download installer to a temporary file:"
	echo "       curl -fsSL ${CHEZMOI_INSTALLER_URL} -o /tmp/install-chezmoi.<rand>.sh"
	echo "  3. Inspect the downloaded script (you can review it before run)."
	echo "  4. Run it with:"
	echo "       sh /tmp/install-chezmoi.<rand>.sh -b \"${CHEZMOI_BIN_DIR}\""
	echo "       (no '--' separator: it would be treated as positional \$1 and"
	echo "        the upstream installer would leak '-b' to chezmoi itself)"
	echo "  5. Clean up the temporary file."
	echo "  6. Verify with: \"${CHEZMOI_DEFAULT_PATH}\" --version"
	echo ""
	echo "[DRY_RUN] Equivalent one-liner (upstream fallback, '--' required for 'sh -c'):"
	echo "  sh -c \"\$(curl -fsLS ${CHEZMOI_INSTALLER_URL})\" -- -b \"${CHEZMOI_BIN_DIR}\""
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - This script never edits ~/.zshrc, ~/.bashrc or any rc file."
	echo "  - No sudo, no apt-get, no Go toolchain. Installs only under \$HOME/.local/bin."
	echo "  - If \$HOME/.local/bin is not in your PATH yet, this repo already"
	echo "    appends it via zsh/10-path.zsh; nothing else needs to change."
}

download_and_install() {
	if ! command -v curl >/dev/null 2>&1; then
		install_label FAIL "curl is required to download the official chezmoi installer (install via 'make install-apt')."
		return 1
	fi

	mkdir -p "${CHEZMOI_BIN_DIR}"

	local tmp_file
	tmp_file="$(mktemp -t install-chezmoi.XXXXXX.sh)"
	# shellcheck disable=SC2064
	trap "rm -f '${tmp_file}'" EXIT INT TERM

	echo ""
	echo "==> Downloading official installer"
	echo "    From: ${CHEZMOI_INSTALLER_URL}"
	echo "    To:   ${tmp_file}"
	if ! curl -fsSL "${CHEZMOI_INSTALLER_URL}" -o "${tmp_file}"; then
		install_label FAIL "Failed to download installer from ${CHEZMOI_INSTALLER_URL}"
		return 1
	fi

	if [[ ! -s "${tmp_file}" ]]; then
		install_label FAIL "Downloaded installer is empty: ${tmp_file}"
		return 1
	fi

	echo ""
	echo "==> Running official installer with -b \"${CHEZMOI_BIN_DIR}\""
	echo "    (drops the binary at ${CHEZMOI_DEFAULT_PATH}; never touches rc files)"
	# IMPORTANT: do NOT use the '--' separator here. The upstream one-liner uses
	# 'sh -c "$(curl …)" -- -b "$HOME/.local/bin"' because '--' is the $0
	# placeholder for 'sh -c'. When we invoke a downloaded file directly
	# ('sh script.sh ...'), '--' becomes positional $1 and the chezmoi installer
	# treats it as end-of-options, leaking '-b <dir>' to the newly installed
	# chezmoi binary (which fails with: unknown shorthand flag: 'b' in -b).
	if ! sh "${tmp_file}" -b "${CHEZMOI_BIN_DIR}"; then
		install_label FAIL "Official chezmoi installer reported an error."
		return 1
	fi

	if [[ -x "${CHEZMOI_DEFAULT_PATH}" ]]; then
		local version
		version="$("${CHEZMOI_DEFAULT_PATH}" --version 2>/dev/null | head -n1 || echo 'chezmoi (version unknown)')"
		install_label OK "chezmoi installed at ${CHEZMOI_DEFAULT_PATH} (${version})"
		return 0
	fi

	if command -v chezmoi >/dev/null 2>&1; then
		install_label OK "chezmoi installed and resolvable in PATH at $(command -v chezmoi)"
		return 0
	fi

	install_label FAIL "Installer finished but 'chezmoi' is not at ${CHEZMOI_DEFAULT_PATH} and not in PATH."
	return 1
}

main() {
	print_header

	if command -v chezmoi >/dev/null 2>&1; then
		print_already_present "$(command -v chezmoi)"
		return 0
	fi

	# DRY_RUN is intentionally checked BEFORE the disk fallback below so that
	# 'DRY_RUN=1 make install-chezmoi' always prints the plan, even when a
	# previous (possibly partial) install left ~/.local/bin/chezmoi on disk but
	# not on the current PATH.
	if dry; then
		print_dry_plan
		return 0
	fi

	# Fallback idempotency: chezmoi can be present on disk after a previous
	# (possibly partial) install even when $HOME/.local/bin is not currently on
	# PATH. Treat that as "already installed" instead of re-downloading.
	if [[ -x "${CHEZMOI_DEFAULT_PATH}" ]]; then
		print_present_not_on_path "${CHEZMOI_DEFAULT_PATH}"
		return 0
	fi

	download_and_install
}

main "$@"
