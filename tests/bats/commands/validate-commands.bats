#!/usr/bin/env bats
# Tests for commands system (multi-platform)
# Run with: bats tests/bats/commands/validate-commands.bats

setup() {
    load '../helpers/common'
    DOTFILES_DIR="$(get_dotfiles_dir)"
    COMMANDS_DIR="${DOTFILES_DIR}/ai/assets/commands"
    REGISTRY_FILE="${COMMANDS_DIR}/registry.yaml"
    OPENCODE_COMMANDS="${DOTFILES_DIR}/dot_config/opencode/commands"
    CURSOR_COMMANDS="${DOTFILES_DIR}/dot_config/cursor/commands"
    CODEX_PROMPTS="${DOTFILES_DIR}/dot_config/codex/prompts"
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

@test "generate-commands produces sos.md for opencode" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh" -c sos
    [[ $status -eq 0 ]]

    sos_file="${OPENCODE_COMMANDS}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "generate-commands produces sos.md for cursor" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh" -c sos
    [[ $status -eq 0 ]]

    sos_file="${CURSOR_COMMANDS}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "generate-commands produces sos.md for codex" {
    run bash "${DOTFILES_DIR}/scripts/generate-commands.sh" -c sos
    [[ $status -eq 0 ]]

    sos_file="${CODEX_PROMPTS}/sos.md"
    [[ -f "${sos_file}" ]]
}

# =============================================================================
# Format Validation Tests
# =============================================================================

@test "generated opencode sos.md has frontmatter" {
    sos_file="${OPENCODE_COMMANDS}/sos.md"
    run grep -q "^---$" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated opencode sos.md has description in frontmatter" {
    sos_file="${OPENCODE_COMMANDS}/sos.md"
    run grep -q "^description:" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated opencode sos.md has correct content" {
    sos_file="${OPENCODE_COMMANDS}/sos.md"
    run grep -q "SOS Command" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated cursor sos.md does NOT have frontmatter" {
    sos_file="${CURSOR_COMMANDS}/sos.md"
    run head -n 1 "${sos_file}"
    [[ "$output" != "---" ]]
}

@test "generated cursor sos.md starts with Markdown header" {
    sos_file="${CURSOR_COMMANDS}/sos.md"
    run head -n 1 "${sos_file}"
    [[ "$output" == "# "* ]]
}

@test "generated codex sos.md has frontmatter" {
    sos_file="${CODEX_PROMPTS}/sos.md"
    run grep -q "^---$" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated codex sos.md has description in frontmatter" {
    sos_file="${CODEX_PROMPTS}/sos.md"
    run grep -q "^description:" "${sos_file}"
    [[ $status -eq 0 ]]
}

@test "generated codex sos.md has correct content" {
    sos_file="${CODEX_PROMPTS}/sos.md"
    run grep -q "SOS Command" "${sos_file}"
    [[ $status -eq 0 ]]
}

# =============================================================================
# Invocation Reference Tests
# =============================================================================

@test "opencode invocation is /sos" {
    sos_file="${OPENCODE_COMMANDS}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "cursor invocation is /sos" {
    sos_file="${CURSOR_COMMANDS}/sos.md"
    [[ -f "${sos_file}" ]]
}

@test "codex invocation is /prompts:sos" {
    sos_file="${CODEX_PROMPTS}/sos.md"
    [[ -f "${sos_file}" ]]
}
