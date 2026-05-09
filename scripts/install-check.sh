#!/usr/bin/env bash
# Non-destructive bootstrap diagnostic: environment, core tools, declarative deps.
#
# Modes:
#   - default: only hard prerequisites (platform, apt-get, internal scripts,
#     real execution errors) cause exit != 0. Missing tools and missing
#     declarative required items surface as MISSING/WARN so the rest of the
#     install flow (install-apt, install-external, ...) can still resolve them.
#   - STRICT=1: missing required items reported by check-system-deps.sh are
#     promoted to FAIL and exit != 0. Use this for CI / fully-baked machines.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

local_ok=0
local_warn=0
local_missing=0
hard_fail=0

declarative_state="UNKNOWN"
declarative_required_ok=0
declarative_required_missing=0
declarative_optional_ok=0
declarative_optional_missing=0

bump_local() {
	case "$1" in
	OK) local_ok=$((local_ok + 1)) ;;
	WARN) local_warn=$((local_warn + 1)) ;;
	MISSING) local_missing=$((local_missing + 1)) ;;
	esac
}

line_local() {
	local state="$1"
	local msg="$2"
	install_label "${state}" "${msg}"
	bump_local "${state}"
}

hard_fail_line() {
	install_label FAIL "$1"
	hard_fail=$((hard_fail + 1))
}

probe() {
	local label="$1"
	local cmd="$2"
	if command -v "${cmd}" >/dev/null 2>&1; then
		line_local OK "${label} (${cmd})"
	else
		line_local MISSING "${label} (${cmd})"
	fi
}

echo "==> Environment"
if install_is_wsl; then
	line_local OK "Platform: WSL (Linux kernel reports Microsoft)"
elif install_is_debian_like; then
	line_local OK "Platform: Debian-like Linux"
else
	hard_fail_line "Platform: not Debian-like — APT targets in this repo expect Ubuntu/Debian"
fi

line_local OK "User: $(id -un) (uid=$(id -u))"

if command -v apt-get >/dev/null 2>&1; then
	line_local OK "apt-get in PATH"
else
	hard_fail_line "apt-get not in PATH (required for the APT bootstrap path)"
fi

if command -v sudo >/dev/null 2>&1; then
	if sudo -n true 2>/dev/null; then
		line_local OK "sudo: non-interactive check passed (-n)"
	else
		line_local WARN "sudo: present; you may need a password for apt installs"
	fi
else
	line_local WARN "sudo: not in PATH (non-root installs need another strategy)"
fi

echo ""
echo "==> Core commands"
probe git git
probe curl curl
probe wget wget
probe make make

echo ""
echo "==> Desired tooling"
probe zsh zsh
probe chezmoi chezmoi
probe sops sops
probe age age
probe ripgrep rg
probe docker docker
probe gh gh
probe uv uv
probe node node
probe npm npm

if install_is_wsl; then
	echo ""
	echo "==> Windows host interop (WSL)"
	for entry in "wt.exe:Windows Terminal" "winget.exe:winget" "powershell.exe:PowerShell"; do
		cmd="${entry%%:*}"
		label="${entry##*:}"
		if command -v "${cmd}" >/dev/null 2>&1; then
			line_local OK "${label} (${cmd})"
		else
			line_local WARN "${cmd} not in WSL PATH (host-side install required if you use it)"
		fi
	done
fi

echo ""
echo "==> Declarative dependency check (scripts/check-system-deps.sh --include-optional)"
CHECK_SCRIPT="${DOTFILES_ROOT}/scripts/check-system-deps.sh"
if [[ ! -x "${CHECK_SCRIPT}" ]]; then
	hard_fail_line "check-system-deps.sh not found or not executable: ${CHECK_SCRIPT}"
	declarative_state="FAIL"
else
	set +e
	check_out="$(bash "${CHECK_SCRIPT}" --include-optional 2>&1)"
	check_st=$?
	set -e
	printf '%s\n' "${check_out}"

	summary_line="$(printf '%s\n' "${check_out}" | grep -E '^Summary: required ok=' | tail -n 1 || true)"
	if [[ -n "${summary_line}" && "${summary_line}" =~ required\ ok=([0-9]+)\ missing=([0-9]+).*optional\ ok=([0-9]+)\ missing=([0-9]+) ]]; then
		declarative_required_ok="${BASH_REMATCH[1]}"
		declarative_required_missing="${BASH_REMATCH[2]}"
		declarative_optional_ok="${BASH_REMATCH[3]}"
		declarative_optional_missing="${BASH_REMATCH[4]}"
		if [[ "${declarative_required_missing}" -gt 0 ]]; then
			declarative_state="WARN"
		else
			declarative_state="PASS"
		fi
	else
		# No parseable summary line -> real script/exec failure, not just a missing item.
		hard_fail_line "deps-check did not produce a parseable Summary line (exit=${check_st}); treat as real script failure"
		declarative_state="FAIL"
	fi
fi

strict_mode=0
if install_is_truthy "${STRICT:-}"; then
	strict_mode=1
fi

echo ""
echo "=== Summary ==="
printf 'Local probes:       OK=%s WARN=%s MISSING=%s\n' \
	"${local_ok}" "${local_warn}" "${local_missing}"
printf 'Declarative deps:   required ok=%s missing=%s | optional ok=%s missing=%s | state=%s\n' \
	"${declarative_required_ok}" "${declarative_required_missing}" \
	"${declarative_optional_ok}" "${declarative_optional_missing}" \
	"${declarative_state}"
printf 'Hard prerequisites: FAIL=%s\n' "${hard_fail}"

overall="PASS"
if [[ ${local_warn} -gt 0 || ${local_missing} -gt 0 || "${declarative_state}" == "WARN" ]]; then
	overall="PASS_WITH_WARNINGS"
fi

if [[ ${hard_fail} -gt 0 ]]; then
	overall="FAIL"
elif [[ ${strict_mode} -eq 1 && ("${declarative_state}" != "PASS") ]]; then
	overall="FAIL"
fi

if [[ ${strict_mode} -eq 1 ]]; then
	printf 'Overall: %s (STRICT=1)\n' "${overall}"
else
	printf 'Overall: %s\n' "${overall}"
fi

if [[ "${overall}" == "FAIL" ]]; then
	if [[ ${hard_fail} -eq 0 && ${strict_mode} -eq 1 ]]; then
		echo ""
		echo "Hint: STRICT=1 promoted missing required declarative deps into FAIL." >&2
		echo "      Re-run without STRICT to continue the bootstrap flow, or run 'make install-apt'" >&2
		echo "      (with DRY_RUN=1 first) to install the APT pieces and then re-check." >&2
	fi
	exit 1
fi

if [[ "${overall}" == "PASS_WITH_WARNINGS" && ${strict_mode} -eq 0 ]]; then
	echo ""
	echo "Hint: items marked MISSING/WARN above can typically be resolved by 'make install-apt'" >&2
	echo "      (APT-managed packages) or 'make install-external' (manual / Windows-host tools)." >&2
fi

exit 0
