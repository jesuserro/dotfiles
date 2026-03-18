#!/usr/bin/env bash
# Generates command artifacts from canonical source to platform surfaces.
# Source of truth: ai/assets/commands/
# Target surfaces: dot_config/opencode/commands/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"

OPENCODE_COMMANDS="${DOTFILES_DIR}/dot_config/opencode/commands"

VALID_PLATFORMS=("opencode" "codex" "cursor")

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
    enabled = '✓ enabled' if cmd.get('enabled') else '✗ disabled'
    print(f"  - {cmd_id} [{platforms}] {enabled}")
PYEOF
    echo ""
}

generate_command() {
    local cmd_id="$1"
    
    python3 - "${REGISTRY_FILE}" "${cmd_id}" "${COMMANDS_DIR}" "${DOTFILES_DIR}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os
import shutil

registry = sys.argv[1] if len(sys.argv) > 1 else ''
cmd_id = sys.argv[2] if len(sys.argv) > 2 else ''
commands_dir = sys.argv[3] if len(sys.argv) > 3 else ''
dotfiles_dir = sys.argv[4] if len(sys.argv) > 4 else ''

if not registry or not cmd_id:
    sys.exit(1)

opencode_dir = os.path.join(dotfiles_dir, 'dot_config', 'opencode', 'commands')

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
        
        platforms = cmd.get('platforms', [])
        for platform in platforms:
            if platform == 'opencode':
                dest_file = os.path.join(opencode_dir, f"{cmd_id}.md")
                os.makedirs(opencode_dir, exist_ok=True)
                shutil.copy2(source_file, dest_file)
                print(f"[INFO] Generated: {dest_file}")
            elif platform in ('codex', 'cursor'):
                print(f"[INFO] Platform {platform} not yet implemented for command: {cmd_id}")
            else:
                print(f"[WARN] Unknown platform '{platform}' for command: {cmd_id}")
        
        sys.exit(0)

print(f"[ERROR] Command not found: {cmd_id}", file=sys.stderr)
sys.exit(1)
PYEOF
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

EXAMPLES:
    $(basename "$0")                  # Generate all commands
    $(basename "$0") --list           # List available commands
    $(basename "$0") -c sos           # Generate only 'sos' command
    $(basename "$0") --validate       # Validate and generate

SOURCE: ${COMMANDS_DIR}
TARGET: ${OPENCODE_COMMANDS}

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
        generate_command "${target_command}"
    else
        python3 - "${REGISTRY_FILE}" "${DOTFILES_DIR}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os
import shutil

registry = sys.argv[1] if len(sys.argv) > 1 else ''
dotfiles_dir = sys.argv[2] if len(sys.argv) > 2 else ''

if not registry or not dotfiles_dir:
    sys.exit(1)

commands_dir = os.path.dirname(registry)
opencode_dir = os.path.join(dotfiles_dir, 'dot_config', 'opencode', 'commands')

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
    
    platforms = cmd.get('platforms', [])
    for platform in platforms:
        if platform == 'opencode':
            dest_file = os.path.join(opencode_dir, f"{cmd_id}.md")
            os.makedirs(opencode_dir, exist_ok=True)
            shutil.copy2(source_file, dest_file)
            print(f"[INFO] Generated: {dest_file}")
        elif platform in ('codex', 'cursor'):
            print(f"[INFO] Platform {platform} not yet implemented for command: {cmd_id}")
        else:
            print(f"[WARN] Unknown platform '{platform}' for command: {cmd_id}")
PYEOF
    fi
    
    echo ""
    log_info "Generation complete."
}

main "$@"
