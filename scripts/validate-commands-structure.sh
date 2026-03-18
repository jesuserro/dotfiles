#!/usr/bin/env bash
# Validates the structure and quality of commands in ai/assets/commands/
# Checks format, content, and architectural compliance.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"

ERRORS=0
WARNINGS=0

VALID_PLATFORMS=("opencode" "codex" "cursor")

log_error() {
    echo "  ✗ ERROR: $*"
    ((ERRORS++))
}

log_warn() {
    echo "  ⚠ WARNING: $*"
    ((WARNINGS++))
}

log_ok() {
    echo "  ✓ $*"
}

check_registry_exists() {
    echo "Checking registry..."
    if [[ ! -f "${REGISTRY_FILE}" ]]; then
        log_error "registry.yaml not found at ${REGISTRY_FILE}"
        return 1
    fi
    log_ok "registry.yaml exists"
}

check_yaml_valid() {
    if ! python3 -c "import yaml" 2>/dev/null; then
        log_warn "Python yaml module not available - skipping YAML validation"
        return 0
    fi
    
    if python3 -c "import yaml; yaml.safe_load(open('${REGISTRY_FILE}'))" 2>/dev/null; then
        log_ok "Valid YAML"
    else
        log_error "registry.yaml is not valid YAML"
        return 1
    fi
}

check_registry_version() {
    local version
    version=$(python3 - "${REGISTRY_FILE}" 2>/dev/null << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
print(data.get('version', ''))
PYEOF
    )
    
    if [[ -z "${version}" ]]; then
        log_error "Missing 'version' field in registry"
        return 1
    fi
    if [[ "${version}" != "1" ]]; then
        log_warn "Registry version is ${version}, expected 1"
    fi
    log_ok "Registry version: ${version}"
}

check_command_ids_unique() {
    echo "Checking command IDs..."
    
    local id_count unique_count
    id_count=$(python3 - "${REGISTRY_FILE}" 2>/dev/null << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
print(len(data.get('commands', [])))
PYEOF
    )
    
    unique_count=$(python3 - "${REGISTRY_FILE}" 2>/dev/null << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
ids = [c.get('id', '') for c in data.get('commands', [])]
print(len(set(ids)))
PYEOF
    )
    
    if [[ ${id_count} -ne ${unique_count} ]]; then
        log_error "Duplicate command IDs found"
        return 1
    fi
    log_ok "All command IDs are unique (${id_count} commands)"
}

check_command_structure() {
    echo "Checking command structure..."
    
    python3 - "${REGISTRY_FILE}" "${COMMANDS_DIR}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os

registry = sys.argv[1]
commands_dir = sys.argv[2]
valid_platforms = ['opencode', 'codex', 'cursor']
errors = 0

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    if not cmd_id:
        print("  ✗ ERROR: Command missing id field")
        errors += 1
        continue
    
    print(f"  Checking command: {cmd_id}")
    
    # Check source
    source = cmd.get('source', '')
    if not source:
        print(f"  ✗ ERROR: Command '{cmd_id}' missing 'source' field")
        errors += 1
    else:
        source_file = os.path.join(commands_dir, source)
        if not os.path.exists(source_file):
            print(f"  ✗ ERROR: Command '{cmd_id}': source file not found: {source}")
            errors += 1
        else:
            print(f"  ✓ Command '{cmd_id}': source exists")
    
    # Check platforms
    platforms = cmd.get('platforms', [])
    if not platforms:
        print(f"  ✗ ERROR: Command '{cmd_id}' missing 'platforms' field")
        errors += 1
    else:
        for p in platforms:
            if p in valid_platforms:
                print(f"  ✓ Platform '{p}' is valid")
            else:
                print(f"  ✗ ERROR: Command '{cmd_id}': invalid platform '{p}'")
                errors += 1
    
    # Check enabled
    enabled = cmd.get('enabled')
    if enabled is None:
        print(f"  ✗ ERROR: Command '{cmd_id}' missing 'enabled' field")
        errors += 1
    elif enabled not in [True, False]:
        print(f"  ✗ ERROR: Command '{cmd_id}': 'enabled' must be true or false")
        errors += 1

sys.exit(errors)
PYEOF
}

check_command_content() {
    echo "Checking command content..."
    
    python3 - "${REGISTRY_FILE}" "${COMMANDS_DIR}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os

registry = sys.argv[1]
commands_dir = sys.argv[2]

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    source = cmd.get('source', '')
    
    if not source:
        continue
    
    source_file = os.path.join(commands_dir, source)
    
    if not os.path.exists(source_file):
        continue
    
    with open(source_file, 'r') as f:
        content = f.read()
    
    # Check for title
    if not any(line.strip().startswith('# ') for line in content.split('\n')):
        print(f"  ✗ ERROR: Command '{cmd_id}': COMMAND.md missing title (should start with '# ')")
    
    # Check for sections
    if not any(line.strip().startswith('## ') for line in content.split('\n')):
        print(f"  ✗ ERROR: Command '{cmd_id}': COMMAND.md missing sections (should have '## ' headings)")
    
    # Check for minimal content
    line_count = len(content.split('\n'))
    if line_count < 10:
        print(f"  ⚠ WARNING: Command '{cmd_id}': COMMAND.md seems minimal (< 10 lines)")
PYEOF
}

check_generated_artifacts() {
    echo "Checking generated artifacts..."
    local opencode_dir="${DOTFILES_DIR}/dot_config/opencode/commands"
    
    if [[ ! -d "${opencode_dir}" ]]; then
        log_warn "OpenCode commands directory not found: ${opencode_dir}"
        return 0
    fi
    
    python3 - "${REGISTRY_FILE}" "${opencode_dir}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os

registry = sys.argv[1]
opencode_dir = sys.argv[2]

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    enabled = cmd.get('enabled', False)
    platforms = cmd.get('platforms', [])
    
    if enabled and 'opencode' in platforms:
        expected_file = os.path.join(opencode_dir, f"{cmd_id}.md")
        if os.path.exists(expected_file):
            print(f"  ✓ Generated artifact exists: {cmd_id}.md")
        else:
            print(f"  ⚠ WARNING: Expected artifact not found: {cmd_id}.md (run generate-commands.sh)")
PYEOF
}

main() {
    echo "========================================"
    echo "COMMAND STRUCTURE VALIDATION"
    echo "========================================"
    echo ""
    
    check_registry_exists || true
    check_yaml_valid || true
    check_registry_version || true
    check_command_ids_unique || true
    check_command_structure || true
    check_command_content || true
    
    echo ""
    echo "========================================"
    echo "GENERATED ARTIFACTS CHECK"
    echo "========================================"
    echo ""
    
    check_generated_artifacts || true
    
    echo ""
    echo "========================================"
    echo "SUMMARY"
    echo "========================================"
    echo "Errors:   ${ERRORS}"
    echo "Warnings: ${WARNINGS}"
    echo ""
    
    if [[ ${ERRORS} -gt 0 ]]; then
        echo "Validation FAILED"
        exit 1
    elif [[ ${WARNINGS} -gt 0 ]]; then
        echo "Validation PASSED with warnings"
        exit 0
    else
        echo "Validation PASSED"
        exit 0
    fi
}

main "$@"
