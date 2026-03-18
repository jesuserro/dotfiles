#!/usr/bin/env bash
# Validates the structure and quality of commands in ai/assets/commands/
# Checks format, content, architectural compliance, and multi-platform artifacts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"

OPENCODE_COMMANDS="${DOTFILES_DIR}/dot_config/opencode/commands"
CURSOR_COMMANDS="${DOTFILES_DIR}/dot_config/cursor/commands"
CODEX_PROMPTS="${DOTFILES_DIR}/dot_config/codex/prompts"

ERRORS=0
WARNINGS=0

VALID_PLATFORMS=("opencode" "cursor" "codex")

log_error() {
    echo "  [ERROR] $*"
    ((ERRORS++)) || true
}

log_warn() {
    echo "  [WARN] $*"
    ((WARNINGS++)) || true
}

log_ok() {
    echo "  [OK] $*"
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
valid_platforms = ['opencode', 'cursor', 'codex']
errors = 0

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    if not cmd_id:
        print("  [ERROR] Command missing id field")
        errors += 1
        continue

    print(f"  Checking command: {cmd_id}")

    # Check source
    source = cmd.get('source', '')
    if not source:
        print(f"  [ERROR] Command '{cmd_id}' missing 'source' field")
        errors += 1
    else:
        source_file = os.path.join(commands_dir, source)
        if not os.path.exists(source_file):
            print(f"  [ERROR] Command '{cmd_id}': source file not found: {source}")
            errors += 1
        else:
            print(f"  [OK] Command '{cmd_id}': source exists")

    # Check platforms
    platforms = cmd.get('platforms', [])
    if not platforms:
        print(f"  [ERROR] Command '{cmd_id}' missing 'platforms' field")
        errors += 1
    else:
        for p in platforms:
            if p in valid_platforms:
                print(f"  [OK] Platform '{p}' is valid")
            else:
                print(f"  [ERROR] Command '{cmd_id}': invalid platform '{p}'")
                errors += 1

    # Check enabled
    enabled = cmd.get('enabled')
    if enabled is None:
        print(f"  [ERROR] Command '{cmd_id}' missing 'enabled' field")
        errors += 1
    elif enabled not in [True, False]:
        print(f"  [ERROR] Command '{cmd_id}': 'enabled' must be true or false")
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
        print(f"  [ERROR] Command '{cmd_id}': COMMAND.md missing title (should start with '# ')")

    # Check for sections
    if not any(line.strip().startswith('## ') for line in content.split('\n')):
        print(f"  [WARN] Command '{cmd_id}': COMMAND.md missing sections (should have '## ' headings)")

    # Check for minimal content
    line_count = len(content.split('\n'))
    if line_count < 10:
        print(f"  [WARN] Command '{cmd_id}': COMMAND.md seems minimal (< 10 lines)")
PYEOF
}

check_opencode_artifacts() {
    echo "Checking OpenCode artifacts..."

    if [[ ! -d "${OPENCODE_COMMANDS}" ]]; then
        log_warn "OpenCode commands directory not found: ${OPENCODE_COMMANDS}"
        return 0
    fi

    python3 - "${REGISTRY_FILE}" "${OPENCODE_COMMANDS}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os
import re

registry = sys.argv[1]
opencode_dir = sys.argv[2]
errors = 0

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    enabled = cmd.get('enabled', False)
    platforms = cmd.get('platforms', [])

    if enabled and 'opencode' in platforms:
        expected_file = os.path.join(opencode_dir, f"{cmd_id}.md")
        if os.path.exists(expected_file):
            print(f"  [OK] OpenCode artifact exists: {cmd_id}.md")

            with open(expected_file, 'r') as f:
                content = f.read()

            # Check for frontmatter
            if content.startswith('---'):
                # Extract frontmatter
                match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
                if match:
                    fm_text = match.group(1)
                    if 'description:' in fm_text:
                        print(f"  [OK] OpenCode has frontmatter with description")
                    else:
                        print(f"  [WARN] OpenCode frontmatter missing 'description:'")
                else:
                    print(f"  [WARN] OpenCode frontmatter format may be invalid")
            else:
                print(f"  [ERROR] OpenCode artifact missing frontmatter")
                errors += 1
        else:
            print(f"  [WARN] OpenCode artifact not found: {cmd_id}.md (run generate-commands.sh)")
            errors += 1

sys.exit(errors)
PYEOF
}

check_cursor_artifacts() {
    echo "Checking Cursor artifacts..."

    if [[ ! -d "${CURSOR_COMMANDS}" ]]; then
        log_warn "Cursor commands directory not found: ${CURSOR_COMMANDS}"
        return 0
    fi

    python3 - "${REGISTRY_FILE}" "${CURSOR_COMMANDS}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os

registry = sys.argv[1]
cursor_dir = sys.argv[2]
errors = 0

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    enabled = cmd.get('enabled', False)
    platforms = cmd.get('platforms', [])

    if enabled and 'cursor' in platforms:
        expected_file = os.path.join(cursor_dir, f"{cmd_id}.md")
        if os.path.exists(expected_file):
            print(f"  [OK] Cursor artifact exists: {cmd_id}.md")

            with open(expected_file, 'r') as f:
                content = f.read()

            # Cursor expects Markdown without frontmatter
            if not content.startswith('---'):
                print(f"  [OK] Cursor artifact has correct Markdown format (no frontmatter)")
            else:
                print(f"  [WARN] Cursor artifact should not have frontmatter")
        else:
            print(f"  [WARN] Cursor artifact not found: {cmd_id}.md (run generate-commands.sh)")
            errors += 1

sys.exit(errors)
PYEOF
}

check_codex_artifacts() {
    echo "Checking Codex artifacts..."

    if [[ ! -d "${CODEX_PROMPTS}" ]]; then
        log_warn "Codex prompts directory not found: ${CODEX_PROMPTS}"
        return 0
    fi

    python3 - "${REGISTRY_FILE}" "${CODEX_PROMPTS}" 2>/dev/null << 'PYEOF'
import sys
import yaml
import os
import re

registry = sys.argv[1]
codex_dir = sys.argv[2]
errors = 0

with open(registry, 'r') as f:
    data = yaml.safe_load(f)

for cmd in data.get('commands', []):
    cmd_id = cmd.get('id', '')
    enabled = cmd.get('enabled', False)
    platforms = cmd.get('platforms', [])

    if enabled and 'codex' in platforms:
        expected_file = os.path.join(codex_dir, f"{cmd_id}.md")
        if os.path.exists(expected_file):
            print(f"  [OK] Codex artifact exists: {cmd_id}.md")

            with open(expected_file, 'r') as f:
                content = f.read()

            # Check for frontmatter
            if content.startswith('---'):
                match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
                if match:
                    fm_text = match.group(1)
                    if 'description:' in fm_text:
                        print(f"  [OK] Codex has frontmatter with description")
                    else:
                        print(f"  [WARN] Codex frontmatter missing 'description:'")
                else:
                    print(f"  [WARN] Codex frontmatter format may be invalid")
            else:
                print(f"  [ERROR] Codex artifact missing frontmatter")
                errors += 1
        else:
            print(f"  [WARN] Codex artifact not found: {cmd_id}.md (run generate-commands.sh)")
            errors += 1

sys.exit(errors)
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
    echo "OPENCODE ARTIFACTS CHECK"
    echo "========================================"
    echo ""

    check_opencode_artifacts || true

    echo ""
    echo "========================================"
    echo "CURSOR ARTIFACTS CHECK"
    echo "========================================"
    echo ""

    check_cursor_artifacts || true

    echo ""
    echo "========================================"
    echo "CODEX ARTIFACTS CHECK"
    echo "========================================"
    echo ""

    check_codex_artifacts || true

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
