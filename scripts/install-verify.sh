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

echo "==> Version checks"

version_or_fail zsh
version_or_fail git
version_or_fail chezmoi
version_or_fail sops
version_or_fail age
version_or_fail rg

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
printf '=== Summary: PASS=%s WARN=%s FAIL=%s ===\n' "${pass}" "${warn}" "${fail}"

if [[ ${fail} -gt 0 ]]; then
	if install_is_truthy "${STRICT:-}"; then
		exit 1
	fi
	printf '%-6s %s\n' "WARN" "STRICT not set — exit 0 despite FAIL (use STRICT=1 to fail this step)"
	exit 0
fi

exit 0
