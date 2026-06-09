#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"
# shellcheck source=scripts/update/lib/node_runtime.sh
source "${SCRIPT_DIR}/lib/node_runtime.sh"
# shellcheck source=scripts/update/lib/results.sh
source "${SCRIPT_DIR}/lib/results.sh"
# shellcheck source=scripts/update/lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"

SECTION="all"
if [[ "${1:-}" == "--section" ]]; then
	SECTION="${2:-all}"
fi

RUN_DIR="${DOTFILES_UPDATE_RUN_DIR:-$(new_run_dir)}"
LOG_DIR="${RUN_DIR}/logs"
mkdir -p "$LOG_DIR"
result_init "${RUN_DIR}/wsl-results.tsv"
TOOL_SNAPSHOT_FILE="${TOOL_SNAPSHOT_FILE:-${RUN_DIR}/tool-snapshot.tsv}"
tool_snapshot_init "$TOOL_SNAPSHOT_FILE"

want_section() {
	[[ "$SECTION" == "all" || "$SECTION" == "$1" ]]
}

probe_version_line() {
	"$@" 2>/dev/null | head -n 1 | tr -d '\r'
}

normalize_component_version() {
	local name="$1" version="${2:-}" lower
	lower="${name,,}"
	version="$(printf '%s\n' "$version" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
	case "$lower" in
	*codex*)
		version="$(printf '%s\n' "$version" | sed -E 's/^[Cc]odex([[:space:]-]+[Cc][Ll][Ii])?[[:space:]]+//; s/^codex-cli[[:space:]]+//')"
		;;
	*gitnexus*)
		version="$(printf '%s\n' "$version" | sed -E 's/^[Gg]it[Nn]exus[[:space:]]+//')"
		;;
	*ast-grep*)
		version="$(printf '%s\n' "$version" | sed -E 's/^(ast-grep|sg)[[:space:]]+//')"
		;;
	*actionlint*)
		version="$(printf '%s\n' "$version" | sed -E 's/^actionlint[[:space:]]+//; s/^v//')"
		;;
	*osv-scanner*)
		version="$(printf '%s\n' "$version" | sed -E 's/^osv-scanner[[:space:]]+(version:?[[:space:]]*)?//; s/^version:?[[:space:]]*//; s/^v([0-9])/\1/')"
		;;
	*opencode*)
		version="$(printf '%s\n' "$version" | sed -E 's/^[Oo]pen[Cc]ode[[:space:]]+//')"
		;;
	*uv*)
		version="$(printf '%s\n' "$version" | sed -E 's/^uv[[:space:]]+//; s/[[:space:]]+\([^)]*\)$//')"
		;;
	esac
	printf '%s\n' "$version"
}

format_version_transition() {
	local before="${1:-}" after="${2:-}"
	if [[ -z "$before" && -z "$after" ]]; then
		printf 'version unavailable\n'
	elif [[ -z "$before" && -n "$after" ]]; then
		printf 'unavailable → %s\n' "$after"
	elif [[ -n "$before" && -z "$after" ]]; then
		printf '%s → unavailable\n' "$before"
	elif [[ "$before" == "$after" ]]; then
		printf '%s (unchanged)\n' "$after"
	else
		printf '%s → %s\n' "$before" "$after"
	fi
}

record_version_transition() {
	local area="$1" name="$2" before="$3" after="$4"
	local message
	before="$(normalize_component_version "$name" "$before")"
	after="$(normalize_component_version "$name" "$after")"
	message="$(format_version_transition "$before" "$after")"
	message="${message%$'\n'}"
	info "${name} version: ${message}"
	result_info "$area" "${name} version" "$message"
	tool_snapshot_add "$name" "$before" "$after"
}

run_versioned_step() {
	local runner="$1" area="$2" name="$3" log_file="$4"
	shift 4
	local probe_delimiter_seen=0
	local -a probe_cmd=()
	while [[ $# -gt 0 ]]; do
		if [[ "$1" == "--" ]]; then
			probe_delimiter_seen=1
			shift
			break
		fi
		probe_cmd+=("$1")
		shift
	done
	[[ "$probe_delimiter_seen" -eq 1 ]] || return 2
	local before after
	before="$(probe_version_line "${probe_cmd[@]}" || true)"
	"$runner" "$area" "$name" "$log_file" "$@"
	if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" == "FAIL" ]]; then
		return 0
	fi
	after="$(probe_version_line "${probe_cmd[@]}" || true)"
	record_version_transition "$area" "$name" "$before" "$after"
}

run_apt() {
	section "APT"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "APT" "mocked"
		return 0
	fi
	if ! command -v sudo >/dev/null 2>&1; then
		result_fail "WSL" "APT" "sudo not found"
		return 0
	fi
	run_step "WSL" "APT update" "${LOG_DIR}/wsl-apt-update.log" sudo apt-get update -y
	run_step "WSL" "APT upgrade" "${LOG_DIR}/wsl-apt-upgrade.log" sudo apt-get upgrade -y
	run_step "WSL" "APT autoremove" "${LOG_DIR}/wsl-apt-autoremove.log" sudo apt-get autoremove -y
}

ensure_node_runtime() {
	local path version major min_major
	min_major="$(node_runtime_min_major)"
	path="$(command -v node 2>/dev/null || true)"
	if [[ -z "$path" ]]; then
		tool_snapshot_add "Node.js" "" ""
		result_fail "WSL" "Node" "node not found; run make install-node-stack"
		return 1
	fi
	version="$(node --version 2>/dev/null || true)"
	major="$(node_major "$version")"
	if [[ -z "$major" || "$major" -lt "$min_major" ]]; then
		tool_snapshot_add "Node.js" "$version" "$version"
		result_fail "WSL" "Node" "Node ${version:-unknown} at ${path} is below required >=${min_major}; run make install-node-stack"
		return 1
	fi
	tool_snapshot_add "Node.js" "$version" "$version"
	result_ok "WSL" "Node" "runtime ${version} at ${path} satisfies >=${min_major}"
	return 0
}

probe_named_version() {
	local name="$1"
	shift
	local raw
	raw="$(probe_version_line "$@" || true)"
	normalize_component_version "$name" "$raw"
}

append_log_line() {
	local log_file="$1" message="$2"
	mkdir -p "$(dirname "$log_file")"
	printf '%s\n' "$message" >>"$log_file"
}

global_npm_package_version() {
	local npm_prefix="$1" package_name="$2"
	local npm_root package_json
	npm_root="$(npm root -g --prefix="$npm_prefix" 2>/dev/null || true)"
	[[ -n "$npm_root" ]] || return 1
	package_json="${npm_root}/${package_name}/package.json"
	[[ -f "$package_json" ]] || return 1
	node -e 'const fs = require("fs"); const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); if (data && data.version) process.stdout.write(String(data.version));' "$package_json" 2>/dev/null
}

npm_dist_tag_version() {
	local package_name="$1" dist_tag="$2"
	npm view "${package_name}@${dist_tag}" version 2>/dev/null | head -n 1 | tr -d '\r'
}

run_gitnexus_postinstall_scripts() {
	local area="$1" log_file="$2" npm_prefix="$3"
	local gitnexus_dir script

	gitnexus_dir="$(npm root -g --prefix="$npm_prefix" 2>/dev/null)/gitnexus"
	if [[ ! -d "$gitnexus_dir/scripts" ]]; then
		append_log_line "$log_file" "postinstall: GitNexus scripts directory not found at ${gitnexus_dir}"
		result_fail "$area" "GitNexus CLI" "postinstall scripts not found"
		RUN_STEP_LAST_RESULT_STATUS="FAIL"
		return 1
	fi

	for script in \
		materialize-vendor-grammars.cjs \
		build-tree-sitter-dart.cjs \
		build-tree-sitter-proto.cjs \
		build-tree-sitter-swift.cjs; do
		if [[ -f "${gitnexus_dir}/scripts/${script}" ]]; then
			append_log_line "$log_file" "postinstall: node scripts/${script}"
			(
				cd "$gitnexus_dir" || exit 1
				node "scripts/${script}"
			) >>"$log_file" 2>&1 || {
				result_fail "$area" "GitNexus CLI" "postinstall ${script} failed"
				RUN_STEP_LAST_RESULT_STATUS="FAIL"
				return 1
			}
		fi
	done
}

pnpm_version_line() {
	pnpm --version 2>/dev/null | head -n 1 | tr -d '\r'
}

pnpm_major() {
	local version="${1:-}"
	version="${version#v}"
	printf '%s\n' "${version%%.*}"
}

pnpm_version_is_major_11() {
	local version="$1" major
	major="$(pnpm_major "$version")"
	[[ "$major" =~ ^[0-9]+$ && "$major" -eq 11 ]]
}

user_npm_prefix() {
	local configured="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-}}" npm_prefix
	if [[ -n "$configured" ]]; then
		printf '%s\n' "$configured"
		return 0
	fi
	npm_prefix="$(npm config get prefix 2>/dev/null | head -n 1 | tr -d '\r' || true)"
	case "$npm_prefix" in
	"" | /usr | /usr/ | /usr/local | /usr/local/)
		printf '%s\n' "$HOME/.npm-global"
		;;
	*)
		if [[ -d "$npm_prefix" && ! -w "$npm_prefix" ]]; then
			printf '%s\n' "$HOME/.npm-global"
		else
			printf '%s\n' "$npm_prefix"
		fi
		;;
	esac
}

remove_flow_created_pnpm_shims() {
	local prefix_bin="$1" marker="$2" shim
	[[ -f "$marker" ]] || return 0
	while IFS= read -r shim; do
		[[ -n "$shim" ]] || continue
		case "$shim" in
		"$prefix_bin"/pnpm | "$prefix_bin"/pnpm.CMD | "$prefix_bin"/pnpm.cmd | "$prefix_bin"/pnpm.ps1 | "$prefix_bin"/pnpx | "$prefix_bin"/pnpx.CMD | "$prefix_bin"/pnpx.cmd | "$prefix_bin"/pnpx.ps1)
			rm -f "$shim"
			;;
		esac
	done <"$marker"
}

record_pnpm_result() {
	local before="$1" after="$2" method="$3"
	record_version_transition "WSL" "pnpm" "$before" "$after"
	if [[ "$method" == "npm-global fallback" ]]; then
		result_warn "WSL" "pnpm method" "npm-global fallback after Corepack validation failed"
		warn "pnpm method: npm-global fallback after Corepack validation failed"
	else
		result_info "WSL" "pnpm method" "$method"
		info "pnpm method: $method"
	fi
}

update_pnpm_major_11() {
	local npm_prefix prefix_bin before after method marker corepack_bin corepack_log fallback_log
	before="$(pnpm_version_line || true)"
	npm_prefix="$(user_npm_prefix)"
	prefix_bin="${npm_prefix}/bin"
	mkdir -p "$prefix_bin" "${npm_prefix}/lib/node_modules"
	export PATH="${prefix_bin}:$PATH"
	corepack_log="${LOG_DIR}/wsl-pnpm-corepack.log"
	fallback_log="${LOG_DIR}/wsl-pnpm-fallback.log"
	marker="${LOG_DIR}/wsl-pnpm-created-shims.txt"
	: >"$marker"

	if ! command -v npm >/dev/null 2>&1; then
		result_fail "WSL" "pnpm" "npm not found; cannot update Corepack or pnpm"
		tool_snapshot_add "pnpm" "$before" ""
		return 0
	fi
	if ! npm --version >/dev/null 2>&1; then
		result_fail "WSL" "pnpm" "npm is not functional; cannot update Corepack or pnpm"
		tool_snapshot_add "pnpm" "$before" ""
		return 0
	fi

	run_npm_step "WSL" "Corepack" "${LOG_DIR}/wsl-corepack.log" npm install -g --prefix="$npm_prefix" corepack@latest
	if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" == "FAIL" ]]; then
		after="$(pnpm_version_line || true)"
		record_version_transition "WSL" "pnpm" "$before" "$after"
		result_fail "WSL" "pnpm" "Corepack update failed; pnpm major 11 convergence skipped"
		return 0
	fi

	corepack_bin="${prefix_bin}/corepack"
	if [[ ! -x "$corepack_bin" ]]; then
		result_fail "WSL" "pnpm" "updated Corepack not found at ${corepack_bin}"
		after="$(pnpm_version_line || true)"
		record_version_transition "WSL" "pnpm" "$before" "$after"
		return 0
	fi

	{
		printf 'prefix=%s\n' "$npm_prefix"
		printf 'corepack=%s\n' "$corepack_bin"
		for shim in pnpm pnpm.CMD pnpm.cmd pnpm.ps1 pnpx pnpx.CMD pnpx.cmd pnpx.ps1; do
			if [[ ! -e "${prefix_bin}/${shim}" ]]; then
				printf '%s\n' "${prefix_bin}/${shim}" >>"$marker"
			fi
		done
		"$corepack_bin" enable pnpm --install-directory "$prefix_bin"
		"$corepack_bin" prepare pnpm@latest-11 --activate
	} >"$corepack_log" 2>&1 && RUN_STEP_LAST_RESULT_STATUS="OK" || RUN_STEP_LAST_RESULT_STATUS="FAIL"

	after="$(pnpm_version_line || true)"
	if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" == "OK" && -n "$after" ]] && pnpm_version_is_major_11 "$after"; then
		record_pnpm_result "$before" "$after" "corepack"
		return 0
	fi

	result_warn "WSL" "pnpm Corepack" "Corepack did not produce a functional pnpm 11; falling back to npm global"
	warn "pnpm Corepack did not produce a functional pnpm 11; falling back to npm global"
	remove_flow_created_pnpm_shims "$prefix_bin" "$marker"
	run_npm_step "WSL" "pnpm fallback" "$fallback_log" npm install -g --prefix="$npm_prefix" "pnpm@^11"
	after="$(pnpm_version_line || true)"
	if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" == "FAIL" || -z "$after" ]] || ! pnpm_version_is_major_11 "$after"; then
		record_version_transition "WSL" "pnpm" "$before" "$after"
		result_fail "WSL" "pnpm" "fallback npm install did not produce a functional pnpm 11"
		return 0
	fi
	record_pnpm_result "$before" "$after" "npm-global fallback"
}

update_global_npm_tool_if_needed() {
	local area="$1" name="$2" log_file="$3" npm_prefix="$4" package_name="$5" dist_tag="$6"
	shift 6
	local probe_delimiter_seen=0
	local -a probe_cmd=()
	while [[ $# -gt 0 ]]; do
		if [[ "$1" == "--" ]]; then
			probe_delimiter_seen=1
			shift
			break
		fi
		probe_cmd+=("$1")
		shift
	done
	[[ "$probe_delimiter_seen" -eq 1 ]] || return 2

	local before after installed_version remote_version display_before display_installed
	before="$(probe_version_line "${probe_cmd[@]}" || true)"
	display_before="$(normalize_component_version "$name" "$before")"
	installed_version="$(global_npm_package_version "$npm_prefix" "$package_name" || true)"
	display_installed="${installed_version:-$display_before}"
	: >"$log_file"
	append_log_line "$log_file" "precheck: package=${package_name}@${dist_tag}"
	append_log_line "$log_file" "precheck: before_version=${display_before:-unavailable}"
	append_log_line "$log_file" "precheck: installed_package_version=${installed_version:-unavailable}"

	remote_version="$(npm_dist_tag_version "$package_name" "$dist_tag" || true)"
	if [[ -z "$remote_version" ]]; then
		append_log_line "$log_file" "precheck: remote_target_version=unavailable"
		if [[ -n "$display_installed" ]]; then
			warn "${name} update check failed; keeping installed version ${display_installed}"
			result_warn "$area" "$name" "update check failed; keeping installed version ${display_installed}"
			tool_snapshot_add "$name" "$display_before" "$display_before"
			RUN_STEP_LAST_RESULT_STATUS="WARN"
			return 0
		fi
		info "${name} update check failed; attempting installation without pre-resolved target"
		append_log_line "$log_file" "precheck: remote lookup failed; proceeding with install because tool is unavailable"
	else
		append_log_line "$log_file" "precheck: remote_target_version=${remote_version}"
		if [[ -n "$display_installed" && "$installed_version" == "$remote_version" ]]; then
			ok "${name} already latest: ${display_installed}"
			result_ok "$area" "$name" "already latest: ${display_installed}"
			tool_snapshot_add "$name" "$display_before" "$display_before"
			RUN_STEP_LAST_RESULT_STATUS="OK"
			return 0
		fi
		if [[ -n "$display_installed" ]]; then
			info "${name} update available: ${display_installed} → ${remote_version}"
		else
			info "${name} is not installed; installing latest available version ${remote_version}"
		fi
	fi

	run_npm_step "$area" "$name" "$log_file" npm install -g --prefix="$npm_prefix" "${package_name}@${dist_tag}"
	if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" == "FAIL" ]]; then
		return 0
	fi
	if [[ "$package_name" == "gitnexus" ]]; then
		run_gitnexus_postinstall_scripts "$area" "$log_file" "$npm_prefix" || return 0
	fi
	after="$(probe_version_line "${probe_cmd[@]}" || true)"
	record_version_transition "$area" "$name" "$before" "$after"
}

ingest_agent_tools_results() {
	local result_file="$1"
	[[ -f "$result_file" ]] || return 0
	while IFS=$'\t' read -r status tool message; do
		[[ "$status" == "WARN" && -n "$tool" && -n "$message" ]] || continue
		result_warn "WSL" "$tool" "$message"
		RUN_STEP_LAST_RESULT_STATUS="WARN"
	done <"$result_file"
}

run_tools() {
	section "Node and AI tools"
	local npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"
	local original_path="$PATH" overlay="" switched=0
	mkdir -p "$npm_prefix/bin" "$npm_prefix/lib/node_modules"

	node_runtime_probe
	if [[ "$NODE_RUNTIME_EFFECTIVE_OK" -eq 1 ]]; then
		export PATH="$npm_prefix/bin:$PATH"
		tool_snapshot_add "Node.js" "$NODE_RUNTIME_EFFECTIVE_VERSION" "$NODE_RUNTIME_EFFECTIVE_VERSION"
		result_ok "WSL" "Node" "runtime ${NODE_RUNTIME_EFFECTIVE_VERSION} at ${NODE_RUNTIME_EFFECTIVE_PATH} satisfies >=${NODE_RUNTIME_MIN_MAJOR}"
	elif [[ "$NODE_RUNTIME_MANAGED_OK" -eq 1 ]]; then
		overlay="$(node_runtime_create_overlay "$RUN_DIR" "$NODE_RUNTIME_MANAGED_PATH")"
		export PATH
		PATH="$(node_runtime_controlled_path "$overlay" "$npm_prefix" "$original_path")"
		switched=1
		local active_node active_version
		active_node="$(command -v node 2>/dev/null || true)"
		active_version="$(node --version 2>/dev/null || true)"
		if [[ "$active_node" != "${overlay}/node" ]] || ! node_runtime_version_satisfies "$active_version" "$NODE_RUNTIME_MIN_MAJOR"; then
			PATH="$original_path"
			node_runtime_cleanup_overlay "$overlay"
			result_fail "WSL" "Node" "managed runtime overlay did not activate cleanly; expected ${overlay}/node -> ${NODE_RUNTIME_MANAGED_PATH}, got ${active_node:-missing} ${active_version:-unknown}"
			tool_snapshot_add "Node.js" "$NODE_RUNTIME_EFFECTIVE_VERSION" "$NODE_RUNTIME_EFFECTIVE_VERSION"
			return 0
		fi
		info "Node runtime for managed tools: switched from ${NODE_RUNTIME_EFFECTIVE_VERSION:-missing} (${NODE_RUNTIME_EFFECTIVE_ORIGIN}) to ${NODE_RUNTIME_MANAGED_VERSION} (${NODE_RUNTIME_MANAGED_PATH})"
		result_info "WSL" "Node runtime for managed tools" "switched from ${NODE_RUNTIME_EFFECTIVE_VERSION:-missing} (${NODE_RUNTIME_EFFECTIVE_ORIGIN}) to ${NODE_RUNTIME_MANAGED_VERSION} (${NODE_RUNTIME_MANAGED_PATH})"
		tool_snapshot_add "Node.js" "$NODE_RUNTIME_EFFECTIVE_VERSION" "$NODE_RUNTIME_EFFECTIVE_VERSION"
		tool_snapshot_add "Node.js managed tools" "$NODE_RUNTIME_MANAGED_VERSION" "$NODE_RUNTIME_MANAGED_VERSION"
	else
		local effective_desc
		if [[ -n "$NODE_RUNTIME_EFFECTIVE_PATH" ]]; then
			effective_desc="${NODE_RUNTIME_EFFECTIVE_VERSION:-unknown} at ${NODE_RUNTIME_EFFECTIVE_PATH} (${NODE_RUNTIME_EFFECTIVE_ORIGIN})"
		else
			effective_desc="missing"
		fi
		result_fail "WSL" "Node" "effective runtime ${effective_desc} is below required >=${NODE_RUNTIME_MIN_MAJOR}; no compatible managed runtime available at ${NODE_RUNTIME_MANAGED_PATH}: ${NODE_RUNTIME_MANAGED_ERROR:-unknown}; run make install-node-stack"
		tool_snapshot_add "Node.js" "$NODE_RUNTIME_EFFECTIVE_VERSION" "$NODE_RUNTIME_EFFECTIVE_VERSION"
		return 0
	fi
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "Node / AI tools" "mocked"
		PATH="$original_path"
		node_runtime_cleanup_overlay "$overlay"
		return 0
	fi
	if ! command -v npm >/dev/null 2>&1; then
		result_fail "WSL" "npm" "npm not found after Node validation"
		PATH="$original_path"
		node_runtime_cleanup_overlay "$overlay"
		return 0
	fi

	update_global_npm_tool_if_needed "WSL" "Codex CLI" "${LOG_DIR}/wsl-codex.log" "$npm_prefix" "@openai/codex" "latest" codex --version --
	update_global_npm_tool_if_needed "WSL" "ast-grep CLI" "${LOG_DIR}/wsl-ast-grep.log" "$npm_prefix" "@ast-grep/cli" "latest" ast-grep --version --
	update_global_npm_tool_if_needed "WSL" "GitNexus CLI" "${LOG_DIR}/wsl-gitnexus.log" "$npm_prefix" "gitnexus" "latest" gitnexus --version --
	if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" != "FAIL" && "${RUN_STEP_LAST_RESULT_STATUS:-}" != "WARN" ]] && command -v gitnexus >/dev/null 2>&1; then
		result_ok "WSL" "GitNexus" "usable: $(gitnexus --version 2>/dev/null || echo version unknown)"
	elif [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" == "FAIL" ]]; then
		:
	else
		result_fail "WSL" "GitNexus" "install finished but gitnexus not found in PATH"
	fi
	update_pnpm_major_11
	local agent_tools_script="${DOTFILES_ROOT}/scripts/install-agent-tools.sh"
	if [[ -x "$agent_tools_script" ]]; then
		local actionlint_before actionlint_after osv_before osv_after agent_tools_results
		actionlint_before="$(probe_named_version "actionlint" actionlint --version || true)"
		osv_before="$(probe_named_version "osv-scanner" osv-scanner --version || true)"
		agent_tools_results="${LOG_DIR}/wsl-agent-tools-results.tsv"
		run_step "WSL" "Agent validation tools" "${LOG_DIR}/wsl-agent-tools.log" "$agent_tools_script" --external-only --upgrade --result-file "$agent_tools_results"
		ingest_agent_tools_results "$agent_tools_results"
		if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" != "FAIL" ]]; then
			actionlint_after="$(probe_named_version "actionlint" actionlint --version || true)"
			osv_after="$(probe_named_version "osv-scanner" osv-scanner --version || true)"
			tool_snapshot_add "actionlint" "$actionlint_before" "$actionlint_after"
			tool_snapshot_add "osv-scanner" "$osv_before" "$osv_after"
		fi
	fi
	if [[ "$switched" -eq 1 ]]; then
		PATH="$original_path"
		node_runtime_cleanup_overlay "$overlay"
	fi
}

run_opencode() {
	section "OpenCode"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "OpenCode" "mocked"
		return 0
	fi
	run_versioned_step run_step "WSL" "OpenCode" "${LOG_DIR}/wsl-opencode.log" opencode --version -- bash -c 'curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path'
}

run_shell() {
	section "Shell"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "Oh My Zsh" "mocked"
		result_ok "WSL" "uv" "mocked"
		return 0
	fi
	local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
	if [[ -x "${zsh_dir}/tools/upgrade.sh" ]]; then
		run_step "WSL" "Oh My Zsh" "${LOG_DIR}/wsl-omz.log" env ZSH="$zsh_dir" zsh "${zsh_dir}/tools/upgrade.sh" -v minimal
	elif [[ -d "$zsh_dir" ]]; then
		result_warn "WSL" "Oh My Zsh" "installed at ${zsh_dir} but tools/upgrade.sh is missing"
	else
		result_info "WSL" "Oh My Zsh" "not installed; skipped"
	fi
	local custom_dir="${ZSH_CUSTOM:-${zsh_dir}/custom}"
	local plugin
	for plugin in powerlevel10k autoupdate zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting; do
		case "$plugin" in
		powerlevel10k)
			update_git_checkout "WSL" "Oh My Zsh custom powerlevel10k" "${custom_dir}/themes/powerlevel10k" "${LOG_DIR}/wsl-omz-powerlevel10k.log"
			;;
		*)
			update_git_checkout "WSL" "Oh My Zsh plugin ${plugin}" "${custom_dir}/plugins/${plugin}" "${LOG_DIR}/wsl-omz-plugin-${plugin}.log"
			;;
		esac
	done
}

update_git_checkout() {
	local area="$1" name="$2" repo_dir="$3" log_file="$4"
	if [[ -d "${repo_dir}/.git" ]]; then
		run_step "$area" "$name" "$log_file" git -C "$repo_dir" pull --ff-only
	elif [[ -e "$repo_dir" ]]; then
		result_warn "$area" "$name" "${repo_dir} exists but is not a git checkout; skipped"
	fi
}

run_uv_update() {
	if command -v uv >/dev/null 2>&1; then
		local uv_path
		uv_path="$(command -v uv)"
		if [[ "$uv_path" == "$HOME/.local/bin/uv" ]]; then
			run_versioned_step run_step "WSL" "uv" "${LOG_DIR}/wsl-uv.log" uv --version -- uv self update
		else
			result_info "WSL" "uv" "detected at ${uv_path}; update with its owning package manager"
		fi
	else
		result_info "WSL" "uv" "not installed; install with make install-uv"
	fi
}

run_mcp() {
	section "MCPs and Docker"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "MCPs" "mocked"
		return 0
	fi
	"${SCRIPT_DIR}/update-excalidraw.sh" update --results "${RESULTS_FILE}" --log-dir "$LOG_DIR" || true
	result_info "WSL" "mcp-server-fetch" "runtime-managed via uvx; no persistent uv tool install"
	local ai_venv="$HOME/.config/ai/runtime/.venv"
	local ai_req="${DOTFILES_ROOT}/ai/runtime/mcp/requirements.txt"
	if [[ -x "$ai_venv/bin/python" && -f "$ai_req" ]]; then
		if command -v uv >/dev/null 2>&1; then
			run_step "WSL" "Python MCP runtime" "${LOG_DIR}/wsl-mcp-python.log" uv pip install --python "$ai_venv/bin/python" -r "$ai_req" -U
		else
			run_step "WSL" "Python MCP runtime" "${LOG_DIR}/wsl-mcp-python.log" "$ai_venv/bin/python" -m pip install -r "$ai_req" -U
		fi
	fi
	result_info "WSL" "MCP runtime" "npx/uvx launchers resolve at runtime; use make ai-mcp-governance after manifest/template changes"
}

run_services() {
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		return 0
	fi
	if command -v apache2 >/dev/null 2>&1 && declare -F restart_apache >/dev/null 2>&1; then
		section "Services"
		run_step "WSL" "Apache/MySQL" "${LOG_DIR}/wsl-services.log" restart_apache
	fi
}

want_section apt && run_apt
want_section tools && run_tools
want_section tools && run_opencode
want_section shell && run_shell
want_section shell && run_uv_update
want_section mcp && run_mcp
want_section services && run_services

result_info "WSL" "Projects" "personal projects are excluded; run make update-projects"
