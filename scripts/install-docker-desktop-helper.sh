#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/update/lib/environment.sh"
# shellcheck source=scripts/update/lib/docker_desktop_credentials.sh
source "${SCRIPT_DIR}/update/lib/docker_desktop_credentials.sh"

TARGET_DIR="${DOCKER_DESKTOP_HELPER_TARGET_DIR:-$HOME/.local/bin}"

label() {
	printf '%-6s %s\n' "$1" "$2"
}

windows_path_to_wsl() {
	local path="$1"
	if [[ "$path" == /mnt/* || "$path" == /* ]]; then
		printf '%s\n' "$path"
	elif command -v wslpath >/dev/null 2>&1; then
		wslpath -u "$path" 2>/dev/null || return 1
	else
		return 1
	fi
}

candidate_sources_for_helper() {
	local command_name="$1" basename
	if [[ "$command_name" == *.exe ]]; then
		basename="$command_name"
	else
		basename="${command_name}.exe"
	fi
	if [[ -n "${DOCKER_DESKTOP_CREDENTIAL_HELPER_SOURCE:-}" ]]; then
		windows_path_to_wsl "$DOCKER_DESKTOP_CREDENTIAL_HELPER_SOURCE" || true
	fi
	if [[ -n "${DOCKER_DESKTOP_HELPER_PROGRAM_FILES_ROOT:-}" ]]; then
		printf '%s/Docker/Docker/resources/bin/%s\n' "$DOCKER_DESKTOP_HELPER_PROGRAM_FILES_ROOT" "$basename"
		printf '%s/Docker/resources/bin/%s\n' "$DOCKER_DESKTOP_HELPER_PROGRAM_FILES_ROOT" "$basename"
	else
		printf '/mnt/c/Program Files/Docker/Docker/resources/bin/%s\n' "$basename"
	fi
	if [[ -n "${DOCKER_DESKTOP_HELPER_LOCALAPPDATA_ROOT:-}" ]]; then
		printf '%s/Docker/resources/bin/%s\n' "$DOCKER_DESKTOP_HELPER_LOCALAPPDATA_ROOT" "$basename"
		printf '%s/Programs/Docker/Docker/resources/bin/%s\n' "$DOCKER_DESKTOP_HELPER_LOCALAPPDATA_ROOT" "$basename"
	else
		printf '/mnt/c/Users/%s/AppData/Local/Docker/resources/bin/%s\n' "${USER:-}" "$basename"
		printf '/mnt/c/Users/%s/AppData/Local/Programs/Docker/Docker/resources/bin/%s\n' "${USER:-}" "$basename"
	fi
}

find_source_for_helper() {
	local command_name="$1" candidate
	while IFS= read -r candidate; do
		[[ -n "$candidate" ]] || continue
		if [[ -x "$candidate" ]]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done < <(candidate_sources_for_helper "$command_name")
	return 1
}

required_helper_commands() {
	local config_file
	config_file="$(docker_credentials_config_file)"
	[[ -f "$config_file" ]] || return 0
	python3 - "$config_file" <<'PY'
import json
import sys
from pathlib import Path

try:
    data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
except Exception as exc:
    print(f"could not parse Docker config: {exc}", file=sys.stderr)
    sys.exit(2)
if not isinstance(data, dict):
    sys.exit(0)
values = []
store = data.get("credsStore")
if isinstance(store, str) and store:
    values.append(store)
helpers = data.get("credHelpers")
if isinstance(helpers, dict):
    values.extend(value for value in helpers.values() if isinstance(value, str) and value)
for value in sorted(set(values)):
    if value in {"desktop", "desktop.exe"}:
        print(f"docker-credential-{value}")
PY
}

install_helper_link() {
	local command_name="$1" source target
	source="$(find_source_for_helper "$command_name")" || {
		label FAIL "Docker Desktop helper source not found for ${command_name}"
		label INFO "Set DOCKER_DESKTOP_CREDENTIAL_HELPER_SOURCE to the Windows helper path if Docker Desktop is installed in a custom location."
		return 1
	}
	mkdir -p "$TARGET_DIR"
	target="${TARGET_DIR}/${command_name}"
	if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
		label OK "${target} already points to ${source}"
		return 0
	fi
	if [[ -e "$target" && ! -L "$target" ]]; then
		label FAIL "${target} exists and is not a symlink; refusing to replace it"
		return 1
	fi
	ln -sfn "$source" "$target"
	label OK "linked ${target} -> ${source}"
}

main() {
	if ! is_wsl; then
		label SKIP "not WSL; Docker Desktop credential helper symlink is only needed from WSL"
		return 0
	fi
	if ! command -v python3 >/dev/null 2>&1; then
		label FAIL "python3 is required to inspect Docker config JSON"
		return 1
	fi

	local config_file helpers helper failed=0
	config_file="$(docker_credentials_config_file)"
	if [[ ! -f "$config_file" ]]; then
		label SKIP "Docker config not found at ${config_file}; nothing to repair"
		return 0
	fi
	helpers="$(required_helper_commands)" || return 1
	if [[ -z "$helpers" ]]; then
		label SKIP "Docker config does not require Docker Desktop credential helpers"
		return 0
	fi

	while IFS= read -r helper; do
		[[ -n "$helper" ]] || continue
		if ! install_helper_link "$helper"; then
			failed=1
		fi
	done <<<"$helpers"

	if [[ "$failed" -eq 0 ]]; then
		label OK "Docker Desktop credential helper setup complete"
	else
		return 1
	fi
}

main "$@"
