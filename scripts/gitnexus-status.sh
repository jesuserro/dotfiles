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

ok() {
	printf 'OK: %s\n' "$*"
}

GITNEXUS_CANONICAL_BIN="${GITNEXUS_CANONICAL_BIN:-$HOME/.local/bin/gitnexus}"

gitnexus_probe_version() {
	local bin="$1" version=""
	[[ -n "$bin" && -x "$bin" ]] || {
		printf 'unknown\n'
		return 0
	}
	version="$("$bin" --version 2>/dev/null | head -n 1 | tr -d '\r' || true)"
	if [[ -z "$version" ]]; then
		printf 'unknown\n'
	else
		printf '%s\n' "$version"
	fi
}

normalize_gitnexus_path() {
	local path="$1"
	[[ -n "$path" ]] || return 1
	if command -v readlink >/dev/null 2>&1; then
		readlink -f "$path" 2>/dev/null || printf '%s\n' "$path"
	else
		printf '%s\n' "$path"
	fi
}

paths_equal() {
	local left="" right=""
	left="$(normalize_gitnexus_path "$1" 2>/dev/null || true)"
	right="$(normalize_gitnexus_path "$2" 2>/dev/null || true)"
	[[ -n "$left" && -n "$right" && "$left" == "$right" ]]
}

collect_known_gitnexus_paths() {
	local npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"
	local -a raw=(
		"$GITNEXUS_CANONICAL_BIN"
		"${HOME}/.npm-global/bin/gitnexus"
		"${npm_prefix}/bin/gitnexus"
	)
	local path seen=""
	for path in "${raw[@]}"; do
		[[ -n "$path" && -x "$path" ]] || continue
		if [[ " ${seen} " != *" ${path} "* ]]; then
			printf '%s\n' "$path"
			seen+=" ${path}"
		fi
	done
}

run_mcp_process_lines() {
	if [[ -n "${GITNEXUS_STATUS_PS_CMD:-}" ]]; then
		# shellcheck disable=SC2090
		bash -c "${GITNEXUS_STATUS_PS_CMD}" 2>/dev/null || true
	else
		ps aux 2>/dev/null | grep -Ei 'gitnexus mcp' | grep -v grep || true
	fi
}

summarize_mcp_gitnexus_paths() {
	local line path
	declare -A counts=()
	while IFS= read -r line; do
		[[ -z "$line" ]] && continue
		if [[ "$line" =~ (/[^[:space:]]+/gitnexus)[[:space:]]+mcp ]]; then
			path="${BASH_REMATCH[1]}"
			counts["$path"]=$((${counts["$path"]:-0} + 1))
		fi
	done < <(run_mcp_process_lines)

	local key
	for key in "${!counts[@]}"; do
		printf '%s\t%d\n' "$key" "${counts[$key]}"
	done | sort
}

gitnexus_collect_distinct_versions() {
	local -a versions=("$@")
	local version seen="" unique=()
	for version in "${versions[@]}"; do
		[[ -z "$version" || "$version" == "unknown" ]] && continue
		if [[ " ${seen} " != *" ${version} "* ]]; then
			unique+=("$version")
			seen+=" ${version}"
		fi
	done
	printf '%s\n' "${unique[@]}"
}

report_gitnexus_path_alignment() {
	local canonical_bin="${GITNEXUS_CANONICAL_BIN}"
	local npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"
	local npm_global_bin="${HOME}/.npm-global/bin/gitnexus"
	local path_gitnexus="" path_version="" canonical_version=""
	local -a known_paths=() mcp_entries=() all_versions=() distinct_versions=()
	local path_aligned=0 mcp_aligned=-1 mcp_all_match=1 version_mismatch=0
	local mcp_path mcp_count idx

	section "GitNexus path alignment"

	if [[ -n "${MCP_GITNEXUS_BIN:-}" ]]; then
		info "MCP_GITNEXUS_BIN override is set: ${MCP_GITNEXUS_BIN}"
	fi

	info "Canonical agent GitNexus: ${canonical_bin}"

	path_gitnexus="$(command -v gitnexus 2>/dev/null || true)"
	if [[ -n "$path_gitnexus" ]]; then
		path_version="$(gitnexus_probe_version "$path_gitnexus")"
		info "PATH GitNexus: ${path_gitnexus} (version ${path_version})"
		all_versions+=("$path_version")
	else
		info "PATH GitNexus: not found in PATH"
	fi

	if [[ -x "$canonical_bin" ]]; then
		canonical_version="$(gitnexus_probe_version "$canonical_bin")"
		if [[ -n "$path_gitnexus" ]] && ! paths_equal "$path_gitnexus" "$canonical_bin"; then
			info "Local GitNexus: ${canonical_bin} (version ${canonical_version})"
		fi
		all_versions+=("$canonical_version")
	fi

	while IFS= read -r path; do
		[[ -n "$path" ]] || continue
		known_paths+=("$path")
	done < <(collect_known_gitnexus_paths)

	if ((${#known_paths[@]} > 0)); then
		info "Known GitNexus binaries:"
		for path in "${known_paths[@]}"; do
			note "  ${path} (version $(gitnexus_probe_version "$path"))"
		done
	fi

	if [[ -n "$path_gitnexus" ]] && paths_equal "$path_gitnexus" "$canonical_bin"; then
		ok "PATH GitNexus matches canonical agent path."
		path_aligned=1
	elif [[ -n "$path_gitnexus" ]]; then
		warn "PATH GitNexus differs from canonical agent path."
	else
		info "PATH GitNexus unavailable; cannot verify PATH/canonical alignment."
	fi

	if [[ -x "$canonical_bin" && -n "$path_gitnexus" ]] && ! paths_equal "$path_gitnexus" "$canonical_bin"; then
		if paths_equal "$path_gitnexus" "$npm_global_bin" ||
			[[ "$path_gitnexus" == "${npm_prefix}/bin/gitnexus" ]]; then
			warn "${HOME}/.npm-global/bin/gitnexus shadows canonical agent GitNexus."
		fi
	fi

	while IFS=$'\t' read -r mcp_path mcp_count; do
		[[ -n "$mcp_path" ]] || continue
		mcp_entries+=("$mcp_path" "$mcp_count")
	done < <(summarize_mcp_gitnexus_paths)

	if ((${#mcp_entries[@]} == 0)); then
		info "No live GitNexus MCP processes detected."
		info "MCP path alignment cannot be verified until an MCP is running."
	else
		info "Live MCP GitNexus paths:"
		idx=0
		while ((idx < ${#mcp_entries[@]})); do
			mcp_path="${mcp_entries[$idx]}"
			mcp_count="${mcp_entries[$((idx + 1))]}"
			note "  ${mcp_path} (${mcp_count} processes)"
			if ! paths_equal "$mcp_path" "$canonical_bin"; then
				mcp_all_match=0
			fi
			if [[ -x "$mcp_path" ]]; then
				all_versions+=("$(gitnexus_probe_version "$mcp_path")")
			fi
			idx=$((idx + 2))
		done

		if [[ "$mcp_all_match" -eq 1 ]]; then
			ok "live MCP GitNexus paths match canonical agent path."
			mcp_aligned=1
		else
			warn "live MCP GitNexus paths differ from canonical agent path."
			mcp_aligned=0
		fi
	fi

	mapfile -t distinct_versions < <(gitnexus_collect_distinct_versions "${all_versions[@]}")
	if ((${#distinct_versions[@]} > 1)); then
		version_mismatch=1
		warn "GitNexus CLI/MCP version mismatch may cause storage version mismatch."
	elif [[ "$path_aligned" -eq 1 && "$mcp_aligned" -eq 1 && "$version_mismatch" -eq 0 ]]; then
		ok "GitNexus path alignment is agent-safe for read-only impact/context."
	elif [[ "$path_aligned" -eq 1 && "$mcp_aligned" -eq -1 && "$version_mismatch" -eq 0 ]] &&
		((${#distinct_versions[@]} <= 1)); then
		ok "GitNexus path alignment is agent-safe for read-only impact/context."
	fi
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

report_gitnexus_path_alignment

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
note "  make gitnexus-status (includes GitNexus path alignment diagnostics)"
note "  GitNexus MCP read-only queries when path alignment is OK"
note "  manual rg/grep + focused tests when status warns and scope is bounded"
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
