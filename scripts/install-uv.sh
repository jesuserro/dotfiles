#!/usr/bin/env bash
# Idempotent, explicit installer for the Astral uv Python tool.
#
# Contract:
#   - Never edits ~/.zshrc, ~/.bashrc or any rc file.
#   - DRY_RUN=1: prints what would happen, downloads nothing, installs nothing.
#   - If `uv` is already present in PATH, do not reinstall (just report version).
#   - If missing, download the official Astral installer to a temp file,
#     show the URL explicitly, run it with conservative flags, then clean up.
#   - Never installs Windows-side / host-side tooling. Linux/WSL only.
#
# Notes:
#   - The official installer historically supports UV_NO_MODIFY_PATH=1 to skip
#     touching shell rc files. We pass it as env to minimise rc-edit risk.
#     If a future installer ignores it, this script still avoids editing rc files
#     itself; the worst case is the installer printing a hint about PATH.
#   - This script never modifies $HOME outside of what the official installer
#     drops at $HOME/.local/bin/uv (its default user-level location).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

UV_INSTALLER_URL="https://astral.sh/uv/install.sh"
UV_DEFAULT_PATH="${HOME}/.local/bin/uv"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

print_header() {
	echo "==> install-uv (idempotent, explicit, never edits rc files)"
	echo "    Source URL: ${UV_INSTALLER_URL}"
	echo "    Target binary (user-level): ${UV_DEFAULT_PATH}"
	if dry; then
		echo "[DRY_RUN] No download, no install, no writes."
	fi
}

print_already_present() {
	local path
	path="$(command -v uv)"
	local version
	version="$(uv --version 2>/dev/null || echo 'uv (version unknown)')"
	install_label OK "uv already present at ${path} (${version}) — not reinstalling."
	echo "    To force a re-install, remove the binary first:"
	echo "      rm -f \"${path}\""
	echo "    Or, if uv supports it on your install, refresh in-place with:"
	echo "      uv self update"
}

print_dry_plan() {
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. Download installer to a temporary file:"
	echo "       curl -fsSL ${UV_INSTALLER_URL} -o /tmp/install-uv.<rand>.sh"
	echo "  2. Inspect the downloaded script (you can review it before run)."
	echo "  3. Run it with:"
	echo "       UV_NO_MODIFY_PATH=1 sh /tmp/install-uv.<rand>.sh"
	echo "  4. Clean up the temporary file."
	echo "  5. Verify with: \"${UV_DEFAULT_PATH}\" --version"
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - This script never edits ~/.zshrc, ~/.bashrc or any rc file."
	echo "  - UV_NO_MODIFY_PATH=1 asks the official installer to skip PATH edits."
	echo "  - If \$HOME/.local/bin is not in your PATH yet, this repo already"
	echo "    appends it via zsh/10-path.zsh; nothing else needs to change."
}

download_and_install() {
	if ! command -v curl >/dev/null 2>&1; then
		install_label FAIL "curl is required to download the official uv installer (install via 'make install-apt')."
		return 1
	fi

	local tmp_file
	tmp_file="$(mktemp -t install-uv.XXXXXX.sh)"
	# shellcheck disable=SC2064
	trap "rm -f '${tmp_file}'" EXIT INT TERM

	echo ""
	echo "==> Downloading official installer"
	echo "    From: ${UV_INSTALLER_URL}"
	echo "    To:   ${tmp_file}"
	if ! curl -fsSL "${UV_INSTALLER_URL}" -o "${tmp_file}"; then
		install_label FAIL "Failed to download installer from ${UV_INSTALLER_URL}"
		return 1
	fi

	if [[ ! -s "${tmp_file}" ]]; then
		install_label FAIL "Downloaded installer is empty: ${tmp_file}"
		return 1
	fi

	echo ""
	echo "==> Running official installer with UV_NO_MODIFY_PATH=1"
	echo "    (asks the installer to skip editing ~/.zshrc, ~/.bashrc, etc.)"
	if ! UV_NO_MODIFY_PATH=1 sh "${tmp_file}"; then
		install_label FAIL "Official uv installer reported an error."
		return 1
	fi

	if [[ -x "${UV_DEFAULT_PATH}" ]]; then
		local version
		version="$("${UV_DEFAULT_PATH}" --version 2>/dev/null || echo 'uv (version unknown)')"
		install_label OK "uv installed at ${UV_DEFAULT_PATH} (${version})"
	elif command -v uv >/dev/null 2>&1; then
		install_label OK "uv installed and resolvable in PATH at $(command -v uv)"
	else
		install_label WARN "Installer finished but 'uv' is not in PATH yet. Open a new shell or ensure \$HOME/.local/bin is on PATH."
	fi
}

main() {
	print_header

	if command -v uv >/dev/null 2>&1; then
		print_already_present
		return 0
	fi

	if dry; then
		print_dry_plan
		return 0
	fi

	download_and_install
}

main "$@"
