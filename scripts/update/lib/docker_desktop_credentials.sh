#!/usr/bin/env bash
# Docker credential helper checks for WSL + Docker Desktop.
# shellcheck shell=bash
# shellcheck disable=SC2034

DOCKER_CREDENTIALS_LAST_MESSAGE=""
DOCKER_CREDENTIALS_LAST_HELPERS=""

docker_credentials_config_file() {
	printf '%s/config.json\n' "${DOCKER_CONFIG:-$HOME/.docker}"
}

docker_credentials_helper_command() {
	local helper="$1"
	printf 'docker-credential-%s\n' "$helper"
}

docker_credentials_required_helpers_for_images() {
	local config_file="$1"
	shift
	[[ -f "$config_file" ]] || return 0
	python3 - "$config_file" "$@" <<'PY'
import json
import sys
from pathlib import Path


def registry_for_image(ref: str) -> str:
    first = ref.split("/", 1)[0]
    if "/" not in ref or ("." not in first and ":" not in first and first != "localhost"):
        return "docker.io"
    return first


def helper_for_registry(config: dict, registry: str):
    helpers = config.get("credHelpers")
    if not isinstance(helpers, dict):
        helpers = {}
    candidates = [registry]
    if registry == "docker.io":
        candidates.extend(["index.docker.io", "https://index.docker.io/v1/"])
    for key in candidates:
        value = helpers.get(key)
        if isinstance(value, str) and value:
            return value, f"credHelpers[{key}]"
    value = config.get("credsStore")
    if isinstance(value, str) and value:
        return value, "credsStore"
    return None, None


config_path = Path(sys.argv[1])
try:
    config = json.loads(config_path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"PARSE_ERROR\t{exc}", file=sys.stderr)
    sys.exit(2)
if not isinstance(config, dict):
    sys.exit(0)

seen = set()
for image in sys.argv[2:]:
    registry = registry_for_image(image)
    helper, source = helper_for_registry(config, registry)
    if not helper:
        continue
    command = f"docker-credential-{helper}"
    key = (command, registry, source)
    if key in seen:
        continue
    seen.add(key)
    print(f"{command}\t{registry}\t{source}\t{image}")
PY
}

check_docker_credentials_for_images() {
	DOCKER_CREDENTIALS_LAST_MESSAGE=""
	DOCKER_CREDENTIALS_LAST_HELPERS=""
	if ! is_wsl; then
		DOCKER_CREDENTIALS_LAST_MESSAGE="not WSL; Docker credential helper check skipped"
		return 0
	fi
	if [[ $# -eq 0 ]]; then
		DOCKER_CREDENTIALS_LAST_MESSAGE="no Docker images provided for credential helper check"
		return 0
	fi
	if ! command -v python3 >/dev/null 2>&1; then
		DOCKER_CREDENTIALS_LAST_MESSAGE="python3 not found; cannot parse Docker credential config"
		return 1
	fi

	local config_file required rc err_file missing=() command registry source image
	config_file="$(docker_credentials_config_file)"
	if [[ ! -f "$config_file" ]]; then
		DOCKER_CREDENTIALS_LAST_MESSAGE="Docker config not found at ${config_file}; credential helper check skipped"
		return 0
	fi

	err_file="$(mktemp "${TMPDIR:-/tmp}/dotfiles-docker-credentials.XXXXXX")"
	set +e
	required="$(docker_credentials_required_helpers_for_images "$config_file" "$@" 2>"$err_file")"
	rc=$?
	set -e
	if [[ "$rc" -ne 0 ]]; then
		local err
		err="$(<"$err_file")"
		rm -f "$err_file"
		err="${err#PARSE_ERROR$'\t'}"
		DOCKER_CREDENTIALS_LAST_MESSAGE="could not parse Docker config ${config_file}: ${err}"
		return 1
	fi
	rm -f "$err_file"

	if [[ -z "$required" ]]; then
		DOCKER_CREDENTIALS_LAST_MESSAGE="Docker config has no credential helper requirement for requested images"
		return 0
	fi

	DOCKER_CREDENTIALS_LAST_HELPERS="$required"
	while IFS=$'\t' read -r command registry source image; do
		[[ -n "$command" ]] || continue
		if ! command -v "$command" >/dev/null 2>&1; then
			missing+=("${command} (${source} for ${registry}, image ${image})")
		fi
	done <<<"$required"

	if [[ "${#missing[@]}" -eq 0 ]]; then
		DOCKER_CREDENTIALS_LAST_MESSAGE="Docker credential helpers available for requested images"
		return 0
	fi

	local joined
	joined="$(printf '%s; ' "${missing[@]}")"
	joined="${joined%; }"
	DOCKER_CREDENTIALS_LAST_MESSAGE="Docker credential helper unavailable from PATH: ${joined}. Run: make install-docker-desktop-helper"
	return 1
}
