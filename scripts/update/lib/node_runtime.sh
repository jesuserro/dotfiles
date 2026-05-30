#!/usr/bin/env bash
# Controlled Node runtime helpers for update tooling.
# shellcheck shell=bash

node_runtime_min_major() {
	local major="${DOTFILES_NODE_MIN_MAJOR:-22}"
	if [[ "$major" =~ ^[0-9]+$ ]]; then
		printf '%s\n' "$major"
	else
		printf '22\n'
	fi
}

node_runtime_major() {
	local version="${1#v}"
	version="${version%%.*}"
	if [[ "$version" =~ ^[0-9]+$ ]]; then
		printf '%s\n' "$version"
	else
		printf '\n'
	fi
}

node_runtime_version_for() {
	local node_bin="$1"
	[[ -n "$node_bin" && -x "$node_bin" ]] || return 1
	"$node_bin" --version 2>/dev/null | head -n 1 | tr -d '\r'
}

node_runtime_version_satisfies() {
	local version="$1" min_major="${2:-$(node_runtime_min_major)}" major
	major="$(node_runtime_major "$version")"
	[[ -n "$major" && "$major" -ge "$min_major" ]]
}

node_runtime_effective_path() {
	command -v node 2>/dev/null || true
}

node_runtime_origin_label() {
	local path="$1"
	case "$path" in
	*/.cursor-server/*) printf 'cursor-server' ;;
	*/.vscode-server/*) printf 'vscode-server' ;;
	*/.windsurf-server/*) printf 'windsurf-server' ;;
	*/.codex/* | */.opencode/* | */extensions/*/bin/*) printf 'remote-agent' ;;
	"") printf 'missing' ;;
	*) printf 'unknown-shadowing' ;;
	esac
}

node_runtime_resolve_managed_candidate() {
	if [[ -n "${DOTFILES_MANAGED_NODE_BIN:-}" ]]; then
		printf '%s\n' "$DOTFILES_MANAGED_NODE_BIN"
		return 0
	fi
	printf '/usr/bin/node\n'
}

node_runtime_probe() {
	local min_major effective_path effective_version effective_ok=0 origin
	local managed_path managed_version managed_ok=0 managed_error=""
	min_major="$(node_runtime_min_major)"
	effective_path="$(node_runtime_effective_path)"
	if [[ -n "$effective_path" ]]; then
		effective_version="$(node_runtime_version_for "$effective_path" || true)"
	else
		effective_version=""
	fi
	origin="$(node_runtime_origin_label "$effective_path")"
	if [[ -n "$effective_version" ]] && node_runtime_version_satisfies "$effective_version" "$min_major"; then
		effective_ok=1
	fi

	managed_path="$(node_runtime_resolve_managed_candidate)"
	if [[ -z "$managed_path" ]]; then
		managed_error="managed candidate is empty"
	elif [[ ! -e "$managed_path" ]]; then
		managed_error="managed candidate does not exist"
	elif [[ ! -x "$managed_path" ]]; then
		managed_error="managed candidate is not executable"
	else
		managed_version="$(node_runtime_version_for "$managed_path" || true)"
		if [[ -z "$managed_version" ]]; then
			managed_error="managed candidate did not return a Node version"
		elif node_runtime_version_satisfies "$managed_version" "$min_major"; then
			managed_ok=1
		else
			managed_error="managed candidate ${managed_version} is below required >=${min_major}"
		fi
	fi

	NODE_RUNTIME_MIN_MAJOR="$min_major"
	NODE_RUNTIME_EFFECTIVE_PATH="$effective_path"
	NODE_RUNTIME_EFFECTIVE_VERSION="$effective_version"
	NODE_RUNTIME_EFFECTIVE_OK="$effective_ok"
	NODE_RUNTIME_EFFECTIVE_ORIGIN="$origin"
	NODE_RUNTIME_MANAGED_PATH="$managed_path"
	NODE_RUNTIME_MANAGED_VERSION="${managed_version:-}"
	NODE_RUNTIME_MANAGED_OK="$managed_ok"
	NODE_RUNTIME_MANAGED_ERROR="$managed_error"
}

node_runtime_create_overlay() {
	local base_dir="$1" managed_node="$2" overlay
	mkdir -p "$base_dir"
	overlay="$(mktemp -d "${base_dir%/}/node-runtime.XXXXXX")"
	ln -s "$managed_node" "${overlay}/node"
	printf '%s\n' "$overlay"
}

node_runtime_cleanup_overlay() {
	local overlay="${1:-}"
	[[ -n "$overlay" && -d "$overlay" ]] || return 0
	case "$(basename "$overlay")" in
	node-runtime.*) rm -rf -- "$overlay" ;;
	esac
}

node_runtime_controlled_path() {
	local overlay="$1" npm_prefix="$2" original_path="$3"
	printf '%s\n' "${overlay}:${npm_prefix}/bin:${original_path}"
}

node_runtime_need_overlay() {
	node_runtime_probe
	[[ "$NODE_RUNTIME_EFFECTIVE_OK" -ne 1 && "$NODE_RUNTIME_MANAGED_OK" -eq 1 ]]
}

node_runtime_diagnostic_effective() {
	node_runtime_probe
	if [[ "$NODE_RUNTIME_EFFECTIVE_OK" -eq 1 ]]; then
		printf 'OK\tNode.js effective runtime: %s (%s)\n' "$NODE_RUNTIME_EFFECTIVE_VERSION" "$NODE_RUNTIME_EFFECTIVE_PATH"
	elif [[ -n "$NODE_RUNTIME_EFFECTIVE_PATH" ]]; then
		printf 'WARN\tNode.js effective runtime is below required >=%s: %s (%s, %s)\n' \
			"$NODE_RUNTIME_MIN_MAJOR" "${NODE_RUNTIME_EFFECTIVE_VERSION:-unknown}" "$NODE_RUNTIME_EFFECTIVE_PATH" "$NODE_RUNTIME_EFFECTIVE_ORIGIN"
	else
		printf 'WARN\tNode.js effective runtime missing; required >=%s\n' "$NODE_RUNTIME_MIN_MAJOR"
	fi

	if [[ "$NODE_RUNTIME_EFFECTIVE_OK" -ne 1 && "$NODE_RUNTIME_MANAGED_OK" -eq 1 ]]; then
		printf 'INFO\tManaged compatible runtime available for update tools: %s (%s)\n' \
			"$NODE_RUNTIME_MANAGED_VERSION" "$NODE_RUNTIME_MANAGED_PATH"
	elif [[ "$NODE_RUNTIME_EFFECTIVE_OK" -ne 1 ]]; then
		printf 'FAIL\tNode.js effective runtime is below required >=%s and no compatible managed runtime is available: %s (%s)\n' \
			"$NODE_RUNTIME_MIN_MAJOR" "${NODE_RUNTIME_MANAGED_ERROR:-no managed candidate}" "$NODE_RUNTIME_MANAGED_PATH"
	fi
}
