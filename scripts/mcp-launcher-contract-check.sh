#!/usr/bin/env bash
# Read-only MCP launcher contract: bin/ <-> Chezmoi templates + agent template paths.
# Does not run chezmoi apply or modify HOME.
# See docs/CHEZMOI.md — "Launchers MCP materializados".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
SOURCE="${CHEZMOI_SOURCE:-${DOTFILES_ROOT}}"
HOME_ROOT="${HOME}"

BIN_DIR="${DOTFILES_ROOT}/bin"
TMPL_DIR="${DOTFILES_ROOT}/dot_local/share/chezmoi/bin"
SYNC_NAMES=(git gitnexus postgres)
ALL_NAMES=(filesystem git gitnexus postgres)

AGENT_TEMPLATES=(
	"${DOTFILES_ROOT}/dot_cursor/mcp.json.tmpl"
	"${DOTFILES_ROOT}/dot_codex/private_config.toml.tmpl"
	"${DOTFILES_ROOT}/dot_config/opencode/opencode.json.tmpl"
)

LAUNCHER_REFS=(
	mcp-git-launcher
	mcp-gitnexus-launcher
	mcp-filesystem-launcher
	mcp-postgres-launcher
)

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

warn() {
	printf 'WARN: %s\n' "$*" >&2
}

note() {
	printf '    %s\n' "$*"
}

section() {
	printf '\n==> %s\n' "$1"
}

section "MCP launcher contract (read-only)"
note "Dotfiles root: ${DOTFILES_ROOT}"
note "This script never runs chezmoi apply."

section "Repo: launcher files exist"
for name in "${ALL_NAMES[@]}"; do
	[[ -f "${BIN_DIR}/mcp-${name}-launcher" ]] ||
		fail "missing ${BIN_DIR}/mcp-${name}-launcher"
	[[ -f "${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl" ]] ||
		fail "missing ${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl"
done
note "All bin/ and dot_local/.../ templates present."

section "Repo: bin/ <-> template (strict sync)"
for name in "${SYNC_NAMES[@]}"; do
	if ! diff -q "${BIN_DIR}/mcp-${name}-launcher" \
		"${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl" >/dev/null 2>&1; then
		fail "mcp-${name}-launcher: bin/ and template differ (expected byte-identical)"
	fi
	note "mcp-${name}-launcher: bin/ == template"
done

if diff -q "${BIN_DIR}/mcp-filesystem-launcher" \
	"${TMPL_DIR}/executable_mcp-filesystem-launcher.tmpl" >/dev/null 2>&1; then
	note "mcp-filesystem-launcher: bin/ == template (optional; dual design usually differs)"
else
	note "filesystem: dual design OK (bin/ and template intentionally differ)"
fi

section "Repo: productive agent templates (paths)"
for agent_file in "${AGENT_TEMPLATES[@]}"; do
	[[ -f "${agent_file}" ]] || fail "missing agent template: ${agent_file}"
	rel="${agent_file#${DOTFILES_ROOT}/}"
	if grep -qE 'dotfiles/bin/mcp-' "${agent_file}" 2>/dev/null; then
		fail "${rel}: must not reference dotfiles/bin/mcp-* (use ~/.local/share/chezmoi/bin/)"
	fi
	if grep -qE '/home/jesus/dotfiles/bin/mcp-' "${agent_file}" 2>/dev/null; then
		fail "${rel}: must not reference /home/jesus/dotfiles/bin/mcp-*"
	fi
	for launcher in "${LAUNCHER_REFS[@]}"; do
		if grep -q "${launcher}" "${agent_file}" &&
			! grep -q ".local/share/chezmoi/bin/${launcher}" "${agent_file}"; then
			fail "${rel}: references ${launcher} but not via .local/share/chezmoi/bin/"
		fi
	done
	note "${rel}: agent paths OK"
done

section "HOME: advisory only (never fails this check)"
home_drift=false
if ! command -v chezmoi >/dev/null 2>&1; then
	note "chezmoi not in PATH — skip HOME advisory"
else
	launcher_paths=()
	for name in "${ALL_NAMES[@]}"; do
		launcher_paths+=("${HOME_ROOT}/.local/share/chezmoi/bin/mcp-${name}-launcher")
	done

	if chezmoi --source="${SOURCE}" status 2>/dev/null | grep -qE 'mcp-(filesystem|git|gitnexus|postgres)-launcher'; then
		home_drift=true
		note "chezmoi status shows modified MCP launcher(s):"
		chezmoi --source="${SOURCE}" status 2>/dev/null | grep -E 'mcp-(filesystem|git|gitnexus|postgres)-launcher' || true
	fi

	existing=()
	for p in "${launcher_paths[@]}"; do
		[[ -e "$p" ]] && existing+=("$p")
	done
	if ((${#existing[@]} > 0)); then
		if ! chezmoi --source="${SOURCE}" diff "${existing[@]}" >/dev/null 2>&1; then
			home_drift=true
			note "chezmoi diff (launchers):"
			chezmoi --source="${SOURCE}" diff "${existing[@]}" 2>/dev/null || true
		fi
	fi
fi

if [[ "${home_drift}" == true ]]; then
	warn "HOME launcher drift detected. Run make chezmoi-drift-report and apply selected launchers manually if desired."
	warn "Example (acotado, not global apply):"
	warn "  chezmoi --source=\"${SOURCE}\" apply \\"
	warn "    ${HOME_ROOT}/.local/share/chezmoi/bin/mcp-git-launcher \\"
	warn "    ${HOME_ROOT}/.local/share/chezmoi/bin/mcp-postgres-launcher"
else
	note "No HOME launcher drift reported (or chezmoi unavailable)."
fi

section "Contract OK"
note "Repo contract satisfied. HOME advisory does not affect exit status."
exit 0
