#!/usr/bin/env bats

setup() {
    load '../helpers/common'
    setup_temp_dir
    DOTFILES_DIR="$(get_dotfiles_dir)"
    CHECK_SCRIPT="${DOTFILES_DIR}/scripts/check-system-deps.sh"
    ACTIONS_SCRIPT="${DOTFILES_DIR}/scripts/show-system-deps-actions.sh"
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

@test "actions helper emits canonical guidance for known external tooling" {
    cat > "${TEST_INVENTORY}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: @openai/codex
    command: codex
    required: false
    capability: ai-cli
    install_method: npm
    note: Codex CLI.
EOF

    run python3 "${HELPER_SCRIPT}" actions --include-optional --inventory "${TEST_INVENTORY}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Install Codex CLI in the user npm prefix used by this repo."* ]]
    [[ "${output}" == *'npm install -g --prefix="$HOME/.npm-global" @openai/codex@latest'* ]]
}

@test "repo inventory declares agent validation tools in the expected channels" {
    run python3 "${HELPER_SCRIPT}" list --include-optional \
        --inventory "${DOTFILES_DIR}/system/packages/ubuntu.yaml" \
        --inventory "${DOTFILES_DIR}/system/packages/tooling.yaml"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *$'required\tyamllint\tyamllint\tubuntu\tlinting\tapt'* ]]
    [[ "${output}" == *$'required\tgitleaks\tgitleaks\tubuntu\tsecurity\tapt'* ]]
    [[ "${output}" == *$'optional\t@ast-grep/cli\tast-grep\tcommon\tagent-validation\texternal\tnpm'* ]]
    [[ "${output}" == *$'optional\tactionlint\tactionlint\tcommon\tagent-validation\texternal\tgithub-release'* ]]
    [[ "${output}" == *$'optional\tosv-scanner\tosv-scanner\tcommon\tsecurity\texternal\tgithub-release'* ]]
}

@test "actions helper routes agent tools to canonical installers" {
    cat > "${TEST_INVENTORY}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: @ast-grep/cli
    command: ast-grep
    required: false
    capability: agent-validation
    install_method: npm
    note: ast-grep CLI.
  - package: actionlint
    command: actionlint
    required: false
    capability: agent-validation
    install_method: github-release
    note: actionlint.
  - package: osv-scanner
    command: osv-scanner
    required: false
    capability: security
    install_method: github-release
    note: osv.
EOF

    run python3 "${HELPER_SCRIPT}" actions --include-optional --inventory "${TEST_INVENTORY}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *'npm install -g --prefix="$HOME/.npm-global" @ast-grep/cli@latest'* ]]
    [[ "${output}" == *"Install actionlint from the official GitHub release with checksum verification."* ]]
    [[ "${output}" == *"Install OSV-Scanner from the official GitHub release with checksum verification."* ]]
    [[ "${output}" == *"make install-agent-tools"* ]]
}

@test "Makefile exposes agent validation and installation targets" {
    run make -pn -C "${DOTFILES_DIR}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"install-agent-tools:"* ]]
    [[ "${output}" == *"quality-check:"* ]]
    [[ "${output}" == *"security-check:"* ]]
    [[ "${output}" == *"agent-validate:"* ]]
    [[ "${output}" == *"agent-validate-changed:"* ]]
    [[ "${output}" == *"lint-actions:"* ]]
    [[ "${output}" == *"security-osv:"* ]]
    [[ "${output}" == *"install: install-check install-apt install-external install-dotfiles install-verify"* ]]
}

@test "show-system-deps-actions reports actionable guidance for missing external tools" {
    cat > "${TEST_INVENTORY}" <<'EOF'
schema_version: 1
platform: common
manager: external
packages:
  - package: @openai/codex
    command: codex-missing
    required: false
    capability: ai-cli
    install_method: npm
    note: Codex CLI.
  - package: docker
    command: docker-missing
    required: false
    capability: containers
    install_method: manual
    note: Docker workflow.
EOF

    run env PATH="/bin" PYTHON="/usr/bin/python3" bash "${ACTIONS_SCRIPT}" --include-optional --inventory "${TEST_INVENTORY}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"SKIP @openai/codex -> codex-missing"* ]]
    [[ "${output}" == *'npm install -g --prefix="$HOME/.npm-global" @openai/codex@latest'* ]]
    [[ "${output}" == *"Manual: use your chosen Docker Desktop WSL integration or Linux Docker Engine setup."* ]]
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
