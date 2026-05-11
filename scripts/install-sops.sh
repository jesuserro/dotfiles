#!/usr/bin/env bash
# Idempotent, explicit installer for the SOPS (Mozilla → getsops) secrets editor.
#
# Contract:
#   - Never edits ~/.zshrc, ~/.bashrc or any rc file.
#   - DRY_RUN=1: prints what would happen, downloads nothing, installs nothing.
#   - If `sops` is already present in PATH, do not reinstall (just report version).
#   - If missing, download the official binary for the current Linux architecture
#     from the pinned release of getsops/sops, verify its sha256, then drop it at
#     $HOME/.local/bin/sops with mode 0755.
#   - Never installs Windows-side / host-side tooling. Linux/WSL only. No sudo.
#
# Notes:
#   - The pinned version (SOPS_VERSION below) is intentional: reproducible installs
#     across home/work workstations and audit-friendly secrets tooling. To bump,
#     update SOPS_VERSION + the two sha256 constants (the upstream checksums.txt
#     file in the release publishes them under sops-<ver>.linux.amd64 /
#     sops-<ver>.linux.arm64).
#   - The official release ships direct binaries (no tarball), see
#     https://github.com/getsops/sops/releases/tag/v3.9.4.
#   - This script never modifies $HOME outside of $HOME/.local/bin/sops.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

SOPS_VERSION="v3.9.4"
SOPS_DEFAULT_PATH="${HOME}/.local/bin/sops"
SOPS_RELEASE_BASE="https://github.com/getsops/sops/releases/download/${SOPS_VERSION}"

# Pinned sha256 sums (from sops-${SOPS_VERSION}.checksums.txt at release time).
SOPS_SHA256_AMD64="5488e32bc471de7982ad895dd054bbab3ab91c417a118426134551e9626e4e85"
SOPS_SHA256_ARM64="16564c6b181d88505d9e0dfef62771894293d85cde5884d9b1a843859eee174b"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

detect_arch() {
	local m
	m="$(uname -m)"
	case "${m}" in
	x86_64 | amd64) echo "amd64" ;;
	aarch64 | arm64) echo "arm64" ;;
	*)
		echo "" # unsupported
		;;
	esac
}

asset_url_for_arch() {
	local arch="$1"
	printf '%s/sops-%s.linux.%s' "${SOPS_RELEASE_BASE}" "${SOPS_VERSION}" "${arch}"
}

expected_sha_for_arch() {
	local arch="$1"
	case "${arch}" in
	amd64) echo "${SOPS_SHA256_AMD64}" ;;
	arm64) echo "${SOPS_SHA256_ARM64}" ;;
	*) echo "" ;;
	esac
}

print_header() {
	local arch="$1"
	echo "==> install-sops (idempotent, explicit, never edits rc files, no sudo)"
	echo "    Version (pinned): ${SOPS_VERSION}"
	echo "    Architecture:     ${arch:-unknown}"
	echo "    Target binary:    ${SOPS_DEFAULT_PATH}"
	if dry; then
		echo "[DRY_RUN] No download, no install, no writes."
	fi
}

print_already_present() {
	local path
	path="$(command -v sops)"
	local version
	version="$(sops --version 2>/dev/null | head -n1 || echo 'sops (version unknown)')"
	install_label OK "sops already present at ${path} (${version}) — not reinstalling."
	echo "    To force a re-install, remove the binary first:"
	echo "      rm -f \"${path}\""
}

print_dry_plan() {
	local arch="$1"
	local url
	url="$(asset_url_for_arch "${arch}")"
	local sha
	sha="$(expected_sha_for_arch "${arch}")"
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. mkdir -p \"$(dirname "${SOPS_DEFAULT_PATH}")\""
	echo "  2. Download official binary to a temp file:"
	echo "       curl -fsSL ${url} -o <tmp>/sops"
	echo "  3. Verify sha256:"
	echo "       echo \"${sha}  <tmp>/sops\" | sha256sum -c -"
	echo "  4. chmod 0755 <tmp>/sops"
	echo "  5. mv <tmp>/sops \"${SOPS_DEFAULT_PATH}\""
	echo "  6. Verify with: \"${SOPS_DEFAULT_PATH}\" --version"
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - This script never edits ~/.zshrc, ~/.bashrc or any rc file."
	echo "  - No sudo, no apt-get. Installs only under \$HOME/.local/bin."
	echo "  - If \$HOME/.local/bin is not in your PATH yet, this repo already"
	echo "    appends it via zsh/10-path.zsh."
}

download_and_install() {
	local arch="$1"
	local url
	url="$(asset_url_for_arch "${arch}")"
	local sha
	sha="$(expected_sha_for_arch "${arch}")"

	if ! command -v curl >/dev/null 2>&1; then
		install_label FAIL "curl is required to download the sops release (install via 'make install-apt')."
		return 1
	fi
	if ! command -v sha256sum >/dev/null 2>&1; then
		install_label FAIL "sha256sum is required to verify the sops release (coreutils)."
		return 1
	fi

	local tmp_dir
	tmp_dir="$(mktemp -d -t install-sops.XXXXXX)"
	# shellcheck disable=SC2064
	trap "rm -rf '${tmp_dir}'" EXIT INT TERM

	local tmp_bin="${tmp_dir}/sops"

	echo ""
	echo "==> Downloading official binary"
	echo "    From: ${url}"
	echo "    To:   ${tmp_bin}"
	if ! curl -fsSL "${url}" -o "${tmp_bin}"; then
		install_label FAIL "Failed to download sops from ${url}"
		return 1
	fi

	if [[ ! -s "${tmp_bin}" ]]; then
		install_label FAIL "Downloaded sops binary is empty: ${tmp_bin}"
		return 1
	fi

	echo ""
	echo "==> Verifying sha256"
	echo "    Expected: ${sha}"
	if ! (cd "${tmp_dir}" && echo "${sha}  sops" | sha256sum -c - >/dev/null); then
		install_label FAIL "sha256 mismatch — refusing to install. File left at ${tmp_bin} (will be cleaned by trap)."
		return 1
	fi
	install_label OK "sha256 verified"

	mkdir -p "$(dirname "${SOPS_DEFAULT_PATH}")"
	chmod 0755 "${tmp_bin}"
	mv -f "${tmp_bin}" "${SOPS_DEFAULT_PATH}"

	local version
	version="$("${SOPS_DEFAULT_PATH}" --version 2>/dev/null | head -n1 || echo 'sops (version unknown)')"
	install_label OK "sops installed at ${SOPS_DEFAULT_PATH} (${version})"
}

main() {
	local arch
	arch="$(detect_arch)"

	print_header "${arch}"

	if command -v sops >/dev/null 2>&1; then
		print_already_present
		return 0
	fi

	if [[ -z "${arch}" ]]; then
		install_label FAIL "Unsupported architecture: $(uname -m). Only amd64/arm64 are supported by this installer."
		return 1
	fi

	if dry; then
		print_dry_plan "${arch}"
		return 0
	fi

	download_and_install "${arch}"
}

main "$@"
