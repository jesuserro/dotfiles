#!/usr/bin/env bash
# Sourceable GitNexus runtime helpers for interactive aliases and repository hooks.

_gnx_analyze_log_has_lbug_lock() {
	local log_file="$1"
	grep -Eq 'Could not set lock|\.gitnexus/lbug|docs\.ladybugdb\.com/concurrency' "$log_file"
}

_gnx_print_lbug_lock_hint() {
	echo ""
	echo "GitNexus no pudo bloquear .gitnexus/lbug."
	echo "Puede haber otro GitNexus MCP/analyze usando el indice, o un lock stale."
	echo "Diagnostico seguro:"
	echo "  ps aux | grep -Ei 'gitnexus|ladybug|node' | grep -v grep"
	echo "Si hay procesos gitnexus activos, cierralos o espera a que terminen y reintenta."
	echo "Si no hay procesos activos y el fallo persiste, reinicia el IDE/MCP antes de limpiar el indice manualmente."
}

_gnx_run_gitnexus_analyze() {
	local gitnexus_bin="$1"
	shift

	local analyze_log exit_code=0
	analyze_log="$(mktemp "${TMPDIR:-/tmp}/gitnexus-analyze.XXXXXX")" || return 1

	(
		set -o pipefail
		"$gitnexus_bin" analyze "$@" 2>&1 | tee "$analyze_log"
	)
	exit_code=$?

	if [[ "$exit_code" -ne 0 ]] && _gnx_analyze_log_has_lbug_lock "$analyze_log"; then
		_gnx_print_lbug_lock_hint
	fi

	rm -f "$analyze_log"
	return "$exit_code"
}

_gnx_resolve_gitnexus_bin() {
	local npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"

	if command -v gitnexus >/dev/null 2>&1; then
		command -v gitnexus
		return 0
	elif [[ -x "$npm_prefix/bin/gitnexus" ]]; then
		echo "$npm_prefix/bin/gitnexus"
		return 0
	fi

	echo "GitNexus no esta instalado" >&2
	echo "Ejecuta: ~/dotfiles/scripts/install-gitnexus.sh" >&2
	return 1
}

_gnx_with_managed_node_invoke() {
	local gitnexus_bin="$1"
	shift
	"$gitnexus_bin" "$@"
}

_gnx_with_managed_node_impl() {
	local runner="$1"
	shift
	local runtime_lib="${DOTFILES_DIR:-$HOME/dotfiles}/scripts/update/lib/node_runtime.sh"
	local npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"
	local original_path="$PATH"
	local gitnexus_bin="" overlay="" exit_code=0

	gitnexus_bin="$(_gnx_resolve_gitnexus_bin)" || return 1

	if [[ ! -r "$runtime_lib" ]]; then
		echo "No se pudo cargar el helper de Node gestionado" >&2
		echo "Ejecuta: make update-check" >&2
		return 1
	fi

	if [[ -n "${ZSH_VERSION:-}" ]]; then
		setopt local_options no_aliases
	fi
	# shellcheck source=scripts/update/lib/node_runtime.sh
	source "$runtime_lib"
	node_runtime_probe

	if [[ "$NODE_RUNTIME_EFFECTIVE_OK" -eq 1 ]]; then
		"$runner" "$gitnexus_bin" "$@"
		return $?
	fi

	if [[ "$NODE_RUNTIME_MANAGED_OK" -ne 1 ]]; then
		echo "Node.js efectivo no cumple >=${NODE_RUNTIME_MIN_MAJOR} y no hay Node gestionado compatible" >&2
		echo "Ejecuta: make update-check" >&2
		return 1
	fi

	overlay="$(node_runtime_create_overlay "${TMPDIR:-/tmp}" "$NODE_RUNTIME_MANAGED_PATH")" || return 1
	PATH="$(node_runtime_controlled_path "$overlay" "$npm_prefix" "$original_path")"
	export PATH

	"$runner" "$gitnexus_bin" "$@"
	exit_code=$?

	PATH="$original_path"
	export PATH
	node_runtime_cleanup_overlay "$overlay"
	return "$exit_code"
}

_gnx_with_managed_node() {
	_gnx_with_managed_node_impl _gnx_with_managed_node_invoke "$@"
}

_gnx_analyze_with_managed_node() {
	_gnx_with_managed_node_impl _gnx_run_gitnexus_analyze "$@"
}

gitnexus_list_related_processes() {
	if command -v pgrep >/dev/null 2>&1; then
		pgrep -af '(/| )gitnexus (mcp|analyze|serve|wiki)|ladybug' || true
	else
		# shellcheck disable=SC2009
		ps aux 2>/dev/null | grep -Ei '(/| )gitnexus (mcp|analyze|serve|wiki)|ladybug' | grep -v grep || true
	fi
}

gitnexus_index_in_use() {
	local repo_root="$1"
	local lbug_file="${repo_root}/.gitnexus/lbug"
	local process_lines=""

	if [[ -e "$lbug_file" ]] && command -v lsof >/dev/null 2>&1 && lsof -- "$lbug_file" >/dev/null 2>&1; then
		return 0
	fi

	process_lines="$(gitnexus_list_related_processes)"
	[[ -n "$process_lines" ]]
}

# shellcheck disable=SC2120
gitnexus_serve() {
	_gnx_with_managed_node serve "$@"
}

gitnexus_analyze_here() {
	local repo_root
	repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
		echo "No estas en un repositorio Git" >&2
		return 1
	}

	echo "Analizando repositorio actual con GitNexus..."
	(
		cd "$repo_root" || exit 1
		_gnx_analyze_with_managed_node "$@"
	)
}

gitnexus_wiki_here() {
	local repo_root api_key="" wiki_output
	repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
		echo "No estas en un repositorio Git" >&2
		return 1
	}

	if [[ -n "${OPENAI_API_KEY:-}" ]]; then
		api_key="$OPENAI_API_KEY"
	elif [[ -n "${GITNEXUS_API_KEY:-}" ]]; then
		api_key="$GITNEXUS_API_KEY"
	fi

	if [[ -z "$api_key" ]]; then
		echo "No se encontro API key de OpenAI" >&2
		echo "Configura OPENAI_API_KEY o GITNEXUS_API_KEY" >&2
		return 1
	fi

	wiki_output="$repo_root/docs/wiki"
	mkdir -p "$wiki_output"

	(
		cd "$repo_root" || exit 1
		if ! _gnx_with_managed_node status >/dev/null 2>&1; then
			echo "Indexando repositorio..."
			_gnx_analyze_with_managed_node || exit $?
		fi
		echo "Generando wiki en $wiki_output..."
		_gnx_with_managed_node wiki "$wiki_output" --api-key "$api_key"
	)
}

gitnexus_map() {
	gitnexus_analyze_here "$@" || return $?
	echo ""
	echo "Iniciando servidor GitNexus..."
	echo "Presiona Ctrl+C para detener"
	# shellcheck disable=SC2119
	gitnexus_serve
}
