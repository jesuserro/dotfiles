#!/usr/bin/env bash
# Generates command artifacts from canonical source into build/commands/.
#
# Architecture (4 layers):
#   1. Canonical: ai/assets/commands/<id>/COMMAND.md
#   2. Adapter:   ai/adapters/<platform>/TEMPLATE.md
#   3. Build:     build/commands/<platform>/<id>.md
#   4. Runtime:   ~/.config/... materialized separately

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"
ADAPTERS_DIR="${DOTFILES_DIR}/ai/adapters"
BUILD_DIR="${DOTFILES_DIR}/build/commands"
MANAGED_MARKER="managed-by: dotfiles-global-commands"

log_info()  { echo "[INFO] $*"; }
log_warn()  { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

check_dependencies() {
    if ! python3 -c "import yaml" 2>/dev/null; then
        log_error "Python yaml module is required but not installed."
        exit 1
    fi
}

list_commands() {
    log_info "Available commands in registry:"
    echo ""

    python3 - "${REGISTRY_FILE}" <<'PYEOF'
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

for cmd in data.get("commands", []):
    cmd_id = cmd.get("id", "")
    platforms = ", ".join(cmd.get("platforms", []))
    enabled = "enabled" if cmd.get("enabled") else "disabled"
    print(f"  - {cmd_id} [{platforms}] ({enabled})")
PYEOF
    echo ""
}

generate_commands() {
    local target_command="${1:-}"
    local clean_build="${2:-false}"

    python3 - "${REGISTRY_FILE}" "${COMMANDS_DIR}" "${BUILD_DIR}" "${target_command}" "${clean_build}" "${MANAGED_MARKER}" <<'PYEOF'
import os
import shutil
import sys
import yaml

registry_file, commands_dir, build_dir, target_command, clean_build, managed_marker = sys.argv[1:7]

platforms = {
    "opencode": {"subdir": "opencode"},
    "cursor": {"subdir": "cursor"},
    "codex": {"subdir": "codex"},
}

with open(registry_file, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

commands = data.get("commands", [])
command_map = {cmd.get("id"): cmd for cmd in commands if cmd.get("id")}

if target_command:
    if target_command not in command_map:
        print(f"[ERROR] Command not found: {target_command}", file=sys.stderr)
        sys.exit(1)
    commands = [command_map[target_command]]

if clean_build.lower() == "true":
    shutil.rmtree(build_dir, ignore_errors=True)

generated = 0

for cmd in commands:
    cmd_id = cmd.get("id", "")
    if not cmd.get("enabled", False):
        print(f"[INFO] Skipping disabled command: {cmd_id}")
        continue

    source = cmd.get("source", "")
    if not source:
        print(f"[ERROR] No source defined for command: {cmd_id}", file=sys.stderr)
        sys.exit(1)

    source_file = os.path.join(commands_dir, source)
    if not os.path.exists(source_file):
        print(f"[ERROR] Source file not found: {source_file}", file=sys.stderr)
        sys.exit(1)

    with open(source_file, "r", encoding="utf-8") as handle:
        content = handle.read().rstrip() + "\n"

    description = cmd.get("description", "")

    for platform in cmd.get("platforms", []):
        if platform not in platforms:
            print(f"[WARN] Unknown platform '{platform}' for command: {cmd_id}")
            continue

        dest_dir = os.path.join(build_dir, platforms[platform]["subdir"])
        os.makedirs(dest_dir, exist_ok=True)
        dest_file = os.path.join(dest_dir, f"{cmd_id}.md")

        if platform in {"opencode", "codex"}:
            rendered = (
                "---\n"
                f"description: {description}\n"
                "---\n\n"
                f"<!-- {managed_marker} -->\n\n"
                f"{content}"
            )
        elif platform == "cursor":
            rendered = (
                f"<!-- {managed_marker} -->\n\n"
                "# Cursor Commands\n\n"
                f"{content}"
            )
        else:
            continue

        with open(dest_file, "w", encoding="utf-8") as handle:
            handle.write(rendered)

        print(f"[INFO] Generated {platform}: {dest_file}")
        generated += 1

if target_command and generated == 0:
    print(f"[WARN] No artifacts generated for command: {target_command}")
PYEOF
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generates command artifacts from canonical source into build/commands/.

OPTIONS:
    -h, --help        Show this help message
    -c, --command ID  Generate only this command
    -l, --list        List all commands in registry
    -v, --validate    Validate registry before generating

ARCHITECTURE:
    Layer 1: ai/assets/commands/<id>/COMMAND.md
    Layer 2: ai/adapters/<platform>/TEMPLATE.md
    Layer 3: build/commands/<platform>/<id>.md
    Layer 4: runtime materialization via materialize-commands.sh

BUILD OUTPUT:
    opencode  -> build/commands/opencode/<id>.md
    cursor    -> build/commands/cursor/<id>.md
    codex     -> build/commands/codex/<id>.md

RUNTIME DESTINATIONS:
    opencode  -> ~/.config/opencode/commands/<id>.md
    cursor    -> ~/.cursor/commands/<id>.md
    codex     -> ~/.codex/prompts/<id>.md

EXAMPLES:
    $(basename "$0")
    $(basename "$0") --list
    $(basename "$0") -c sos
    $(basename "$0") --validate

SOURCE: ${COMMANDS_DIR}
ADAPTERS: ${ADAPTERS_DIR}
BUILD: ${BUILD_DIR}
EOF
}

main() {
    local target_command=""
    local do_validate=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--command)
                if [[ $# -lt 2 ]]; then
                    log_error "Missing value for $1"
                    exit 1
                fi
                target_command="$2"
                shift 2
                ;;
            -l|--list)
                check_dependencies
                list_commands
                exit 0
                ;;
            -v|--validate)
                do_validate=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    check_dependencies

    if [[ ! -f "${REGISTRY_FILE}" ]]; then
        log_error "Registry not found: ${REGISTRY_FILE}"
        exit 1
    fi

    if [[ "${do_validate}" == "true" ]]; then
        log_info "Running validation..."
        if ! "${SCRIPT_DIR}/validate-commands-structure.sh" >/dev/null; then
            log_error "Validation failed. Fix errors before generating."
            exit 1
        fi
        log_info "Validation passed."
    fi

    log_info "Generating commands into ${BUILD_DIR}"
    echo ""

    if [[ -n "${target_command}" ]]; then
        generate_commands "${target_command}" false
    else
        generate_commands "" true
    fi

    echo ""
    log_info "Generation complete."
    log_info "To materialize into runtime destinations, run: ./scripts/materialize-commands.sh"
}

main "$@"
