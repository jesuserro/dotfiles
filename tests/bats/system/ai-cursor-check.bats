#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	AI_CURSOR_CHECK="${DOTFILES_DIR}/scripts/ai-cursor-check.sh"
}

@test "ai-cursor-check.sh exists and passes bash -n" {
	[[ -f "${AI_CURSOR_CHECK}" ]]
	run bash -n "${AI_CURSOR_CHECK}"
	[[ "${status}" -eq 0 ]]
}

@test "Makefile defines ai-cursor-check target" {
	[[ -f "${DOTFILES_DIR}/install.mk" ]]
	run grep -q '^ai-cursor-check:' "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
}

@test "make -n ai-cursor-check references the check script" {
	run make -C "${DOTFILES_DIR}" -n ai-cursor-check
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"ai-cursor-check.sh"* ]]
}

@test "ai-cursor-check with empty HOME reports missing Cursor mcp.json (non-strict, exit 0)" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}"
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"mcp.json"* ]] || [[ "${output}" == *"missing"* ]] || [[ "${output}" == *"MISSING"* ]]
}

@test "ai-cursor-check STRICT=1 fails when HOME has no Cursor mcp.json" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}"
	run env HOME="${fake_home}" STRICT=1 bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"FAIL"* ]] || [[ "${output}" == *"STRICT"* ]]
}

@test "ai-cursor-check Node warning includes actionable hint" {
	local fake_home stub_path
	fake_home="$(mktemp -d)"
	stub_path="$(mktemp -d)"
	mkdir -p "${fake_home}"
	# Stub PATH that exposes the external utilities ai-cursor-check actually
	# calls (find/stat/grep/sed/awk/dirname/readlink/wc/tr/head/tail/sort/
	# basename/cat/ls/python3) but NOT node/npx, so the WARN branch is taken
	# even when the host has node in /usr/bin. We do not assert exit 0 here
	# because the test only cares that the WARN message is actionable.
	for c in python3 find stat grep sed awk dirname readlink wc tr head tail sort basename cat ls; do
		if command -v "$c" >/dev/null 2>&1; then
			ln -s "$(command -v "$c")" "${stub_path}/$c"
		fi
	done
	local bash_abs
	bash_abs="$(command -v bash)"
	run env HOME="${fake_home}" PATH="${stub_path}" "${bash_abs}" "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}" "${stub_path}"
	[[ "${output}" == *"make install-node-stack"* ]]
}

@test "ai-cursor-check reports Docker Excalidraw and GitHub hints when both MCPs are present in mcp.json" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	mkdir -p /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{
  "mcpServers": {
    "excalidraw_canvas": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "EXPRESS_SERVER_URL=http://host.docker.internal:3210", "-e", "ENABLE_CANVAS_SYNC=true", "-e", "EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw", "-v", "/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw", "ghcr.io/yctimlin/mcp_excalidraw:latest"],
      "env": {}
    },
    "github": {
      "command": "/usr/bin/bash",
      "args": ["-lc", "source ~/.secrets/codex.env 2>/dev/null; exec /home/dummy/.local/bin/codex-mcp-github"],
      "env": {}
    }
  }
}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Cursor HOME Excalidraw MCP 'excalidraw_canvas' uses Docker runtime with scoped workspace mount"* ]]
	[[ "${output}" == *"Excalidraw workspace host path present"* ]]
	[[ "${output}" == *"make install-mcp-github"* ]]
	# Should also mention the secrets file boundary without reading it.
	[[ "${output}" == *"codex.env"* ]]
}

@test "ai-cursor-check validates Excalidraw Docker runtime in Cursor Codex and OpenCode HOME" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor" "${fake_home}/.codex" "${fake_home}/.config/opencode"
	mkdir -p /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw_canvas":{"command":"docker","args":["run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3210","-e","ENABLE_CANVAS_SYNC=true","-e","EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw","-v","/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw","ghcr.io/yctimlin/mcp_excalidraw:latest"],"env":{}}}}
JSON
	cat >"${fake_home}/.codex/config.toml" <<'TOML'
[mcp_servers.excalidraw_canvas]
command = "docker"
args = ["run", "-i", "--rm", "-e", "EXPRESS_SERVER_URL=http://host.docker.internal:3210", "-e", "ENABLE_CANVAS_SYNC=true", "-e", "EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw", "-v", "/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw", "ghcr.io/yctimlin/mcp_excalidraw:latest"]
enabled = true
TOML
	cat >"${fake_home}/.config/opencode/opencode.json" <<'JSON'
{"mcp":{"excalidraw_canvas":{"type":"local","command":["docker","run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3210","-e","ENABLE_CANVAS_SYNC=true","-e","EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw","-v","/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw","ghcr.io/yctimlin/mcp_excalidraw:latest"],"enabled":true}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Cursor HOME Excalidraw MCP 'excalidraw_canvas' uses Docker runtime with scoped workspace mount"* ]]
	[[ "${output}" == *"Codex HOME Excalidraw MCP 'excalidraw_canvas' uses Docker runtime with scoped workspace mount"* ]]
	[[ "${output}" == *"OpenCode HOME Excalidraw MCP 'excalidraw_canvas' uses Docker runtime with scoped workspace mount"* ]]
}

@test "ai-cursor-check treats valid Docker bind mount as host path only" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	mkdir -p /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw_canvas":{"command":"docker","args":["run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3210","-e","ENABLE_CANVAS_SYNC=true","-e","EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw","-v","/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw","ghcr.io/yctimlin/mcp_excalidraw:latest"],"env":{}}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MCP path exists: /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw"* ]]
	[[ "${output}" != *"MCP path not found (WSL/host path?): /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw"* ]]
	[[ "${output}" != *"MCP path missing on disk: /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw:/workspace/excalidraw"* ]]
}

@test "ai-cursor-check warns on missing Docker bind mount host path only" {
	local fake_home missing_host
	fake_home="$(mktemp -d)"
	missing_host="/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw-missing-for-test"
	mkdir -p "${fake_home}/.cursor"
	rm -rf "${missing_host}"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"probe":{"command":"docker","args":["run","--rm","-v","/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw-missing-for-test:/workspace/probe","alpine:3.20"],"env":{}}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MCP path not found (WSL/host path?): /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw-missing-for-test"* ]]
	[[ "${output}" != *"MCP path not found (WSL/host path?): /mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw-missing-for-test:/workspace/probe"* ]]
}

@test "ai-cursor-check flags legacy Excalidraw canvas port 3000" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw_canvas":{"command":"docker","args":["run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3000","-e","ENABLE_CANVAS_SYNC=true","ghcr.io/yctimlin/mcp_excalidraw:latest"],"env":{}}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"legacy canvas port 3000"* ]]
	[[ "${output}" == *"expected host port 3210"* ]]
}

@test "ai-cursor-check flags missing Excalidraw workspace env and mount" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw_canvas":{"command":"docker","args":["run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3210","-e","ENABLE_CANVAS_SYNC=true","ghcr.io/yctimlin/mcp_excalidraw:latest"],"env":{}}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"missing the scoped workspace bind mount"* ]]
}

@test "ai-cursor-check flags excessive vault mount for Excalidraw" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw_canvas":{"command":"docker","args":["run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3210","-e","ENABLE_CANVAS_SYNC=true","-e","EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw","-v","/mnt/c/Users/jesus/Documents/vault_trabajo:/workspace/excalidraw","ghcr.io/yctimlin/mcp_excalidraw:latest"],"env":{}}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"mounts more than the scoped excalidraw workspace"* ]]
}

@test "ai-cursor-check flags ambiguous legacy Excalidraw MCP name" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw":{"command":"docker","args":["run","-i","--rm","-e","EXPRESS_SERVER_URL=http://host.docker.internal:3210","-e","ENABLE_CANVAS_SYNC=true","ghcr.io/yctimlin/mcp_excalidraw:latest"],"env":{}}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"ambiguous legacy name 'excalidraw'"* ]]
	[[ "${output}" == *"expected 'excalidraw_canvas'"* ]]
}

@test "ai-cursor-check flags legacy Excalidraw local checkout in effective HOME configs" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor" "${fake_home}/.codex" "${fake_home}/.config/opencode"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{"mcpServers":{"excalidraw_canvas":{"command":"node","args":["/home/test/mcp-servers/excalidraw-mcp/dist/index.js"],"env":{}}}}
JSON
	cat >"${fake_home}/.codex/config.toml" <<'TOML'
[mcp_servers.excalidraw_canvas]
command = "node"
args = ["/home/test/mcp-servers/excalidraw-mcp/dist/index.js"]
enabled = true
TOML
	cat >"${fake_home}/.config/opencode/opencode.json" <<'JSON'
{"mcp":{"excalidraw_canvas":{"type":"local","command":["node","/home/test/mcp-servers/excalidraw-mcp/dist/index.js"],"enabled":true}}}
JSON
	run env HOME="${fake_home}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Cursor HOME uses legacy Excalidraw local checkout"* ]]
	[[ "${output}" == *"Codex HOME uses legacy Excalidraw local checkout"* ]]
	[[ "${output}" == *"OpenCode HOME uses legacy Excalidraw local checkout"* ]]
}

@test "ai-cursor-check validates Docker MCP through docker.exe stub" {
	local fake_home stub_path
	fake_home="$(mktemp -d)"
	stub_path="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	cat >"${fake_home}/.cursor/mcp.json" <<'JSON'
{
  "mcpServers": {
    "docker": {
      "command": "docker.exe",
      "args": ["mcp", "gateway", "run"],
      "env": {}
    }
  }
}
JSON
	cat >"${stub_path}/docker.exe" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == "mcp version" ]]; then
	echo "v0.42.0"
	exit 0
fi
if [[ "$*" == "mcp profile ls" ]]; then
	echo "No profiles"
	exit 0
fi
exit 1
SH
	chmod +x "${stub_path}/docker.exe"
	run env HOME="${fake_home}" PATH="${stub_path}:${PATH}" bash "${AI_CURSOR_CHECK}"
	rm -rf "${fake_home}" "${stub_path}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Docker MCP Toolkit responds via docker.exe"* ]]
	[[ "${output}" == *"Docker MCP Gateway available via docker.exe; no Docker MCP profile/server enabled yet"* ]]
}
