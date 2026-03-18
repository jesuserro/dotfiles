#!/usr/bin/env bats
# Tests for commands system (multi-platform)
# Run with: bats tests/bats/commands/validate-commands.bats

setup() {
    load '../helpers/common'
    DOTFILES_DIR="$(get_dotfiles_dir)"
    COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
    REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"
    BUILD_COMMANDS="${DOTFILES_DIR}/build/commands"
    OPENCODE_BUILD="${BUILD_COMMANDS}/opencode"
    CURSOR_BUILD="${BUILD_COMMANDS}/cursor"
    CODEX_BUILD="${BUILD_COMMANDS}/codex"
    TEST_HOME_ROOT="$(mktemp -d)"
}

teardown() {
    rm -rf "${TEST_HOME_ROOT}"
}

# =============================================================================
# Registry Tests
# =============================================================================

@test "commands directory exists" {
    [[ -d "${COMMANDS_DIR}" ]]
}

@test "registry.yaml exists" {
    [[ -f "${REGISTRY_FILE}" ]]
}

@test "registry.yaml is valid YAML" {
    run python3 -c "import yaml; yaml.safe_load(open('${REGISTRY_FILE}'))"
    [[ $status -eq 0 ]]
}

@test "registry has version 1" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
print(data.get('version', ''))
PYEOF
    [[ "$output" == "1" ]]
}

@test "all command IDs are unique" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
ids = [c.get('id', '') for c in data.get('commands', [])]
if len(ids) != len(set(ids)):
    sys.exit(1)
PYEOF
    [[ $status -eq 0 ]]
}

@test "command has description" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
for cmd in data.get('commands', []):
    if cmd.get('id') == 'sos':
        desc = cmd.get('description', '')
        if not desc or desc == 'null':
            sys.exit(1)
        print(desc)
PYEOF
    [[ $status -eq 0 ]]
    [[ -n "$output" ]]
}

# =============================================================================
# SOS Command Tests
# =============================================================================

@test "sos command is defined" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
for cmd in data.get('commands', []):
    print(cmd.get('id', ''))
PYEOF
    [[ "$output" == *"sos"* ]]
}

@test "sos command is enabled" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
for cmd in data.get('commands', []):
    if cmd.get('id') == 'sos':
        print(cmd.get('enabled', False))
PYEOF
    [[ "$output" == "True" ]]
}

@test "sos source file exists" {
    command_file="${COMMANDS_DIR}/sos/COMMAND.md"
    [[ -f "${command_file}" ]]
}

@test "sos COMMAND.md has title" {
    command_file="${COMMANDS_DIR}/sos/COMMAND.md"
    run grep -q "^# " "${command_file}"
    [[ $status -eq 0 ]]
}

@test "sos COMMAND.md has sections" {
    command_file="${COMMANDS_DIR}/sos/COMMAND.md"
    run grep -q "^## " "${command_file}"
    [[ $status -eq 0 ]]
}

# =============================================================================
# Platform Support Tests
# =============================================================================

@test "sos command supports opencode platform" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
for cmd in data.get('commands', []):
    if cmd.get('id') == 'sos':
        platforms = cmd.get('platforms', [])
        print('opencode' in platforms)
PYEOF
    [[ "$output" == "True" ]]
}

@test "sos command supports cursor platform" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
for cmd in data.get('commands', []):
    if cmd.get('id') == 'sos':
        platforms = cmd.get('platforms', [])
        print('cursor' in platforms)
PYEOF
    [[ "$output" == "True" ]]
}

@test "sos command supports codex platform" {
    run python3 - "${REGISTRY_FILE}" << 'PYEOF'
import sys
import yaml
registry = sys.argv[1]
with open(registry, 'r') as f:
    data = yaml.safe_load(f)
for cmd in data.get('commands', []):
    if cmd.get('id') == 'sos':
        platforms = cmd.get('platforms', [])
        print('codex' in platforms)
PYEOF
    [[ "$output" == "True" ]]
}

# =============================================================================
# Generator Tests
# =============================================================================

@test "generate-commands script exists and is executable" {
    generate_script="${DOTFILES_DIR}/scripts/generate-commands.sh"
    [[ -f "${generate_script}" ]]
    [[ -x "${generate_script}" ]]
}

@test "validate-commands script exists and is executable" {
    validate_script="${DOTFILES_DIR}/scripts/validate-commands-structure.sh"
    [[ -f "${validate_script}" ]]
    [[ -x "${validate_script}" ]]
}

@test "validate-commands passes" {
    run bash "${DOTFILES_DIR}/scripts/validate-commands-structure.sh"
    [[ $status -eq 0 ]]
}

@test "materialize-commands script exists and is executable" {
    materialize_script="${DOTFILES_DIR}/scripts/materialize-commands.sh"
    [[ -f "${materialize_script}" ]]
    [[ -x "${materialize_script}" ]]
}

@test "validate-commands passes when build artifacts do not exist yet" {
    rm -rf "${BUILD_COMMANDS}"

    run bash "${DOTFILES_DIR}/scripts/validate-commands-structure.sh"
    [[ $status -eq 0 ]]
    [[ "$output" == *"Build artifacts not generated yet"* ]]
}

@test "generate-commands produces sos.md for opencode build" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh" -c sos
    [[ $status -eq 0 ]]

    sos_file="${OPENCODE_BUILD}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "generate-commands produces sos.md for cursor build" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh" -c sos
    [[ $status -eq 0 ]]

    sos_file="${CURSOR_BUILD}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "generate-commands produces sos.md for codex build" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh" -c sos
    [[ $status -eq 0 ]]

    sos_file="${CODEX_BUILD}/sos.md"
    [[ -f "${sos_file}" ]]
}

# =============================================================================
# Format Validation Tests
# =============================================================================

@test "generated opencode sos.md has frontmatter" {
    sos_file="${OPENCODE_BUILD}/sos.md"
    run grep -q "^---$" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated opencode sos.md has description in frontmatter" {
    sos_file="${OPENCODE_BUILD}/sos.md"
    run grep -q "^description:" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated opencode sos.md has managed marker" {
    sos_file="${OPENCODE_BUILD}/sos.md"
    run grep -q "managed-by: dotfiles-global-commands" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated opencode sos.md has correct content" {
    sos_file="${OPENCODE_BUILD}/sos.md"
    run grep -q "SOS Command" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated cursor sos.md does NOT have frontmatter" {
    sos_file="${CURSOR_BUILD}/sos.md"
    run head -n 1 "${sos_file}"
    [[ "$output" == "<!-- managed-by: dotfiles-global-commands -->" ]]
}

@test "generated cursor sos.md starts with Markdown header" {
    sos_file="${CURSOR_BUILD}/sos.md"
    run sed -n '3p' "${sos_file}"
    [[ "$output" == "# "* ]]
}

@test "generated codex sos.md has frontmatter" {
    sos_file="${CODEX_BUILD}/sos.md"
    run grep -q "^---$" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated codex sos.md has description in frontmatter" {
    sos_file="${CODEX_BUILD}/sos.md"
    run grep -q "^description:" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated codex sos.md has correct content" {
    sos_file="${CODEX_BUILD}/sos.md"
    run grep -q "SOS Command" "${sos_file}"
    [[ $status -eq 0 ]]
}

# =============================================================================
# Invocation Reference Tests
# =============================================================================

@test "opencode invocation is /sos" {
    sos_file="${OPENCODE_BUILD}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "cursor invocation is /sos" {
    sos_file="${CURSOR_BUILD}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "codex invocation is /prompts:sos" {
    sos_file="${CODEX_BUILD}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "materialize-commands publishes to a configurable home root" {
    run env COMMANDS_HOME_ROOT="${TEST_HOME_ROOT}" bash "${DOTFILES_DIR}/scripts/materialize-commands.sh"
    [[ $status -eq 0 ]]

    [[ -f "${TEST_HOME_ROOT}/.config/opencode/commands/sos.md" ]]
    [[ -f "${TEST_HOME_ROOT}/.cursor/commands/sos.md" ]]
    [[ -f "${TEST_HOME_ROOT}/.codex/prompts/sos.md" ]]
}

@test "materialize-commands removes obsolete managed files but preserves manual files" {
    managed_dir="${TEST_HOME_ROOT}/.cursor/commands"
    mkdir -p "${managed_dir}"

    cat > "${managed_dir}/obsolete.md" <<'EOF'
<!-- managed-by: dotfiles-global-commands -->
old content
EOF

    cat > "${managed_dir}/manual.md" <<'EOF'
manual content
EOF

    run env COMMANDS_HOME_ROOT="${TEST_HOME_ROOT}" bash "${DOTFILES_DIR}/scripts/materialize-commands.sh"
    [[ $status -eq 0 ]]

    [[ ! -f "${managed_dir}/obsolete.md" ]]
    [[ -f "${managed_dir}/manual.md" ]]
}

@test "materialize-commands can reuse an existing build without regenerating" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh"
    [[ $status -eq 0 ]]

    run env COMMANDS_HOME_ROOT="${TEST_HOME_ROOT}" bash "${DOTFILES_DIR}/scripts/materialize-commands.sh" --skip-generate
    [[ $status -eq 0 ]]

    [[ -f "${TEST_HOME_ROOT}/.config/opencode/commands/sos.md" ]]
}
