#!/usr/bin/env bats

setup() {
	bats_require_minimum_version 1.5.0
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

@test "rendered Excalidraw MCP uses scoped workspace mount and export dir" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	grep -q 'EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q 'EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q 'EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
	grep -q '{{ \$excalidrawWorkspaceHost }}:/workspace/excalidraw' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '{{ \$excalidrawWorkspaceHost }}:/workspace/excalidraw' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q '{{ \$excalidrawWorkspaceHost }}:/workspace/excalidraw' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
	run ! grep -q '/mnt/c/Users/jesus/Documents/vault_trabajo:/workspace/excalidraw' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	run ! grep -q '/mnt/c/Users/jesus/Documents/vault_trabajo:/workspace/excalidraw' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	run ! grep -q '/mnt/c/Users/jesus/Documents/vault_trabajo:/workspace/excalidraw' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
}

@test "rendered MCP configs use Chezmoi ai.obsidian_vault_path for Obsidian" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	grep -q '{{ \.ai\.obsidian_vault_path }}' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '{{ \.ai\.obsidian_vault_path }}' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q '{{ \.ai\.obsidian_vault_path }}' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
}

@test "rendered MCP configs use Chezmoi excalidraw workspace variable for Excalidraw" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	grep -q '{{ \$excalidrawWorkspaceHost }}' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '{{ \$excalidrawWorkspaceHost }}' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q '{{ \$excalidrawWorkspaceHost }}' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
}

@test "make ai-mcp-drift exits 0 with intentional parity only" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-drift
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"INTENTIONAL_PENDING_PARITY"* ]]
	[[ "${output}" == *"--- UNEXPECTED_DRIFT ---"* ]]
	[[ "${output}" == *"(none)"* ]]
	[[ -f "${BUILD_MCPS}/drift-report.json" ]]
}

@test "rendered Docker MCP uses Docker Desktop Gateway via docker.exe" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-render
	[[ "${status}" -eq 0 ]]
	grep -q '"command": "docker.exe"' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '"mcp"' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '"gateway"' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q '"run"' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	run ! grep -q '@0xshariq/docker-mcp-server' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	run ! grep -q '\.codex/mcp/docker/node_modules' "${BUILD_MCPS}/dot_cursor/mcp.json.tmpl"
	grep -q 'command = "docker.exe"' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q 'args = \["mcp", "gateway", "run"\]' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	run ! grep -q '@0xshariq/docker-mcp-server' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	run ! grep -q '\.codex/mcp/docker/node_modules' "${BUILD_MCPS}/dot_codex/mcp_servers.toml.tmpl"
	grep -q '"docker.exe"' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
	grep -q '"gateway"' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
	run ! grep -q '@0xshariq/docker-mcp-server' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
	run ! grep -q '\.codex/mcp/docker/node_modules' "${BUILD_MCPS}/dot_config/opencode/opencode.json.tmpl"
}

@test "productive Chezmoi templates also use Docker Desktop Gateway via docker.exe" {
	run ! grep -q '\.codex/mcp/docker/node_modules' "${TMPL_CURSOR}"
	run ! grep -q '\.codex/mcp/docker/node_modules' "${TMPL_CODEX}"
	run ! grep -q '\.codex/mcp/docker/node_modules' "${TMPL_OPENCODE}"
	run ! grep -q '@0xshariq/docker-mcp-server' "${TMPL_CURSOR}"
	run ! grep -q '@0xshariq/docker-mcp-server' "${TMPL_CODEX}"
	run ! grep -q '@0xshariq/docker-mcp-server' "${TMPL_OPENCODE}"
	grep -q '"command": "docker.exe"' "${TMPL_CURSOR}"
	grep -q 'command = "docker.exe"' "${TMPL_CODEX}"
	grep -q '"docker.exe"' "${TMPL_OPENCODE}"
}

@test "make ai-mcp-generate without APPLY does not modify productive templates" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	local a b c
	a="$(_sum "${TMPL_CURSOR}")"
	b="$(_sum "${TMPL_CODEX}")"
	c="$(_sum "${TMPL_OPENCODE}")"
	run make -C "${DOTFILES_DIR}" ai-mcp-generate
	[[ "${status}" -eq 0 ]]
	[[ "$(_sum "${TMPL_CURSOR}")" == "${a}" ]]
	[[ "$(_sum "${TMPL_CODEX}")" == "${b}" ]]
	[[ "$(_sum "${TMPL_OPENCODE}")" == "${c}" ]]
}

@test "make ai-mcp-generate without APPLY prints APPLY=1 hint" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-generate
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"APPLY=1"* ]]
	[[ "${output}" == *"plan only"* ]] || [[ "${output}" == *"no files written"* ]]
}

@test "merge_codex_productive preserves preamble and plugins (in-memory)" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	cd "${DOTFILES_DIR}" || exit 1
	run python3 -c "
import runpy
from pathlib import Path
root = Path('.')
g = runpy.run_path('scripts/generate-mcp-configs.py')
full = (root / 'dot_codex' / 'config.toml.tmpl').read_text(encoding='utf-8')
frag = '[mcp_servers.__probe_merge__]\ncommand = \"true\"\nenabled = true\n'
out = g['merge_codex_productive'](full, frag)
import tomllib
tomllib.loads(g['strip_chezmoi_template_preamble'](out))
assert 'model =' in out
assert '[plugins.' in out
assert '__probe_merge__' in out
assert 'excalidrawWorkspaceHost' in out
"
	[[ "${status}" -eq 0 ]]
}

@test "validate render drift generate plan succeed in sequence" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run bash -c "cd '${DOTFILES_DIR}' && make ai-mcp-validate && make ai-mcp-render && make ai-mcp-drift && make ai-mcp-generate"
	[[ "${status}" -eq 0 ]]
}
