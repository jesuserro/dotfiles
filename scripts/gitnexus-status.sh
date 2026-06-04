#!/usr/bin/env bash
# Read-only GitNexus operational status for agents and humans.
# Does not use network, mutate workspace, delete locks, or invoke mutating GitNexus CLI subcommands.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_DIR:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
# shellcheck source=scripts/update/lib/node_runtime.sh
source "${SCRIPT_DIR}/update/lib/node_runtime.sh"

warn() {
	printf 'WARN: %s\n' "$*" >&2
}

info() {
	printf 'INFO: %s\n' "$*"
}

note() {
	printf '    %s\n' "$*"
}

section() {
	printf '\n==> %s\n' "$1"
}

fail() {
	printf 'ERROR: %s\n' "$*" >&2
	exit 1
}

has_gitnexus_marker() {
	local file="$1"
	[[ -f "$file" ]] && grep -q '<!-- gitnexus:' "$file"
}

resolve_gitnexus_bin() {
	local npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"
	local candidates=()

	if command -v gitnexus >/dev/null 2>&1; then
		candidates+=("$(command -v gitnexus)")
	fi
	candidates+=(
		"${npm_prefix}/bin/gitnexus"
		"${HOME}/.npm-global/bin/gitnexus"
		"${HOME}/.local/bin/gitnexus"
	)

	local path
	for path in "${candidates[@]}"; do
		[[ -n "$path" && -x "$path" ]] || continue
		printf '%s\n' "$path"
		return 0
	done
	return 1
}

read_meta_field() {
	local meta_file="$1" field="$2"
	python3 - "$meta_file" "$field" <<'PY'
import json
import sys

path, field = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except (OSError, json.JSONDecodeError):
    sys.exit(1)

value = data
for part in field.split("."):
    if not isinstance(value, dict) or part not in value:
        sys.exit(1)
    value = value[part]

if isinstance(value, (dict, list)):
    print(json.dumps(value))
else:
    print(value)
PY
}

list_related_processes() {
	ps aux 2>/dev/null | grep -Ei '(/| )gitnexus (mcp|analyze|serve|wiki)|ladybug' | grep -v grep || true
}

section "GitNexus status (read-only)"
note "Dotfiles root: ${DOTFILES_ROOT}"
note "This script never runs mutating GitNexus CLI subcommands (analyze, wiki, clean, npx)."

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
	fail "Not inside a Git repository (git rev-parse --show-toplevel failed)."
fi
note "Repository: ${repo_root}"

section "GitNexus binary"
if gitnexus_bin="$(resolve_gitnexus_bin)"; then
	info "gitnexus binary: ${gitnexus_bin}"
else
	warn "gitnexus binary not found (checked PATH, NPM_CONFIG_PREFIX, ~/.npm-global/bin, ~/.local/bin)"
	gitnexus_bin=""
fi

section "Node runtime"
node_runtime_probe
if [[ "$NODE_RUNTIME_EFFECTIVE_OK" -eq 1 ]]; then
	info "Node effective: ${NODE_RUNTIME_EFFECTIVE_VERSION} (${NODE_RUNTIME_EFFECTIVE_PATH}, origin=${NODE_RUNTIME_EFFECTIVE_ORIGIN})"
else
	if [[ -n "$NODE_RUNTIME_EFFECTIVE_PATH" ]]; then
		warn "Node effective below >=${NODE_RUNTIME_MIN_MAJOR}: ${NODE_RUNTIME_EFFECTIVE_VERSION:-unknown} (${NODE_RUNTIME_EFFECTIVE_PATH}, origin=${NODE_RUNTIME_EFFECTIVE_ORIGIN})"
	else
		warn "Node effective runtime missing; required >=${NODE_RUNTIME_MIN_MAJOR}"
	fi
fi

if [[ "$NODE_RUNTIME_MANAGED_OK" -eq 1 ]]; then
	info "Managed Node available: ${NODE_RUNTIME_MANAGED_VERSION} (${NODE_RUNTIME_MANAGED_PATH})"
else
	warn "No compatible managed Node at ${NODE_RUNTIME_MANAGED_PATH}: ${NODE_RUNTIME_MANAGED_ERROR:-unknown}"
fi

if [[ "$NODE_RUNTIME_EFFECTIVE_ORIGIN" == "cursor-server" || "$NODE_RUNTIME_EFFECTIVE_ORIGIN" == "vscode-server" || "$NODE_RUNTIME_EFFECTIVE_ORIGIN" == "remote-agent" ]]; then
	if [[ "$NODE_RUNTIME_EFFECTIVE_OK" -ne 1 ]]; then
		warn "Effective Node appears to come from an IDE/agent path and is below policy >=${NODE_RUNTIME_MIN_MAJOR}. Do not run npx or raw analyze subcommands from this shell."
	fi
fi

section "Index status"
meta_file="${repo_root}/.gitnexus/meta.json"
head_commit="$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
index_state="UNKNOWN"

if [[ ! -f "$meta_file" ]]; then
	info "Index: NO_INDEX (.gitnexus/meta.json missing)"
else
	last_commit=""
	indexed_at=""
	stats_files=""
	stats_nodes=""
	stats_edges=""

	last_commit="$(read_meta_field "$meta_file" "lastCommit" 2>/dev/null || true)"
	indexed_at="$(read_meta_field "$meta_file" "indexedAt" 2>/dev/null || true)"
	stats_files="$(read_meta_field "$meta_file" "stats.files" 2>/dev/null || true)"
	stats_nodes="$(read_meta_field "$meta_file" "stats.nodes" 2>/dev/null || true)"
	stats_edges="$(read_meta_field "$meta_file" "stats.edges" 2>/dev/null || true)"

	if [[ -n "$last_commit" && -n "$head_commit" ]]; then
		if [[ "$last_commit" == "$head_commit" ]]; then
			index_state="FRESH"
		else
			index_state="STALE"
		fi
	fi

	info "Index: ${index_state}"
	note "meta.json: ${meta_file}"
	[[ -n "$indexed_at" ]] && note "indexedAt: ${indexed_at}"
	[[ -n "$last_commit" ]] && note "lastCommit: ${last_commit}"
	[[ -n "$head_commit" ]] && note "HEAD:       ${head_commit}"
	if [[ -n "$stats_files" || -n "$stats_nodes" || -n "$stats_edges" ]]; then
		note "stats: files=${stats_files:-?} nodes=${stats_nodes:-?} edges=${stats_edges:-?}"
	fi
	if [[ "$index_state" == "STALE" ]]; then
		warn "Index is STALE (lastCommit != HEAD). Agents must not auto-refresh; ask Jesús before gnx-analyze-here."
	fi
	if [[ "$index_state" == "UNKNOWN" ]]; then
		warn "Could not compare lastCommit with HEAD; treat index freshness as UNKNOWN."
	fi
fi

section "Lock status"
lbug_file="${repo_root}/.gitnexus/lbug"
if [[ -e "$lbug_file" ]]; then
	lbug_size="$(stat -c '%s' "$lbug_file" 2>/dev/null || stat -f '%z' "$lbug_file" 2>/dev/null || echo '?')"
	lbug_mtime="$(stat -c '%y' "$lbug_file" 2>/dev/null || stat -f '%Sm' "$lbug_file" 2>/dev/null || echo '?')"
	info "Lock file present: ${lbug_file}"
	note "size: ${lbug_size} bytes"
	note "mtime: ${lbug_mtime}"
	warn "Do not delete .gitnexus/lbug automatically. Check for live GitNexus/MCP processes first."

	process_lines="$(list_related_processes)"
	if [[ -n "$process_lines" ]]; then
		warn "Related processes detected (GitNexus MCP/analyze may hold the lock):"
		while IFS= read -r line; do
			[[ -n "$line" ]] && note "$line"
		done <<<"$process_lines"
		warn "Wait for MCP/analyze to finish or close the IDE before running gnx-analyze-here."
	else
		info "No gitnexus/ladybug processes detected in ps output."
	fi
else
	info "Lock file absent: ${lbug_file}"
fi

section "Artifacts"
for artifact in \
	"${repo_root}/.gitnexus" \
	"${lbug_file}" \
	"${repo_root}/AGENTS.md" \
	"${repo_root}/CLAUDE.md" \
	"${repo_root}/docs/wiki"; do
	if [[ -e "$artifact" ]]; then
		info "present: ${artifact}"
	else
		note "absent:  ${artifact}"
	fi
done

if has_gitnexus_marker "${repo_root}/AGENTS.md"; then
	note "AGENTS.md contains <!-- gitnexus:* --> block (derivado; no editar/commit sin revisión)"
fi
if has_gitnexus_marker "${repo_root}/CLAUDE.md"; then
	note "CLAUDE.md contains <!-- gitnexus:* --> block (derivado; no editar/commit sin revisión)"
fi

section "Recommendations"
info "Allowed for agents:"
note "  make gitnexus-status"
note "  GitNexus MCP read-only queries (query, context, impact, detect_changes, …)"
note "  make update-check"
note "  Read docs/GITNEXUS_OPERATIONAL_POLICY.md"

info "Requires explicit human approval (Jesús):"
note "  gnx-analyze-here --skip-agents-md (canonical dotfiles index refresh)"
note "  gnx-analyze-here without --skip-agents-md (regenerates AGENTS/CLAUDE blocks; exception)"
note "  gnx-wiki-here / wiki subcommand"
note "  clean subcommand"
note "  deleting .gitnexus/lbug"
note "  editing <!-- gitnexus:* --> blocks in AGENTS.md / CLAUDE.md"
note "  committing AGENTS.md / CLAUDE.md changes produced by analyze"

info "Not recommended for agents in IDE shells:"
note "  npx invocations (may use IDE Node <22)"

exit 0
