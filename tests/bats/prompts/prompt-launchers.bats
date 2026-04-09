#!/usr/bin/env bats
#
# Tests for prompt launchers backed by external vault markdown files.

load '../helpers/common'

setup() {
    setup_temp_dir

    DOTFILES_DIR="$(get_dotfiles_dir)"
    LAUNCHER_DIR="${DOTFILES_DIR}/local/bin"
    AI_PROMPT_LAUNCHER="${LAUNCHER_DIR}/ai-prompt"
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

    cat > "${PROMPTS_DIR}/summarize-repo.md" <<'EOF'
# Summarize Repo
Prompt body for summarize repo.
EOF

    cat > "${PROMPTS_DIR}/review-diff.md" <<'EOF'
# Review Diff
Prompt body for review diff.
EOF

    cat > "${PROMPTS_DIR}/write-commit-message.md" <<'EOF'
# Write Commit Message
Prompt body for write commit message.
EOF

    cat > "${PROMPTS_DIR}/design-test-cases.md" <<'EOF'
# Design Test Cases
Prompt body for design test cases.
EOF
}

teardown() {
    teardown_temp_dir
}

@test "prompt helper exists" {
    [[ -f "${HELPER}" ]]
}

@test "launchers exist and are executable" {
    [[ -x "${AI_PROMPT_LAUNCHER}" ]]
    [[ -x "${UNDERSTAND_LAUNCHER}" ]]
    [[ -x "${PLAN_LAUNCHER}" ]]
    [[ -x "${DETECT_LAUNCHER}" ]]
}

@test "helper defines local provisional default constant and central catalog" {
    grep -q "DEFAULT_AI_PROMPTS_VAULT_ROOT" "${HELPER}"
    grep -q "not a semantic contract" "${HELPER}"
    grep -q "AI_PROMPT_CATALOG" "${HELPER}"
}

@test "ai-prompt list shows the supported catalog" {
    run bash "${AI_PROMPT_LAUNCHER}" list
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == $'understand-context\nplan-safe-change\ndetect-errors\nsummarize-repo\nreview-diff\nwrite-commit-message\ndesign-test-cases' ]]
}

@test "ai-prompt show understand-context prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show understand-context
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Understand Context"* ]]
}

@test "ai-prompt show plan-safe-change prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show plan-safe-change
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Plan Safe Change"* ]]
}

@test "ai-prompt show detect-errors prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show detect-errors
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Detect Errors"* ]]
}

@test "ai-prompt path prints the resolved markdown path" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" path detect-errors
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${VAULT_ROOT}/agents/prompts/detect-errors.md" ]]
}

@test "ai-prompt show rejects unsupported prompt ids clearly" {
    run bash "${AI_PROMPT_LAUNCHER}" show no-such-prompt
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Unsupported prompt id: no-such-prompt"* ]]
    [[ "${output}" == *"Supported prompt ids:"* ]]
}

@test "ai-prompt render without extras returns the canonical prompt" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Summarize Repo"* ]]
    [[ "${output}" != *"## Additional Context"* ]]
}

@test "ai-prompt render with context file appends file content" {
    local context_file="${TEST_TEMP_DIR}/context.md"
    cat > "${context_file}" <<'EOF'
Repository notes for render.
EOF

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --context-file "${context_file}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Summarize Repo"* ]]
    [[ "${output}" == *"## Additional Context"* ]]
    [[ "${output}" == *"### Context file: ${context_file}"* ]]
    [[ "${output}" == *"Repository notes for render."* ]]
}

@test "ai-prompt render with stdin appends piped content" {
    run bash -lc "printf 'Diff summary here\n' | AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render review-diff --stdin"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Review Diff"* ]]
    [[ "${output}" == *"### STDIN"* ]]
    [[ "${output}" == *"Diff summary here"* ]]
}

@test "ai-prompt render with git diff works inside a git repo" {
    local repo_path="${TEST_TEMP_DIR}/git_repo"
    create_git_repo "${repo_path}"
    echo "changed" >> "${repo_path}/file.txt"

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render write-commit-message --git-diff"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Write Commit Message"* ]]
    [[ "${output}" == *"### Git diff"* ]]
    [[ "${output}" == *"file.txt"* ]]
}

@test "ai-prompt render with git status works inside a git repo" {
    local repo_path="${TEST_TEMP_DIR}/git_repo"
    create_git_repo "${repo_path}"
    echo "changed" >> "${repo_path}/file.txt"

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render write-commit-message --git-status"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Write Commit Message"* ]]
    [[ "${output}" == *"### Git status"* ]]
    [[ "${output}" == *"M file.txt"* || "${output}" == *" M file.txt"* ]]
}

@test "ai-prompt render errors clearly for missing context file" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --context-file /tmp/no-existe
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Context file not found or not readable: /tmp/no-existe"* ]]
}

@test "ai-prompt render errors clearly for git diff outside a repo" {
    local outside_dir="${TEST_TEMP_DIR}/outside"
    mkdir -p "${outside_dir}"

    run bash -lc "cd '${outside_dir}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render review-diff --git-diff"
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Git context requested outside a git repository."* ]]
    [[ "${output}" == *"Current directory: ${outside_dir}"* ]]
}

@test "ai-prompt render errors clearly for git status outside a repo" {
    local outside_dir="${TEST_TEMP_DIR}/outside"
    mkdir -p "${outside_dir}"

    run bash -lc "cd '${outside_dir}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render review-diff --git-status"
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Git context requested outside a git repository."* ]]
    [[ "${output}" == *"Current directory: ${outside_dir}"* ]]
}

@test "ai-prompt show summarize-repo prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show summarize-repo
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Summarize Repo"* ]]
}

@test "ai-prompt show review-diff prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show review-diff
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Review Diff"* ]]
}

@test "ai-prompt show write-commit-message prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show write-commit-message
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Write Commit Message"* ]]
}

@test "ai-prompt show design-test-cases prints canonical prompt from env override" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" show design-test-cases
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Design Test Cases"* ]]
}

@test "ai-prompt check reports catalog state against the vault" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" check
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *$'ok\tunderstand-context\t'* ]]
    [[ "${output}" == *$'ok\tsummarize-repo\t'* ]]
    [[ "${output}" == *$'ok\tdesign-test-cases\t'* ]]
}

@test "ai-prompt check fails when a catalog prompt is missing from the vault" {
    rm -f "${PROMPTS_DIR}/review-diff.md"

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" check
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *$'missing\treview-diff\t'* ]]
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

@test "ai-prompt help shows the unified interface" {
    run bash "${AI_PROMPT_LAUNCHER}" help
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Usage: ai-prompt <command> [prompt-id]"* ]]
    [[ "${output}" == *"list"* ]]
    [[ "${output}" == *"show <prompt-id>"* ]]
    [[ "${output}" == *"render <prompt-id>"* ]]
}
