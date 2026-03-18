#!/usr/bin/env bash
# Materializes generated command artifacts into runtime destinations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
BUILD_DIR="${DOTFILES_DIR}/build/commands"
REGISTRY_FILE="${DOTFILES_DIR}/ai/assets/commands/registry.yaml"
HOME_ROOT="${COMMANDS_HOME_ROOT:-${HOME}}"
MANAGED_MARKER="managed-by: dotfiles-global-commands"

log_info()  { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Materializes build/commands/* into runtime command directories.

OPTIONS:
    -h, --help         Show this help message
    --skip-generate    Reuse existing build/commands without regenerating

ENVIRONMENT:
    COMMANDS_HOME_ROOT Override the runtime root for tests/debug.
                       Default: \$HOME

RUNTIME DESTINATIONS:
    ${HOME_ROOT}/.config/opencode/commands
    ${HOME_ROOT}/.cursor/commands
    ${HOME_ROOT}/.codex/prompts
EOF
}

main() {
    local skip_generate=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --skip-generate)
                skip_generate=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ "${skip_generate}" != "true" ]]; then
        log_info "Generating build artifacts"
        "${SCRIPT_DIR}/generate-commands.sh"
    fi

    if [[ ! -d "${BUILD_DIR}" ]]; then
        log_error "Build directory not found: ${BUILD_DIR}"
        exit 1
    fi

    log_info "Materializing commands into ${HOME_ROOT}"

    python3 - "${REGISTRY_FILE}" "${BUILD_DIR}" "${HOME_ROOT}" "${MANAGED_MARKER}" <<'PYEOF'
import os
import shutil
import sys
import yaml

registry_file, build_dir, home_root, managed_marker = sys.argv[1:5]

platforms = {
    "opencode": {
        "build_subdir": "opencode",
        "dest_dir": os.path.join(home_root, ".config", "opencode", "commands"),
    },
    "cursor": {
        "build_subdir": "cursor",
        "dest_dir": os.path.join(home_root, ".cursor", "commands"),
    },
    "codex": {
        "build_subdir": "codex",
        "dest_dir": os.path.join(home_root, ".codex", "prompts"),
    },
}

with open(registry_file, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

expected = {platform: set() for platform in platforms}

for command in data.get("commands", []):
    cmd_id = command.get("id", "")
    if not cmd_id or not command.get("enabled", False):
        continue
    for platform in command.get("platforms", []):
        if platform in expected:
            expected[platform].add(f"{cmd_id}.md")

for platform, config in platforms.items():
    build_platform_dir = os.path.join(build_dir, config["build_subdir"])
    dest_dir = config["dest_dir"]
    os.makedirs(dest_dir, exist_ok=True)

    expected_files = expected[platform]
    for filename in sorted(expected_files):
        source = os.path.join(build_platform_dir, filename)
        if not os.path.exists(source):
            print(f"[ERROR] Missing build artifact for {platform}: {source}", file=sys.stderr)
            sys.exit(1)
        destination = os.path.join(dest_dir, filename)
        shutil.copyfile(source, destination)
        print(f"[INFO] Materialized {platform}: {destination}")

    for filename in sorted(os.listdir(dest_dir)):
        if not filename.endswith(".md"):
            continue
        destination = os.path.join(dest_dir, filename)
        if not os.path.isfile(destination):
            continue
        if filename in expected_files:
            continue
        try:
            with open(destination, "r", encoding="utf-8") as handle:
                content = handle.read(4096)
        except OSError:
            continue
        if managed_marker in content:
            os.remove(destination)
            print(f"[INFO] Removed obsolete managed artifact: {destination}")
PYEOF

    log_info "Materialization complete"
}

main "$@"
