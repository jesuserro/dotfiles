#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	setup_temp_dir
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	mkdir -p "${FAKE_BIN}"
	DOCKER_LOG="${TEST_TEMP_DIR}/docker.log"
	export DOCKER_LOG
	cat >"${FAKE_BIN}/docker" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$DOCKER_LOG"
case "$1" in
  version) exit 0 ;;
  ps)
    if [[ "$*" == *"--format"* ]]; then exit 0; fi
    exit 0
    ;;
  run|pull|stop|start) exit 0 ;;
  image) exit 1 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "${FAKE_BIN}/docker"
}

teardown() {
	teardown_temp_dir
}

@test "excalidraw update pulls upstream Docker images" {
	run env PATH="${FAKE_BIN}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" update
	[[ "${status}" -eq 0 ]]
	grep -q 'pull ghcr.io/yctimlin/mcp_excalidraw-canvas:latest' "${DOCKER_LOG}"
	grep -q 'pull ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOCKER_LOG}"
}

@test "excalidraw start uses canvas container and is idempotent-compatible" {
	run env PATH="${FAKE_BIN}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" start
	[[ "${status}" -eq 0 ]]
	grep -q 'run -d -p 3000:3000 --name mcp-excalidraw-canvas ghcr.io/yctimlin/mcp_excalidraw-canvas:latest' "${DOCKER_LOG}"
}

@test "MCP templates use ephemeral Docker, not local dist/index.js" {
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl"
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/dot_codex/config.toml.tmpl"
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl"
	! grep -R 'mcp-servers/excalidraw-mcp/dist/index.js' "${DOTFILES_DIR}/dot_cursor" "${DOTFILES_DIR}/dot_codex" "${DOTFILES_DIR}/dot_config/opencode"
}
