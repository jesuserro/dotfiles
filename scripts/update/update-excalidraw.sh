#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/update/lib/results.sh
source "${SCRIPT_DIR}/lib/results.sh"
# shellcheck source=scripts/update/lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"

ACTION="${1:-status}"
shift || true
LOG_DIR="${LOG_DIR:-${TMPDIR:-/tmp}}"
while [[ $# -gt 0 ]]; do
	case "$1" in
	--results)
		RESULTS_FILE="$2"
		shift 2
		;;
	--log-dir)
		LOG_DIR="$2"
		shift 2
		;;
	*)
		shift
		;;
	esac
done

CANVAS_IMAGE="${EXCALIDRAW_CANVAS_IMAGE:-ghcr.io/yctimlin/mcp_excalidraw-canvas:latest}"
MCP_IMAGE="${EXCALIDRAW_MCP_IMAGE:-ghcr.io/yctimlin/mcp_excalidraw:latest}"
CANVAS_NAME="${EXCALIDRAW_CANVAS_NAME:-mcp-excalidraw-canvas}"
CANVAS_PORT="${EXCALIDRAW_CANVAS_PORT:-3000}"
CANVAS_URL="${EXCALIDRAW_CANVAS_URL:-http://127.0.0.1:${CANVAS_PORT}}"

docker_cmd() {
	if [[ -n "${EXCALIDRAW_DOCKER_BIN:-}" ]]; then
		printf '%s\n' "$EXCALIDRAW_DOCKER_BIN"
	elif command -v docker >/dev/null 2>&1; then
		printf 'docker\n'
	elif command -v docker.exe >/dev/null 2>&1; then
		printf 'docker.exe\n'
	else
		return 1
	fi
}

docker_available() {
	local d
	d="$(docker_cmd)" || return 1
	"$d" version >/dev/null 2>&1
}

canvas_running() {
	local d
	d="$(docker_cmd)" || return 1
	"$d" ps --filter "name=^/${CANVAS_NAME}$" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -Fxq "$CANVAS_NAME"
}

case "$ACTION" in
start)
	d="$(docker_cmd)" || {
		echo "Docker CLI not found"
		exit 1
	}
	if canvas_running; then
		echo "Excalidraw canvas already running: ${CANVAS_URL}"
		exit 0
	fi
	if "$d" ps -a --filter "name=^/${CANVAS_NAME}$" --format '{{.Names}}' 2>/dev/null | grep -Fxq "$CANVAS_NAME"; then
		"$d" start "$CANVAS_NAME" >/dev/null
	else
		"$d" run -d -p "${CANVAS_PORT}:3000" --name "$CANVAS_NAME" "$CANVAS_IMAGE" >/dev/null
	fi
	echo "Excalidraw canvas running: ${CANVAS_URL}"
	;;
stop)
	d="$(docker_cmd)" || {
		echo "Docker CLI not found"
		exit 0
	}
	if canvas_running; then
		"$d" stop "$CANVAS_NAME" >/dev/null
		echo "Excalidraw canvas stopped"
	else
		echo "Excalidraw canvas already stopped"
	fi
	;;
status)
	if ! d="$(docker_cmd)"; then
		echo "WARN   Docker CLI not found"
		exit 0
	fi
	echo "INFO   Docker command: $d"
	if docker_available; then
		echo "OK     Docker responds"
	else
		echo "WARN   Docker does not respond; open Docker Desktop"
	fi
	if canvas_running; then
		echo "OK     Canvas running: ${CANVAS_URL}"
	else
		echo "INFO   Canvas not running. Start with: make excalidraw-start"
	fi
	;;
update)
	if ! d="$(docker_cmd)"; then
		msg="Docker CLI not found; Excalidraw images not updated"
		warn "$msg"
		[[ -n "${RESULTS_FILE:-}" ]] && result_warn "WSL" "Excalidraw Docker" "$msg"
		exit 0
	fi
	if ! docker_available; then
		msg="Docker unavailable; open Docker Desktop to update Excalidraw images"
		warn "$msg"
		[[ -n "${RESULTS_FILE:-}" ]] && result_warn "WSL" "Excalidraw Docker" "$msg"
		exit 0
	fi
	mkdir -p "$LOG_DIR"
	run_step "WSL" "Excalidraw canvas image" "${LOG_DIR}/excalidraw-canvas-pull.log" "$d" pull "$CANVAS_IMAGE"
	run_step "WSL" "Excalidraw MCP image" "${LOG_DIR}/excalidraw-mcp-pull.log" "$d" pull "$MCP_IMAGE"
	;;
*)
	echo "Usage: $0 {start|stop|status|update}" >&2
	exit 2
	;;
esac
