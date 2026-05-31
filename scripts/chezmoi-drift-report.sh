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
GITNEXUS_LAUNCHER="${HOME_ROOT}/.local/share/chezmoi/bin/mcp-gitnexus-launcher"
FILESYSTEM_LAUNCHER="${HOME_ROOT}/.local/share/chezmoi/bin/mcp-filesystem-launcher"

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

section "Diff: MCP launchers (git, postgres, gitnexus, filesystem)"
note "Whitespace-only drift is common after bin/tmpl sync; logic should match bin/."
launcher_paths=()
for p in "${GIT_LAUNCHER}" "${POSTGRES_LAUNCHER}" "${GITNEXUS_LAUNCHER}" "${FILESYSTEM_LAUNCHER}"; do
	[[ -e "${p}" ]] && launcher_paths+=("${p}")
done
if ((${#launcher_paths[@]} > 0)); then
	chezmoi --source="${SOURCE}" diff "${launcher_paths[@]}" 2>/dev/null || true
else
	note "Launchers not present in HOME yet — skip diff."
fi

section "Codex — versioned policy; acotado apply manual if drift"
note "~/.codex/config.toml may show MM until you apply that path only (never global apply)."
note "Policy: HOME prefs + Chezmoi data.codex defaults (model, reasoning, trust_level)."
note "Template: dot_codex/private_config.toml.tmpl (private_ prefix → mode 600 on apply)."
note "Override per machine in ~/.config/chezmoi/chezmoi.toml under [data.codex]."
note "Manual (Jesús only):"
note "  chezmoi --source=\"${SOURCE}\" diff ~/.codex/config.toml"
note "  chezmoi --source=\"${SOURCE}\" apply ~/.codex/config.toml"
note "  stat -c '%a %n' ~/.codex/config.toml"
note "Details: docs/CHEZMOI.md — Codex governance"

section "Optional: hide phantom script R entries (local only, not versioned)"
note 'Add to ~/.config/chezmoi/chezmoi.toml: [status] exclude = ["scripts"]'

section "Manual apply (Jesús only — not executed by this script)"
note 'To refresh materialized git/postgres launchers after bin/tmpl changes (typical whitespace drift):'
note "  chezmoi --source=\"${SOURCE}\" apply \\"
note "    ${GIT_LAUNCHER} \\"
note "    ${POSTGRES_LAUNCHER}"
note "Or run: make mcp-launcher-contract-check (repo strict; HOME advisory only)"
note "This is not a global chezmoi apply."

exit 0
