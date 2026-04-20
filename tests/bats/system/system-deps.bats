#!/usr/bin/env bats

setup() {
    load '../helpers/common'
    setup_temp_dir
    DOTFILES_DIR="$(get_dotfiles_dir)"
    CHECK_SCRIPT="${DOTFILES_DIR}/scripts/check-system-deps.sh"
    HELPER_SCRIPT="${DOTFILES_DIR}/scripts/lib/system_deps.py"
    TEST_INVENTORY="${TEST_TEMP_DIR}/inventory.yaml"
}

teardown() {
    teardown_temp_dir
}

@test "system deps helper validates inventory schema" {
    cat > "${TEST_INVENTORY}" <<'EOF'
schema_version: 1
platform: test
manager: apt
packages:
  - package: bash
    command: bash
    required: true
    capability: shell
    note: Present on the test runner.
EOF

    run python3 "${HELPER_SCRIPT}" validate --inventory "${TEST_INVENTORY}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *'"package": "bash"'* ]]
}

@test "check-system-deps succeeds when required commands are present" {
    cat > "${TEST_INVENTORY}" <<'EOF'
schema_version: 1
platform: test
manager: external
packages:
  - package: bash-package
    command: bash
    required: true
    capability: shell
    install_method: npm
    note: Uses a different package and command name.
  - package: definitely-not-a-real-command
    command: definitely-not-a-real-command
    required: false
    capability: optional
    install_method: windows
    note: Used to verify optional reporting.
EOF

    run bash "${CHECK_SCRIPT}" --include-optional --inventory "${TEST_INVENTORY}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"OK   bash-package -> bash"* ]]
    [[ "${output}" == *"[required, external:npm]"* ]]
    [[ "${output}" == *"SKIP definitely-not-a-real-command"* ]]
    [[ "${output}" == *"[optional, external:windows]"* ]]
    [[ "${output}" == *"Summary:"* ]]
}

@test "helper filters apt packages out of mixed inventories for installer flows" {
    local apt_inventory="${TEST_TEMP_DIR}/apt.yaml"
    local tooling_inventory="${TEST_TEMP_DIR}/tooling.yaml"

    cat > "${apt_inventory}" <<'EOF'
schema_version: 1
platform: ubuntu
manager: apt
packages:
  - package: git
    command: git
    required: true
    capability: core
    note: Present on the test runner.
EOF

    cat > "${tooling_inventory}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: codex
    command: codex
    required: false
    capability: ai-cli
    install_method: npm
    note: External CLI.
EOF

    run python3 "${HELPER_SCRIPT}" packages --manager apt --inventory "${apt_inventory}" --inventory "${tooling_inventory}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "git" ]]
}

@test "check-system-deps fails when a required command is missing" {
    cat > "${TEST_INVENTORY}" <<'EOF'
schema_version: 1
platform: test
manager: apt
packages:
  - package: definitely-not-a-real-command
    command: definitely-not-a-real-command
    required: true
    capability: missing
    note: Used to verify non-zero exit status.
EOF

    run bash "${CHECK_SCRIPT}" --inventory "${TEST_INVENTORY}"
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"MISS definitely-not-a-real-command"* ]]
}
