#!/usr/bin/env bash
# Idempotent, explicit installer for MesloLGS NF fonts used by Powerlevel10k.
#
# Contract:
#   - Installs only Linux/WSL user fonts under XDG_DATA_HOME / ~/.local/share.
#   - Never uses sudo, edits shell RC files, touches Windows Terminal settings,
#     or runs `p10k configure`.
#   - DRY_RUN=1: prints the plan without creating directories, downloading, or
#     refreshing fontconfig caches.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

FONT_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/fonts/MesloLGS"

FONT_FILES=(
	"MesloLGS NF Regular.ttf"
	"MesloLGS NF Bold.ttf"
	"MesloLGS NF Italic.ttf"
	"MesloLGS NF Bold Italic.ttf"
)

FONT_URLS=(
	"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
	"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
	"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
	"https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
)

log() {
	install_label OK "$1"
}

warn() {
	install_label WARN "$1"
}

die() {
	install_label FAIL "$1" >&2
	exit 1
}

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

have_cmd() {
	command -v "$1" >/dev/null 2>&1
}

require_cmds() {
	local missing=()
	local cmd
	for cmd in "$@"; do
		if ! have_cmd "${cmd}"; then
			missing+=("${cmd}")
		fi
	done

	if [[ ${#missing[@]} -gt 0 ]]; then
		if [[ "${missing[*]}" == "curl" ]]; then
			die "curl not found. Run make install-apt or install curl."
		fi
		die "fontconfig missing (${missing[*]} not found). Run make install-apt or install fontconfig."
	fi
}

font_file_present() {
	local file="$1"
	[[ -s "${FONT_DIR}/${file}" ]]
}

missing_fonts() {
	local file
	for file in "${FONT_FILES[@]}"; do
		if ! font_file_present "${file}"; then
			printf '%s\n' "${file}"
		fi
	done
}

meslo_available() {
	local match_out list_out
	match_out="$(fc-match "MesloLGS NF" 2>/dev/null || true)"
	list_out="$(fc-list 2>/dev/null || true)"

	[[ "${match_out}" == *"MesloLGS"* && "${list_out}" == *"MesloLGS NF"* ]]
}

download_font() {
	local file="$1"
	local url="$2"
	local tmp="${FONT_DIR}/${file}.tmp.$$"

	rm -f "${tmp}"
	echo "==> Downloading ${file}"
	echo "    From: ${url}"
	echo "    To:   ${FONT_DIR}/${file}"

	if ! curl -fsSL "${url}" -o "${tmp}"; then
		rm -f "${tmp}"
		die "Failed to download ${file} from ${url}"
	fi

	if [[ ! -s "${tmp}" ]]; then
		rm -f "${tmp}"
		die "Downloaded font is empty: ${file}"
	fi

	mv -f "${tmp}" "${FONT_DIR}/${file}"
	log "Installed ${file}"
}

refresh_font_cache() {
	echo "==> Refreshing fontconfig cache"
	fc-cache -fv "${FONT_DIR}"
}

verify_meslo() {
	if meslo_available; then
		local match_out
		match_out="$(fc-match "MesloLGS NF" 2>/dev/null || true)"
		log "MesloLGS NF available via fontconfig (${match_out%%$'\n'*})"
		return 0
	fi

	return 1
}

print_header() {
	echo "==> install-fonts (MesloLGS NF for Powerlevel10k)"
	echo "    Target directory: ${FONT_DIR}"
	echo "    Scope: Linux/WSL user fonts only; Windows Terminal settings are not changed."
	if dry; then
		echo "[DRY_RUN] No directories, downloads, or fontconfig cache updates will be performed."
	fi
}

print_dry_plan() {
	local i file
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. Ensure fontconfig commands exist: fc-match, fc-list, fc-cache."
	echo "  2. If MesloLGS NF is already visible to fontconfig, do nothing."
	echo "  3. Otherwise create: ${FONT_DIR}"
	echo "  4. Download missing font files atomically:"
	for i in "${!FONT_FILES[@]}"; do
		file="${FONT_FILES[$i]}"
		if font_file_present "${file}"; then
			echo "       present: ${file}"
		else
			echo "       missing: ${file}"
			echo "                ${FONT_URLS[$i]}"
		fi
	done
	echo "  5. Run: fc-cache -fv \"${FONT_DIR}\""
	echo "  6. Verify with fc-match and fc-list."
}

main() {
	print_header

	if dry; then
		if have_cmd fc-match && have_cmd fc-list && meslo_available; then
			verify_meslo
		else
			print_dry_plan
		fi
		return 0
	fi

	require_cmds fc-match fc-list fc-cache

	if verify_meslo; then
		log "No download needed."
		return 0
	fi

	mapfile -t missing < <(missing_fonts)
	if [[ ${#missing[@]} -eq 0 ]]; then
		warn "All MesloLGS NF files exist, but fontconfig does not see the family yet."
		refresh_font_cache
		verify_meslo || die "MesloLGS NF still unavailable after fc-cache. Check ${FONT_DIR}."
		return 0
	fi

	require_cmds curl
	mkdir -p "${FONT_DIR}"

	local i file
	for i in "${!FONT_FILES[@]}"; do
		file="${FONT_FILES[$i]}"
		if font_file_present "${file}"; then
			log "${file} already present"
		else
			download_font "${file}" "${FONT_URLS[$i]}"
		fi
	done

	refresh_font_cache
	verify_meslo || die "MesloLGS NF still unavailable after installing fonts. Check ${FONT_DIR}."
}

main "$@"
