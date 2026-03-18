#!/usr/bin/env bash
# Validates canonical command structure and, when present, generated build artifacts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "${SCRIPT_DIR}")"
COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"
ADAPTERS_DIR="${DOTFILES_DIR}/ai/adapters"
BUILD_DIR="${DOTFILES_DIR}/build/commands"

ERRORS=0
WARNINGS=0

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

log_info() {
    echo "  [INFO] $*"
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
    version=$(python3 - "${REGISTRY_FILE}" <<'PYEOF'
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

print(data.get("version", ""))
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
    id_count=$(python3 - "${REGISTRY_FILE}" <<'PYEOF'
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

print(len(data.get("commands", [])))
PYEOF
    )

    unique_count=$(python3 - "${REGISTRY_FILE}" <<'PYEOF'
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

ids = [command.get("id", "") for command in data.get("commands", [])]
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

    python3 - "${REGISTRY_FILE}" "${COMMANDS_DIR}" <<'PYEOF'
import os
import sys
import yaml

registry = sys.argv[1]
commands_dir = sys.argv[2]
valid_platforms = ["opencode", "cursor", "codex"]
errors = 0

with open(registry, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

for cmd in data.get("commands", []):
    cmd_id = cmd.get("id", "")
    if not cmd_id:
        print("  [ERROR] Command missing id field")
        errors += 1
        continue

    print(f"  Checking command: {cmd_id}")

    source = cmd.get("source", "")
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

    platforms = cmd.get("platforms", [])
    if not platforms:
        print(f"  [ERROR] Command '{cmd_id}' missing 'platforms' field")
        errors += 1
    else:
        for platform in platforms:
            if platform in valid_platforms:
                print(f"  [OK] Platform '{platform}' is valid")
            else:
                print(f"  [ERROR] Command '{cmd_id}': invalid platform '{platform}'")
                errors += 1

    enabled = cmd.get("enabled")
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

    python3 - "${REGISTRY_FILE}" "${COMMANDS_DIR}" <<'PYEOF'
import os
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

commands_dir = sys.argv[2]

for cmd in data.get("commands", []):
    cmd_id = cmd.get("id", "")
    source = cmd.get("source", "")

    if not source:
        continue

    source_file = os.path.join(commands_dir, source)
    if not os.path.exists(source_file):
        continue

    with open(source_file, "r", encoding="utf-8") as handle:
        content = handle.read()

    if not any(line.strip().startswith("# ") for line in content.split("\n")):
        print(f"  [ERROR] Command '{cmd_id}': COMMAND.md missing title (should start with '# ')")

    if not any(line.strip().startswith("## ") for line in content.split("\n")):
        print(f"  [WARN] Command '{cmd_id}': COMMAND.md missing sections (should have '## ' headings)")

    if len(content.split("\n")) < 10:
        print(f"  [WARN] Command '{cmd_id}': COMMAND.md seems minimal (< 10 lines)")
PYEOF
}

check_adapters_exist() {
    echo "Checking platform adapters..."

    local missing=0
    for platform in opencode cursor codex; do
        local template="${ADAPTERS_DIR}/${platform}/TEMPLATE.md"
        if [[ -f "${template}" ]]; then
            log_ok "Adapter '${platform}' has TEMPLATE.md"
        else
            log_error "Adapter '${platform}' missing TEMPLATE.md: ${template}"
            missing=1
        fi
    done

    return "${missing}"
}

check_build_artifacts() {
    local platform="$1"
    local platform_dir="${BUILD_DIR}/${platform}"

    echo "Checking ${platform} build artifacts..."

    if [[ ! -d "${platform_dir}" ]]; then
        log_info "Build artifacts not generated yet for ${platform}: ${platform_dir}"
        return 0
    fi

    python3 - "${REGISTRY_FILE}" "${platform}" "${platform_dir}" <<'PYEOF'
import os
import re
import sys
import yaml

registry, platform, build_dir = sys.argv[1:4]
errors = 0

with open(registry, "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle)

for cmd in data.get("commands", []):
    cmd_id = cmd.get("id", "")
    enabled = cmd.get("enabled", False)
    platforms = cmd.get("platforms", [])

    if not enabled or platform not in platforms:
        continue

    expected_file = os.path.join(build_dir, f"{cmd_id}.md")
    if not os.path.exists(expected_file):
        print(f"  [ERROR] Missing build artifact: {platform}/{cmd_id}.md")
        errors += 1
        continue

    print(f"  [OK] Build artifact exists: {platform}/{cmd_id}.md")

    with open(expected_file, "r", encoding="utf-8") as handle:
        content = handle.read()

    if "managed-by: dotfiles-global-commands" not in content:
        print(f"  [ERROR] Missing managed marker in {platform}/{cmd_id}.md")
        errors += 1

    if platform in {"opencode", "codex"}:
        if not content.startswith("---"):
            print(f"  [ERROR] {platform}/{cmd_id}.md missing frontmatter")
            errors += 1
        else:
            match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
            if not match or "description:" not in match.group(1):
                print(f"  [ERROR] {platform}/{cmd_id}.md frontmatter missing description")
                errors += 1
    elif platform == "cursor":
        if content.startswith("---"):
            print(f"  [ERROR] cursor/{cmd_id}.md should not have frontmatter")
            errors += 1
        if not content.lstrip().startswith("<!-- managed-by: dotfiles-global-commands -->"):
            print(f"  [ERROR] cursor/{cmd_id}.md should start with managed marker")
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
    echo "PLATFORM ADAPTERS CHECK"
    echo "========================================"
    echo ""

    check_adapters_exist || true

    echo ""
    echo "========================================"
    echo "BUILD ARTIFACTS CHECK"
    echo "========================================"
    echo ""

    check_build_artifacts opencode || true
    echo ""
    check_build_artifacts cursor || true
    echo ""
    check_build_artifacts codex || true

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
