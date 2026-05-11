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

@test "ai-cursor-check reports Excalidraw and GitHub hints when both MCPs are present in mcp.json" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.cursor"
	cat > "${fake_home}/.cursor/mcp.json" <<'JSON'
{
  "mcpServers": {
    "excalidraw": {
      "command": "/usr/bin/node",
      "args": ["/home/dummy/mcp-servers/excalidraw-mcp/dist/index.js", "--stdio"],
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
	[[ "${output}" == *"make install-mcp-excalidraw"* ]]
	[[ "${output}" == *"make install-mcp-github"* ]]
	# Should also mention the secrets file boundary without reading it.
	[[ "${output}" == *"codex.env"* ]]
}
