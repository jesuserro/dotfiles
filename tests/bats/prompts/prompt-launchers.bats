#!/usr/bin/env bats
#
# Tests for prompt launchers backed by external vault markdown files.

load '../helpers/common'

setup() {
    setup_temp_dir

    DOTFILES_DIR="$(get_dotfiles_dir)"
    LAUNCHER_DIR="${DOTFILES_DIR}/local/bin"
    UNDERSTAND_LAUNCHER="${LAUNCHER_DIR}/prompt-understand-context"
    PLAN_LAUNCHER="${LAUNCHER_DIR}/prompt-plan-safe-change"
    DETECT_LAUNCHER="${LAUNCHER_DIR}/prompt-detect-errors"
    HELPER="${DOTFILES_DIR}/scripts/lib/prompt-vault-common.sh"

    VAULT_ROOT="${TEST_TEMP_DIR}/vault"
    PROMPTS_DIR="${VAULT_ROOT}/agents/prompts"
    mkdir -p "${PROMPTS_DIR}"

    cat > "${PROMPTS_DIR}/understand-context.md" <<'EOF'
# Understand Context
Prompt body for understand context.
EOF

    cat > "${PROMPTS_DIR}/plan-safe-change.md" <<'EOF'
# Plan Safe Change
Prompt body for plan safe change.
EOF

    cat > "${PROMPTS_DIR}/detect-errors.md" <<'EOF'
# Detect Errors
Prompt body for detect errors.
EOF
}

teardown() {
    teardown_temp_dir
}

@test "prompt helper exists" {
    [[ -f "${HELPER}" ]]
}

@test "launchers exist and are executable" {
    [[ -x "${UNDERSTAND_LAUNCHER}" ]]
    [[ -x "${PLAN_LAUNCHER}" ]]
    [[ -x "${DETECT_LAUNCHER}" ]]
}

@test "helper defines local provisional default constant" {
    grep -q "DEFAULT_AI_PROMPTS_VAULT_ROOT" "${HELPER}"
    grep -q "not a semantic contract" "${HELPER}"
}

@test "understand-context launcher prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${UNDERSTAND_LAUNCHER}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Understand Context"* ]]
}

@test "plan-safe-change launcher prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${PLAN_LAUNCHER}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Plan Safe Change"* ]]
}

@test "detect-errors launcher prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${DETECT_LAUNCHER}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Detect Errors"* ]]
}

@test "missing vault root reports resolved vault and override hint" {
    local missing_vault="${TEST_TEMP_DIR}/missing-vault"

    run env AI_PROMPTS_VAULT_ROOT="${missing_vault}" bash "${DETECT_LAUNCHER}"
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Vault root not found."* ]]
    [[ "${output}" == *"Resolved vault root: ${missing_vault}"* ]]
    [[ "${output}" == *"Prompt path attempted: ${missing_vault}/agents/prompts/detect-errors.md"* ]]
    [[ "${output}" == *"AI_PROMPTS_VAULT_ROOT"* ]]
}

@test "missing prompt markdown reports attempted path and override hint" {
    rm -f "${PROMPTS_DIR}/detect-errors.md"

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${DETECT_LAUNCHER}"
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Prompt markdown not found."* ]]
    [[ "${output}" == *"Resolved vault root: ${VAULT_ROOT}"* ]]
    [[ "${output}" == *"Prompt path attempted: ${VAULT_ROOT}/agents/prompts/detect-errors.md"* ]]
    [[ "${output}" == *"AI_PROMPTS_VAULT_ROOT"* ]]
}

@test "without env override uses the centralized fallback path" {
    run bash "${DETECT_LAUNCHER}"

    if [[ "${status}" -eq 0 ]]; then
        [[ -n "${output}" ]]
    else
        [[ "${output}" == *"Resolved vault root: /mnt/c/Users/jesus/Documents/vault_trabajo"* ]]
        [[ "${output}" == *"Prompt path attempted: /mnt/c/Users/jesus/Documents/vault_trabajo/agents/prompts/detect-errors.md"* ]]
    fi
}

@test "launcher works through a symlinked entrypoint" {
    local symlink_path="${TEST_TEMP_DIR}/prompt-detect-errors"
    ln -s "${DETECT_LAUNCHER}" "${symlink_path}"

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${symlink_path}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Detect Errors"* ]]
}
