#!/usr/bin/env bash
# Non-destructive version probes with PASS / WARN / FAIL summary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

pass=0
warn=0
fail=0

bump() {
	case "$1" in
	PASS) pass=$((pass + 1)) ;;
	WARN) warn=$((warn + 1)) ;;
	FAIL) fail=$((fail + 1)) ;;
	esac
}

ver_line() {
	local state="$1"
	local msg="$2"
	printf '%-6s %s\n' "${state}" "${msg}"
	bump "${state}"
}

version_or_fail() {
	local bin="$1"
	if command -v "${bin}" >/dev/null 2>&1; then
		local full o
		full="$("${bin}" --version 2>&1)" || full=""
		o="${full%%$'\n'*}"
		ver_line PASS "${bin}: ${o}"
	else
		ver_line FAIL "${bin}: not in PATH"
	fi
}

# Optional / external user tooling: WARN if missing, never FAIL.
# Used for tools that the repo prefers but does not require for a minimal setup
# (uv, node, npm). They are still verified so STRICT=1 stays informative.
version_or_warn() {
	local bin="$1"
	if command -v "${bin}" >/dev/null 2>&1; then
		local full o
		full="$("${bin}" --version 2>&1)" || full=""
		o="${full%%$'\n'*}"
		ver_line PASS "${bin}: ${o}"
	else
		ver_line WARN "${bin}: not in PATH (optional/external)"
	fi
}

# Opt-in installers (not part of `make install`). WARN when missing; never FAIL.
version_or_warn_optin() {
	local bin="$1"
	local make_target="$2"
	if command -v "${bin}" >/dev/null 2>&1; then
		local full o
		full="$("${bin}" --version 2>&1)" || full=""
		o="${full%%$'\n'*}"
		ver_line PASS "${bin}: ${o}"
	else
		ver_line WARN "${bin}: not installed (optional; run ${make_target})"
	fi
}

have_fontconfig() {
	command -v fc-match >/dev/null 2>&1 &&
		command -v fc-list >/dev/null 2>&1 &&
		command -v fc-cache >/dev/null 2>&1
}

meslo_available() {
	local match_out list_out
	match_out="$(fc-match "MesloLGS NF" 2>/dev/null || true)"
	list_out="$(fc-list 2>/dev/null || true)"

	[[ "${match_out}" == *"MesloLGS"* && "${list_out}" == *"MesloLGS NF"* ]]
}

echo "==> Version checks (bootstrap base)"

version_or_fail zsh
version_or_fail git
version_or_fail age
version_or_fail rg

echo ""
echo "==> Opt-in dotfiles tooling (WARN when missing)"
version_or_warn_optin chezmoi "make install-chezmoi"
version_or_warn_optin sops "make install-sops"

echo ""
echo "==> External / preferred user tooling (WARN-only when missing)"
# uv: preferred Python tool (uv-first policy). Install with 'make install-uv'.
version_or_warn uv
# node / npm: required de facto on workstation use, but kept optional for
# headless/CI machines. Independent of the uv policy.
version_or_warn node
version_or_warn npm

echo ""
echo "==> Docker (WARN-only: never a FAIL here)"
if command -v docker >/dev/null 2>&1; then
	if docker version >/dev/null 2>&1; then
		full="$(docker version 2>&1)" || full=""
		out="${full%%$'\n'*}"
		ver_line PASS "docker: ${out} ..."
	else
		ver_line WARN "docker CLI present but docker version failed (daemon down or permissions)"
	fi
else
	ver_line WARN "docker not in PATH or not installed"
fi

echo ""
echo "==> Powerlevel10k fonts (WARN-only)"
if ! have_fontconfig; then
	ver_line WARN "fontconfig missing (fc-match/fc-list/fc-cache); run make install-apt"
elif meslo_available; then
	match_out="$(fc-match "MesloLGS NF" 2>/dev/null || true)"
	ver_line PASS "MesloLGS NF available (${match_out%%$'\n'*})"
else
	ver_line WARN "MesloLGS NF not available; run make install-fonts"
fi

echo ""
printf '=== Summary: PASS=%s WARN=%s FAIL=%s ===\n' "${pass}" "${warn}" "${fail}"

if [[ ${fail} -gt 0 ]]; then
	if install_is_truthy "${STRICT:-}"; then
		exit 1
	fi
	printf '%-6s %s\n' "WARN" "STRICT not set — exit 0 despite FAIL (use STRICT=1 to fail this step)"
	exit 0
fi

exit 0
