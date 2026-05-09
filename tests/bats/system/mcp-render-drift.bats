#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	GEN="${DOTFILES_DIR}/scripts/generate-mcp-configs.py"
	BUILD_MCPS="${DOTFILES_DIR}/build/mcps"
	TMPL_CURSOR="${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl"
	TMPL_CODEX="${DOTFILES_DIR}/dot_codex/config.toml.tmpl"
	TMPL_OPENCODE="${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl"
}

_sum() {
	sha256sum "$1" | awk '{print $1}'
}

@test "generate-mcp-configs.py passes py_compile" {
	[[ -f "${GEN}" ]]
	run python3 -m py_compile "${GEN}"
	[[ "${status}" -eq 0 ]]
}

@test "make ai-mcp-render creates build/mcps outputs" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	[[ -f "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl" ]]
	[[ -f "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl" ]]
	[[ -f "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl" ]]
}

@test "ai-mcp-render does not modify productive Chezmoi templates" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	local a b c
	a="$(_sum "${TMPL_CURSOR}")"
	b="$(_sum "${TMPL_CODEX}")"
	c="$(_sum "${TMPL_OPENCODE}")"
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	[[ "$(_sum "${TMPL_CURSOR}")" == "${a}" ]]
	[[ "$(_sum "${TMPL_CODEX}")" == "${b}" ]]
	[[ "$(_sum "${TMPL_OPENCODE}")" == "${c}" ]]
}

@test "rendered MCP configs preserve Chezmoi homeDir placeholder" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	grep -q '{{ \.chezmoi\.homeDir }}' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '{{ \.chezmoi\.homeDir }}' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q '{{ \.chezmoi\.homeDir }}' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
}

@test "make ai-mcp-drift exits 0 with intentional parity only" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-drift
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"INTENTIONAL_PENDING_PARITY"* ]]
	[[ "${output}" == *"[cursor]"* ]] || [[ "${output}" == *"cursor"* ]]
	[[ "${output}" == *"[opencode]"* ]] || [[ "${output}" == *"opencode"* ]]
	[[ "${output}" == *"obsidian"* ]]
	[[ -f "${BUILD_MCPS}/drift-report.json" ]]
}
