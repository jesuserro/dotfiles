#!/usr/bin/env bash
# Non-mutating Chezmoi drift report (read-only).
# Does not run chezmoi apply, touch secrets, or modify HOME.
# See docs/CHEZMOI.md — "Drift aceptado y auditoría".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE="${CHEZMOI_SOURCE:-${DOTFILES_ROOT}}"
HOME_ROOT="${HOME}"

GIT_LAUNCHER="${HOME_ROOT}/.local/share/chezmoi/bin/mcp-git-launcher"
POSTGRES_LAUNCHER="${HOME_ROOT}/.local/share/chezmoi/bin/mcp-postgres-launcher"

section() {
	printf '\n==> %s\n' "$1"
}

note() {
	printf '    %s\n' "$*"
}

section "Chezmoi drift report (read-only)"
note "Source: ${SOURCE}"
note "This script never runs chezmoi apply."

if ! command -v chezmoi >/dev/null 2>&1; then
	note "WARN: chezmoi not in PATH — install with: make install-chezmoi"
	exit 0
fi

section "chezmoi status"
chezmoi --source="${SOURCE}" status || true

section "Scripts (real hooks, not phantom R entries)"
note "Audits run_before_* / run_after_* hooks only:"
chezmoi --source="${SOURCE}" status -i scripts -x '' 2>/dev/null || true

section "Diff: MCP launchers (git, postgres)"
note "Whitespace-only drift is common after bin/tmpl sync; logic should match bin/."
if [[ -e "${GIT_LAUNCHER}" || -e "${POSTGRES_LAUNCHER}" ]]; then
	chezmoi --source="${SOURCE}" diff \
		"${GIT_LAUNCHER}" \
		"${POSTGRES_LAUNCHER}" 2>/dev/null || true
else
	note "Launchers not present in HOME yet — skip diff."
fi

section "Codex — manual decision required (out of scope for automated apply)"
note "~/.codex/config.toml may show MM (model, reasoning, permissions, trust_level)."
note "Do not run a global chezmoi apply until you choose:"
note "  1) Repo wins — apply template as-is"
note "  2) HOME wins — update dot_codex/config.toml.tmpl then apply that path only"
note "  3) Permanent local drift — document and never apply ~/.codex/config.toml"
note "Details: docs/CHEZMOI.md — Drift aceptado y auditoría"

section "Optional: hide phantom script R entries (local only, not versioned)"
note 'Add to ~/.config/chezmoi/chezmoi.toml: [status] exclude = ["scripts"]'

section "Manual apply (Jesús only — not executed by this script)"
note 'To refresh materialized git/postgres launchers after bin/tmpl changes:'
note "  chezmoi --source=\"${SOURCE}\" apply \\"
note "    ${GIT_LAUNCHER} \\"
note "    ${POSTGRES_LAUNCHER}"
note "This is not a global chezmoi apply."

exit 0
