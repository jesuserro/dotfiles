#!/usr/bin/env bash
# Generates command artifacts from canonical source to platform surfaces.
# Source of truth: ai/assets/commands/
# Target surfaces:
#   - OpenCode:  dot_config/opencode/commands/<id>.md
#   - Cursor:    dot_config/cursor/commands/<id>.md
#   - Codex:     dot_config/codex/prompts/<id>.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"

OPENCODE_COMMANDS="${DOTFILES_DIR}/dot_config/opencode/commands"
CURSOR_COMMANDS="${DOTFILES_DIR}/dot_config/cursor/commands"
CODEX_PROMPTS="${DOTFILES_DIR}/dot_config/codex/prompts"

VALID_PLATFORMS=("opencode" "cursor" "codex")

log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

check_dependencies() {
    if ! python3 -c "import yaml" 2>/dev/null; then
        log_error "Python yaml module is required but not installed."
        exit 1
    fi
}

list_commands() {
    log_info "Available commands in registry:"
    echo ""

    python3 - "${REGISTRY_FILE}" 2>/dev/null << 'PYEOF'
import sys
import yaml

registry = sys.argv[1] if len(sys.argv) > 1 else ''
if not registry:
    sys.exit(1)

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    platforms = ', '.join(cmd.get('platforms', []))
    enabled = 'enabled' if cmd.get('enabled') else 'disabled'
    print(f"  - {cmd_id} [{platforms}] ({enabled})")
PYEOF
    echo ""
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generates command artifacts from canonical source to platform surfaces.

OPTIONS:
    -h, --help        Show this help message
    -c, --command     Generate only this command (by ID)
    -l, --list       List all commands in registry
    -v, --validate    Validate registry before generating

PLATFORMS:
    opencode  -> ~/.config/opencode/commands/<id>.md
    cursor    -> ~/.cursor/commands/<id>.md
    codex     -> ~/.codex/prompts/<id>.md

EXAMPLES:
    $(basename "$0")                  # Generate all commands
    $(basename "$0") --list           # List available commands
    $(basename "$0") -c sos           # Generate only 'sos' command
    $(basename "$0") --validate       # Validate and generate

SOURCE: ${COMMANDS_DIR}

EOF
}

generate_single() {
    local cmd_id="$1"

    python3 - "${REGISTRY_FILE}" "${cmd_id}" "${COMMANDS_DIR}" "${DOTFILES_DIR}" << 'PYEOF'
import sys
import yaml
import os

registry = sys.argv[1]
cmd_id = sys.argv[2]
commands_dir = sys.argv[3]
dotfiles_dir = sys.argv[4]

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    if cmd.get('id') == cmd_id:
        if not cmd.get('enabled', False):
            print(f"[INFO] Skipping disabled command: {cmd_id}")
            sys.exit(0)

        source = cmd.get('source', '')
        if not source:
            print(f"[ERROR] No source defined for command: {cmd_id}", file=sys.stderr)
            sys.exit(1)

        source_file = os.path.join(commands_dir, source)
        if not os.path.exists(source_file):
            print(f"[ERROR] Source file not found: {source_file}", file=sys.stderr)
            sys.exit(1)

        with open(source_file, 'r') as f:
            content = f.read()

        description = cmd.get('description', '')
        platforms = cmd.get('platforms', [])

        for platform in platforms:
            if platform == 'opencode':
                dest_dir = os.path.join(dotfiles_dir, 'dot_config', 'opencode', 'commands')
                os.makedirs(dest_dir, exist_ok=True)
                dest_file = os.path.join(dest_dir, f"{cmd_id}.md")
                frontmatter = f"""---
description: {description}
---

"""
                with open(dest_file, 'w') as dst:
                    dst.write(frontmatter)
                    dst.write(content)
                print(f"[INFO] Generated OpenCode: {dest_file}")

            elif platform == 'cursor':
                dest_dir = os.path.join(dotfiles_dir, 'dot_config', 'cursor', 'commands')
                os.makedirs(dest_dir, exist_ok=True)
                dest_file = os.path.join(dest_dir, f"{cmd_id}.md")
                header = "# Cursor Commands\n\n"
                with open(dest_file, 'w') as dst:
                    dst.write(header)
                    dst.write(content)
                print(f"[INFO] Generated Cursor: {dest_file}")

            elif platform == 'codex':
                dest_dir = os.path.join(dotfiles_dir, 'dot_config', 'codex', 'prompts')
                os.makedirs(dest_dir, exist_ok=True)
                dest_file = os.path.join(dest_dir, f"{cmd_id}.md")
                frontmatter = f"""---
description: {description}
---

"""
                with open(dest_file, 'w') as dst:
                    dst.write(frontmatter)
                    dst.write(content)
                print(f"[INFO] Generated Codex: {dest_file}")

            else:
                print(f"[WARN] Unknown platform '{platform}' for command: {cmd_id}")

        sys.exit(0)

print(f"[ERROR] Command not found: {cmd_id}", file=sys.stderr)
sys.exit(1)
PYEOF
}

generate_all() {
    python3 - "${REGISTRY_FILE}" "${COMMANDS_DIR}" "${DOTFILES_DIR}" << 'PYEOF'
import sys
import yaml
import os

registry = sys.argv[1]
commands_dir = sys.argv[2]
dotfiles_dir = sys.argv[3]

if not registry:
    sys.exit(1)

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')

    if not cmd.get('enabled', False):
        print(f"[INFO] Skipping disabled command: {cmd_id}")
        continue

    source = cmd.get('source', '')
    if not source:
        print(f"[ERROR] No source defined for command: {cmd_id}", file=sys.stderr)
        continue

    source_file = os.path.join(commands_dir, source)
    if not os.path.exists(source_file):
        print(f"[ERROR] Source file not found: {source_file}", file=sys.stderr)
        continue

    with open(source_file, 'r') as f:
        content = f.read()

    description = cmd.get('description', '')
    platforms = cmd.get('platforms', [])

    for platform in platforms:
        if platform == 'opencode':
            dest_dir = os.path.join(dotfiles_dir, 'dot_config', 'opencode', 'commands')
            os.makedirs(dest_dir, exist_ok=True)
            dest_file = os.path.join(dest_dir, f"{cmd_id}.md")
            frontmatter = f"""---
description: {description}
---

"""
            with open(dest_file, 'w') as dst:
                dst.write(frontmatter)
                dst.write(content)
            print(f"[INFO] Generated OpenCode: {dest_file}")

        elif platform == 'cursor':
            dest_dir = os.path.join(dotfiles_dir, 'dot_config', 'cursor', 'commands')
            os.makedirs(dest_dir, exist_ok=True)
            dest_file = os.path.join(dest_dir, f"{cmd_id}.md")
            header = "# Cursor Commands\n\n"
            with open(dest_file, 'w') as dst:
                dst.write(header)
                dst.write(content)
            print(f"[INFO] Generated Cursor: {dest_file}")

        elif platform == 'codex':
            dest_dir = os.path.join(dotfiles_dir, 'dot_config', 'codex', 'prompts')
            os.makedirs(dest_dir, exist_ok=True)
            dest_file = os.path.join(dest_dir, f"{cmd_id}.md")
            frontmatter = f"""---
description: {description}
---

"""
            with open(dest_file, 'w') as dst:
                dst.write(frontmatter)
                dst.write(content)
            print(f"[INFO] Generated Codex: {dest_file}")

        else:
            print(f"[WARN] Unknown platform '{platform}' for command: {cmd_id}")
PYEOF
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
        if ! "${SCRIPT_DIR}/validate-commands-structure.sh" &>/dev/null; then
            log_error "Validation failed. Fix errors before generating."
            exit 1
        fi
        log_info "Validation passed."
    fi

    log_info "Generating commands..."
    echo ""

    if [[ -n "${target_command}" ]]; then
        generate_single "${target_command}"
    else
        generate_all
    fi

    echo ""
    log_info "Generation complete."
    echo ""
    log_info "To apply to your home directory, run: chezmoi apply"
}

main "$@"
