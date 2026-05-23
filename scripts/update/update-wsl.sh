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

want_section() {
	[[ "$SECTION" == "all" || "$SECTION" == "$1" ]]
}

run_apt() {
	section "APT"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "APT" "mocked"
		return 0
	fi
	if ! command -v sudo >/dev/null 2>&1; then
		result_incident "WSL" "APT" "sudo not found"
		return 0
	fi
	run_step "WSL" "APT update" "${LOG_DIR}/wsl-apt-update.log" sudo apt-get update -y
	run_step "WSL" "APT upgrade" "${LOG_DIR}/wsl-apt-upgrade.log" sudo apt-get upgrade -y
	run_step "WSL" "APT autoremove" "${LOG_DIR}/wsl-apt-autoremove.log" sudo apt-get autoremove -y
}

ensure_node_runtime() {
	local version major
	if ! command -v node >/dev/null 2>&1; then
		result_incident "WSL" "Node" "node not found; run make install-node-stack"
		return 1
	fi
	version="$(node --version 2>/dev/null || true)"
	major="$(node_major "$version")"
	if [[ -z "$major" || "$major" -lt 22 ]]; then
		result_incident "WSL" "Node" "Node ${version:-unknown} is below required >=22; GitNexus update skipped; run make install-node-stack"
		return 1
	fi
	result_ok "WSL" "Node" "runtime ${version} satisfies >=22"
	return 0
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
		result_incident "WSL" "npm" "npm not found after Node validation"
		return 0
	fi

	run_step "WSL" "Codex CLI" "${LOG_DIR}/wsl-codex.log" npm install -g --prefix="$npm_prefix" @openai/codex@latest
	run_step "WSL" "ast-grep CLI" "${LOG_DIR}/wsl-ast-grep.log" npm install -g --prefix="$npm_prefix" @ast-grep/cli@latest
	run_step "WSL" "GitNexus CLI" "${LOG_DIR}/wsl-gitnexus.log" npm install -g --prefix="$npm_prefix" gitnexus@latest
	if command -v gitnexus >/dev/null 2>&1; then
		result_ok "WSL" "GitNexus" "usable: $(gitnexus --version 2>/dev/null || echo version unknown)"
	else
		result_incident "WSL" "GitNexus" "install finished but gitnexus not found in PATH"
	fi
	if command -v corepack >/dev/null 2>&1; then
		run_step "WSL" "pnpm" "${LOG_DIR}/wsl-pnpm.log" corepack prepare pnpm@latest --activate
	else
		result_warn "WSL" "pnpm" "corepack not found; skipped"
	fi
	local agent_tools_script="${DOTFILES_ROOT}/scripts/install-agent-tools.sh"
	if [[ -x "$agent_tools_script" ]]; then
		run_step "WSL" "Agent validation tools" "${LOG_DIR}/wsl-agent-tools.log" "$agent_tools_script" --external-only --upgrade
	fi
}

run_opencode() {
	section "OpenCode"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "OpenCode" "mocked"
		return 0
	fi
	run_step "WSL" "OpenCode" "${LOG_DIR}/wsl-opencode.log" bash -c 'curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path'
}

run_shell() {
	section "Shell"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "Oh My Zsh" "mocked"
		result_ok "WSL" "uv" "mocked"
		return 0
	fi
	if command -v omz >/dev/null 2>&1 || [[ -d "${ZSH:-}" ]]; then
		run_step "WSL" "Oh My Zsh" "${LOG_DIR}/wsl-omz.log" omz update
	else
		result_info "WSL" "Oh My Zsh" "not installed; skipped"
	fi
	if command -v upgrade_oh_my_zsh_custom >/dev/null 2>&1; then
		run_step "WSL" "Oh My Zsh custom" "${LOG_DIR}/wsl-omz-custom.log" upgrade_oh_my_zsh_custom
	fi
	if command -v uv >/dev/null 2>&1; then
		local uv_path
		uv_path="$(command -v uv)"
		if [[ "$uv_path" == "$HOME/.local/bin/uv" ]]; then
			run_step "WSL" "uv" "${LOG_DIR}/wsl-uv.log" uv self update
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
	section "Services"
	if is_truthy "${DOTFILES_UPDATE_MOCK:-}"; then
		result_ok "WSL" "Services" "mocked"
		return 0
	fi
	if command -v apache2 >/dev/null 2>&1 && declare -F restart_apache >/dev/null 2>&1; then
		run_step "WSL" "Apache/MySQL" "${LOG_DIR}/wsl-services.log" restart_apache
	else
		result_info "WSL" "Services" "no managed local service restart required"
	fi
}

want_section apt && run_apt
want_section tools && run_tools
want_section tools && run_opencode
want_section shell && run_shell
want_section mcp && run_mcp
want_section services && run_services

result_info "WSL" "Projects" "personal projects are excluded; run make update-projects"
