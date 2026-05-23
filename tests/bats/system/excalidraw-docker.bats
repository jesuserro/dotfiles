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
	  port) exit 0 ;;
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
	! grep -q 'run -d' "${DOCKER_LOG}"
}

@test "excalidraw start uses canvas container and is idempotent-compatible" {
	run env PATH="${FAKE_BIN}:/usr/bin:/bin" EXCALIDRAW_SKIP_PORT_CHECK=1 bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" start
	[[ "${status}" -eq 0 ]]
	grep -q 'run -d -p 3210:3000 --name mcp-excalidraw-canvas ghcr.io/yctimlin/mcp_excalidraw-canvas:latest' "${DOCKER_LOG}"
	[[ "${output}" == *"http://127.0.0.1:3210"* ]]
}

@test "excalidraw status reports dedicated canvas port" {
	run env PATH="${FAKE_BIN}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" status
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"http://127.0.0.1:3210"* ]]
}

@test "excalidraw start fails when dedicated port is occupied" {
	local occupied_bin="${TEST_TEMP_DIR}/occupied-bin"
	mkdir -p "$occupied_bin"
	cat >"${occupied_bin}/docker" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$DOCKER_LOG"
case "$1" in
  ps|version|port) exit 0 ;;
  run) exit 0 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "${occupied_bin}/docker"
	python3 - <<'PY' &
import socket, time
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 3210))
s.listen(1)
time.sleep(6)
PY
	local listener_pid=$!
	sleep 1
	run env PATH="${occupied_bin}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" start
	kill "${listener_pid}" 2>/dev/null || true
	wait "${listener_pid}" 2>/dev/null || true
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Port 3210 is already in use"* ]]
	run grep -q 'run -d' "${DOCKER_LOG}"
	[[ "${status}" -ne 0 ]]
}

@test "excalidraw start rejects stale canvas container with legacy port mapping" {
	local stale_bin="${TEST_TEMP_DIR}/stale-bin"
	mkdir -p "$stale_bin"
	cat >"${stale_bin}/docker" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$DOCKER_LOG"
case "$1" in
  version) exit 0 ;;
  ps)
    if [[ "$*" == *"--format"* ]]; then echo "mcp-excalidraw-canvas"; fi
    exit 0
    ;;
  port) echo "0.0.0.0:3000"; exit 0 ;;
  start|run) exit 0 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "${stale_bin}/docker"
	run env PATH="${stale_bin}:/usr/bin:/bin" EXCALIDRAW_SKIP_PORT_CHECK=1 bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" start
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"unexpected port mapping"* ]]
	[[ "${output}" == *"Expected host port 3210"* ]]
	run grep -q 'run -d' "${DOCKER_LOG}"
	[[ "${status}" -ne 0 ]]
}

@test "excalidraw status warns on stale canvas container with legacy port mapping" {
	local stale_bin="${TEST_TEMP_DIR}/stale-status-bin"
	mkdir -p "$stale_bin"
	cat >"${stale_bin}/docker" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  version) exit 0 ;;
  ps)
    if [[ "$*" == *"--format"* ]]; then echo "mcp-excalidraw-canvas"; fi
    exit 0
    ;;
  port) echo "0.0.0.0:3000"; exit 0 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "${stale_bin}/docker"
	run env PATH="${stale_bin}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" status
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"unexpected port mapping"* ]]
	[[ "${output}" == *"3210:3000"* ]]
}

@test "MCP templates use ephemeral Docker, not local dist/index.js" {
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl"
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/dot_codex/config.toml.tmpl"
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl"
	grep -q 'EXPRESS_SERVER_URL=http://host.docker.internal:3210' "${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl"
	grep -q 'EXPRESS_SERVER_URL=http://host.docker.internal:3210' "${DOTFILES_DIR}/dot_codex/config.toml.tmpl"
	grep -q 'EXPRESS_SERVER_URL=http://host.docker.internal:3210' "${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl"
	run grep -R 'mcp-servers/excalidraw-mcp/dist/index.js' "${DOTFILES_DIR}/dot_cursor" "${DOTFILES_DIR}/dot_codex" "${DOTFILES_DIR}/dot_config/opencode"
	[[ "${status}" -ne 0 ]]
	run grep -R 'EXPRESS_SERVER_URL=http://host.docker.internal:3000' "${DOTFILES_DIR}/dot_cursor" "${DOTFILES_DIR}/dot_codex" "${DOTFILES_DIR}/dot_config/opencode"
	[[ "${status}" -ne 0 ]]
}

@test "excalidraw status tolerates missing Docker without fatal error" {
	local empty_path="${TEST_TEMP_DIR}/empty-path"
	mkdir -p "$empty_path"
	ln -s "$(command -v dirname)" "${empty_path}/dirname"
	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$empty_path" "$bash_abs" "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" status
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Docker CLI not found"* ]]
}

@test "excalidraw stop is tolerant when canvas is already stopped" {
	run env PATH="${FAKE_BIN}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh" stop
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"already stopped"* ]]
}

@test "update-wsl MCP section updates Excalidraw images without starting canvas" {
	run env PATH="${FAKE_BIN}:/usr/bin:/bin" DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-mcp" bash "${DOTFILES_DIR}/scripts/update/update-wsl.sh" --section mcp
	[[ "${status}" -eq 0 ]]
	grep -q 'pull ghcr.io/yctimlin/mcp_excalidraw-canvas:latest' "${DOCKER_LOG}"
	grep -q 'pull ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOCKER_LOG}"
	! grep -q 'run -d' "${DOCKER_LOG}"
}

@test "Excalidraw manifest uses Docker image and no local checkout" {
	grep -q 'ghcr.io/yctimlin/mcp_excalidraw:latest' "${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml"
	grep -q 'EXPRESS_SERVER_URL=http://host.docker.internal:3210' "${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml"
	grep -q '3210:3000' "${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml"
	run grep -q 'mcp-servers/excalidraw-mcp/dist/index.js' "${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml"
	[[ "${status}" -ne 0 ]]
}

@test "Excalidraw active configuration does not use legacy host port 3000" {
	run grep -R 'EXPRESS_SERVER_URL=http://host.docker.internal:3000' \
		"${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml" \
		"${DOTFILES_DIR}/scripts/generate-mcp-configs.py" \
		"${DOTFILES_DIR}/dot_cursor" \
		"${DOTFILES_DIR}/dot_codex" \
		"${DOTFILES_DIR}/dot_config/opencode"
	[[ "${status}" -ne 0 ]]
}

@test "Excalidraw skills keep Docker, editable source, export, and safety rules" {
	local diagram_skill="${DOTFILES_DIR}/ai/assets/skills/diagrams/excalidraw/SKILL.md"
	local ops_skill="${DOTFILES_DIR}/ai/assets/skills/ops/excalidraw-mcp-operations/SKILL.md"
	local publish_skill="${DOTFILES_DIR}/ai/assets/skills/docs/excalidraw-publishing/SKILL.md"
	grep -q 'make excalidraw-start' "$ops_skill"
	grep -q 'Docker' "$ops_skill"
	grep -qi 'do not clone' "$ops_skill"
	grep -q '.excalidraw' "$diagram_skill"
	grep -q 'import' "$diagram_skill"
	grep -Eq 'backup|snapshot|copy' "$diagram_skill"
	grep -q 'SVG' "$publish_skill"
	grep -q '.excalidraw' "$publish_skill"
}
