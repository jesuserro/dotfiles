#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"
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
	local version major
	if ! command -v node >/dev/null 2>&1; then
		tool_snapshot_add "Node.js" "" ""
		result_fail "WSL" "Node" "node not found; run make install-node-stack"
		return 1
	fi
	version="$(node --version 2>/dev/null || true)"
	major="$(node_major "$version")"
	if [[ -z "$major" || "$major" -lt 22 ]]; then
		tool_snapshot_add "Node.js" "$version" "$version"
		result_fail "WSL" "Node" "Node ${version:-unknown} is below required >=22; GitNexus update skipped; run make install-node-stack"
		return 1
	fi
	tool_snapshot_add "Node.js" "$version" "$version"
	result_ok "WSL" "Node" "runtime ${version} satisfies >=22"
	return 0
}

probe_named_version() {
	local name="$1"
	shift
	local raw
	raw="$(probe_version_line "$@" || true)"
	normalize_component_version "$name" "$raw"
}

run_tools() {
	section "Node and AI tools"
	local npm_prefix="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
	export PATH="$npm_prefix/bin:$PATH"
	mkdir -p "$npm_prefix/bin" "$npm_prefix/lib/node_modules"

	if ! ensure_node_runtime; then
		result_warn "WSL" "GitNexus" "skipped because Node runtime is incompatible; run make install-node-stack"
		return 0
	fi
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "Node / AI tools" "mocked"
		return 0
	fi
	if ! command -v npm >/dev/null 2>&1; then
		result_fail "WSL" "npm" "npm not found after Node validation"
		return 0
	fi

	run_versioned_step run_npm_step "WSL" "Codex CLI" "${LOG_DIR}/wsl-codex.log" codex --version -- npm install -g --prefix="$npm_prefix" @openai/codex@latest
	run_versioned_step run_npm_step "WSL" "ast-grep CLI" "${LOG_DIR}/wsl-ast-grep.log" ast-grep --version -- npm install -g --prefix="$npm_prefix" @ast-grep/cli@latest
	run_versioned_step run_npm_step "WSL" "GitNexus CLI" "${LOG_DIR}/wsl-gitnexus.log" gitnexus --version -- npm install -g --prefix="$npm_prefix" gitnexus@latest
	if command -v gitnexus >/dev/null 2>&1; then
		result_ok "WSL" "GitNexus" "usable: $(gitnexus --version 2>/dev/null || echo version unknown)"
	else
		result_fail "WSL" "GitNexus" "install finished but gitnexus not found in PATH"
	fi
	if command -v corepack >/dev/null 2>&1; then
		run_versioned_step run_step "WSL" "pnpm" "${LOG_DIR}/wsl-pnpm.log" pnpm --version -- corepack prepare pnpm@latest --activate
	else
		result_skip "WSL" "pnpm" "corepack not found; skipped"
	fi
	local agent_tools_script="${DOTFILES_ROOT}/scripts/install-agent-tools.sh"
	if [[ -x "$agent_tools_script" ]]; then
		local actionlint_before actionlint_after osv_before osv_after
		actionlint_before="$(probe_named_version "actionlint" actionlint --version || true)"
		osv_before="$(probe_named_version "osv-scanner" osv-scanner --version || true)"
		run_step "WSL" "Agent validation tools" "${LOG_DIR}/wsl-agent-tools.log" "$agent_tools_script" --external-only --upgrade
		if [[ "${RUN_STEP_LAST_RESULT_STATUS:-}" != "FAIL" ]]; then
			actionlint_after="$(probe_named_version "actionlint" actionlint --version || true)"
			osv_after="$(probe_named_version "osv-scanner" osv-scanner --version || true)"
			tool_snapshot_add "actionlint" "$actionlint_before" "$actionlint_after"
			tool_snapshot_add "osv-scanner" "$osv_before" "$osv_after"
		fi
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
	for plugin in powerlevel10k autoupdate z zsh-autosuggestions zsh-completions zsh-history-substring-search zsh-syntax-highlighting; do
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
	if command -v uv >/dev/null 2>&1; then
		run_step "WSL" "mcp-server-fetch" "${LOG_DIR}/wsl-mcp-fetch.log" uv tool install mcp-server-fetch
	fi
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
