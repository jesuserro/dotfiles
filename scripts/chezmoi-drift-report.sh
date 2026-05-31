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

# Normalized script names in chezmoi status → source templates under .chezmoiscripts/
EXPECTED_SCRIPT_ENTRIES=(
	"00_backup_rc_files.sh:run_before_00_backup_rc_files.sh.tmpl"
	"00_gen_secrets.sh:run_after_00_gen_secrets.sh.tmpl"
	"10_setup_ai_runtime.sh:run_after_10_setup_ai_runtime.sh.tmpl"
	"11_link_ai_assets.sh:run_after_11_link_ai_assets.sh.tmpl"
	"12_materialize_ai_commands.sh:run_after_12_materialize_ai_commands.sh.tmpl"
	"13_link_git_ai_wrapper.sh:run_after_13_link_git_ai_wrapper.sh.tmpl"
	"14_link_prompt_launchers.sh:run_after_14_link_prompt_launchers.sh.tmpl"
	"15_link_tmux_dotfiles.sh:run_after_15_link_tmux_dotfiles.sh.tmpl"
)
readonly EXPECTED_SCRIPT_COUNT="${#EXPECTED_SCRIPT_ENTRIES[@]}"

section() {
	printf '\n==> %s\n' "$1"
}

note() {
	printf '    %s\n' "$*"
}

report_script_run_entries() {
	local status_out="$1"
	local run_lines=()
	local line name tmpl_path found expected_ok=true
	local -A seen=()

	while IFS= read -r line; do
		[[ "${line}" =~ ^[[:space:]]*R[[:space:]]+\.chezmoiscripts/ ]] || continue
		run_lines+=("${line}")
		name="${line#* .chezmoiscripts/}"
		seen["${name}"]=1
	done <<<"${status_out}"

	section "Scripts (.chezmoiscripts) — R means Run"
	note "In chezmoi status, R means Run (the hook would execute on apply), not removed."
	note "Normalized names map to run_before_* / run_after_* templates in the source repo."
	note "They are not files under ~/.chezmoiscripts/ unless you created that directory yourself."
	printf '\n'
	note "R .chezmoiscripts/ lines in status: ${#run_lines[@]} (expected ${EXPECTED_SCRIPT_COUNT} for current hooks)"
	printf '\n'

	note "Normalized name → source template:"
	for entry in "${EXPECTED_SCRIPT_ENTRIES[@]}"; do
		name="${entry%%:*}"
		tmpl_path=".chezmoiscripts/${entry#*:}"
		if [[ -n "${seen[${name}]+x}" ]]; then
			note "  .chezmoiscripts/${name} → ${tmpl_path}"
		else
			note "  .chezmoiscripts/${name} → ${tmpl_path} (not listed in status)"
			expected_ok=false
		fi
	done
	printf '\n'

	if ((${#run_lines[@]} == EXPECTED_SCRIPT_COUNT)) && [[ "${expected_ok}" == true ]]; then
		note "ACCEPTED: expected Chezmoi script run entries"
	else
		note "NOTE: script run count or names differ from expected — review hooks in ${SOURCE}/.chezmoiscripts/"
	fi

	printf '\n'
	note "Do not run chezmoi apply globally just to clear these R lines."
	note "Do not use chezmoi forget for this — it does not fix Run semantics and may re-run hooks."
	note ".chezmoiscripts/00_gen_secrets.sh in status is not drift of ~/.config/mcp-secrets.env."
	note "Audit scripts explicitly: chezmoi --source=\"${SOURCE}\" status -i scripts -x ''"
	note 'Optional local comfort (not versioned): [status] exclude = ["scripts"] in ~/.config/chezmoi/chezmoi.toml'
}

section "Chezmoi drift report (read-only)"
note "Source: ${SOURCE}"
note "This script never runs chezmoi apply."

if ! command -v chezmoi >/dev/null 2>&1; then
	note "WARN: chezmoi not in PATH — install with: make install-chezmoi"
	exit 0
fi

section "chezmoi status"
status_out="$(chezmoi --source="${SOURCE}" status 2>/dev/null || true)"
printf '%s\n' "${status_out}"

report_script_run_entries "${status_out}"

section "Scripts audit (include scripts only)"
note "Same hooks as above; explicit include for scripts:"
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

section "Manual apply (Jesús only — not executed by this script)"
note 'To refresh materialized git/postgres launchers after bin/tmpl changes (typical whitespace drift):'
note "  chezmoi --source=\"${SOURCE}\" apply \\"
note "    ${GIT_LAUNCHER} \\"
note "    ${POSTGRES_LAUNCHER}"
note "Or run: make mcp-launcher-contract-check (repo strict; HOME advisory only)"
note "This is not a global chezmoi apply."

exit 0
