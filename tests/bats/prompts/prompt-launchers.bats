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
    CLIPBOARD_STUB_DIR="${TEST_TEMP_DIR}/clipboard-bin"
    NO_CLIPBOARD_STUB_DIR="${TEST_TEMP_DIR}/no-clipboard-bin"
    MOCK_CLIPBOARD_FILE="${TEST_TEMP_DIR}/mock-clipboard.txt"
    mkdir -p "${PROMPTS_DIR}" "${CLIPBOARD_STUB_DIR}" "${NO_CLIPBOARD_STUB_DIR}"

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

    cat > "${CLIPBOARD_STUB_DIR}/pbcopy" <<'EOF'
#!/usr/bin/env bash
cat > "${MOCK_CLIPBOARD_FILE}"
EOF
    chmod +x "${CLIPBOARD_STUB_DIR}/pbcopy"

    ln -s /usr/bin/cat "${NO_CLIPBOARD_STUB_DIR}/cat"
    ln -s /usr/bin/dirname "${NO_CLIPBOARD_STUB_DIR}/dirname"
    ln -s /usr/bin/mktemp "${NO_CLIPBOARD_STUB_DIR}/mktemp"
    ln -s /usr/bin/python3 "${NO_CLIPBOARD_STUB_DIR}/python3"
    ln -s /usr/bin/rm "${NO_CLIPBOARD_STUB_DIR}/rm"
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

@test "ai-prompt show --copy uses the detected clipboard backend and still prints stdout" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" MOCK_CLIPBOARD_FILE="${MOCK_CLIPBOARD_FILE}" PATH="${CLIPBOARD_STUB_DIR}:$PATH" bash "${AI_PROMPT_LAUNCHER}" show review-diff --copy
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Review Diff"* ]]

    run grep -q "# Review Diff" "${MOCK_CLIPBOARD_FILE}"
    [[ "${status}" -eq 0 ]]
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

@test "ai-prompt render with stdin errors clearly when no input is provided" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render review-diff --stdin
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"STDIN requested but no stdin pipe or redirection was provided."* || "${output}" == *"STDIN requested but no input was received."* ]]
    [[ "${output}" == *"printf 'text"* ]]
}

@test "ai-prompt render --copy uses the detected clipboard backend and still prints stdout" {
    run bash -lc "printf 'Diff summary here\n' | AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' MOCK_CLIPBOARD_FILE='${MOCK_CLIPBOARD_FILE}' PATH='${CLIPBOARD_STUB_DIR}:$PATH' '${AI_PROMPT_LAUNCHER}' render review-diff --stdin --copy"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Review Diff"* ]]
    [[ "${output}" == *"Diff summary here"* ]]

    run grep -q "Diff summary here" "${MOCK_CLIPBOARD_FILE}"
    [[ "${status}" -eq 0 ]]
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

@test "ai-prompt render still writes to stdout by default" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render review-diff --stdin <<'EOF'
Small diff summary
EOF
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Review Diff"* ]]
    [[ "${output}" == *"Small diff summary"* ]]
}

@test "ai-prompt render output-file writes the rendered prompt to disk" {
    local output_file="${TEST_TEMP_DIR}/nested/output/prompt.md"

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --context-file "${DOTFILES_DIR}/README.md" --output-file "${output_file}"
    [[ "${status}" -eq 0 ]]
    [[ -f "${output_file}" ]]
    [[ -z "${output}" ]]

    run grep -q "# Summarize Repo" "${output_file}"
    [[ "${status}" -eq 0 ]]
}

@test "ai-prompt render output-temp creates a temporary file" {
    run bash -lc "printf 'Small diff summary\n' | AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render review-diff --stdin --output-temp --print-output-path"
    [[ "${status}" -eq 0 ]]
    [[ -f "${output}" ]]

    run grep -q "Small diff summary" "${output}"
    [[ "${status}" -eq 0 ]]
}

@test "ai-prompt render print-output-path returns the explicit output file path" {
    local output_file="${TEST_TEMP_DIR}/prompt.md"

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --output-file "${output_file}" --print-output-path
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${output_file}" ]]
    [[ -f "${output_file}" ]]
}

@test "ai-prompt render output file content matches the rendered prompt" {
    local output_file="${TEST_TEMP_DIR}/rendered.md"

    run bash -lc "printf 'Small diff summary\n' | AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' render review-diff --stdin --output-file '${output_file}'"
    [[ "${status}" -eq 0 ]]

    run grep -q "# Review Diff" "${output_file}"
    [[ "${status}" -eq 0 ]]
    run grep -q "Small diff summary" "${output_file}"
    [[ "${status}" -eq 0 ]]
}

@test "ai-prompt render errors clearly when output file cannot be written" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --output-file /proc/forbidden.md
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Failed to write output file: /proc/forbidden.md"* || "${output}" == *"Failed to create output directory for: /proc/forbidden.md"* ]]
}

@test "ai-prompt render rejects conflicting output modes" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --output-file /tmp/a.md --output-temp
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Choose only one output mode: --output-file or --output-temp."* ]]
}

@test "ai-prompt render rejects print-output-path without a file output mode" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" bash "${AI_PROMPT_LAUNCHER}" render summarize-repo --print-output-path
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"--print-output-path requires --output-file or --output-temp."* ]]
}

@test "ai-prompt task review-diff works inside a git repo" {
    local repo_path="${TEST_TEMP_DIR}/git_repo"
    create_git_repo "${repo_path}"
    echo "changed" >> "${repo_path}/file.txt"

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task review-diff"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Review Diff"* ]]
    [[ "${output}" == *"### Git diff"* ]]
    [[ "${output}" == *"### Git status"* ]]
}

@test "ai-prompt task write-commit-message works inside a git repo" {
    local repo_path="${TEST_TEMP_DIR}/git_repo"
    create_git_repo "${repo_path}"
    echo "changed" >> "${repo_path}/file.txt"

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task write-commit-message"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Write Commit Message"* ]]
    [[ "${output}" == *"### Git diff"* ]]
    [[ "${output}" == *"### Git status"* ]]
}

@test "ai-prompt task summarize-repo uses README when present" {
    local repo_path="${TEST_TEMP_DIR}/repo_with_readme"
    mkdir -p "${repo_path}"
    cat > "${repo_path}/README.md" <<'EOF'
Test README content.
EOF

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task summarize-repo"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Summarize Repo"* ]]
    [[ "${output}" == *"### Context file: README.md"* ]]
    [[ "${output}" == *"Test README content."* ]]
}

@test "ai-prompt task summarize-repo works without README" {
    local repo_path="${TEST_TEMP_DIR}/repo_without_readme"
    mkdir -p "${repo_path}"

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task summarize-repo"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Summarize Repo"* ]]
    [[ "${output}" != *"### Context file: README.md"* ]]
}

@test "ai-prompt task errors clearly for unknown task" {
    run bash "${AI_PROMPT_LAUNCHER}" task no-such-task
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Unknown task: no-such-task"* ]]
    [[ "${output}" == *"ai-prompt task help"* ]]
}

@test "ai-prompt task review-diff fails clearly outside a git repo" {
    local outside_dir="${TEST_TEMP_DIR}/outside"
    mkdir -p "${outside_dir}"

    run bash -lc "cd '${outside_dir}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task review-diff"
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Git context requested outside a git repository."* ]]
}

@test "ai-prompt task write-commit-message fails clearly outside a git repo" {
    local outside_dir="${TEST_TEMP_DIR}/outside"
    mkdir -p "${outside_dir}"

    run bash -lc "cd '${outside_dir}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task write-commit-message"
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Git context requested outside a git repository."* ]]
}

@test "ai-prompt task supports output flags" {
    local repo_path="${TEST_TEMP_DIR}/git_repo"
    create_git_repo "${repo_path}"
    echo "changed" >> "${repo_path}/file.txt"

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' '${AI_PROMPT_LAUNCHER}' task write-commit-message --output-temp --print-output-path"
    [[ "${status}" -eq 0 ]]
    [[ -f "${output}" ]]

    run grep -q "# Write Commit Message" "${output}"
    [[ "${status}" -eq 0 ]]
}

@test "ai-prompt task --copy uses the detected clipboard backend and still prints stdout" {
    local repo_path="${TEST_TEMP_DIR}/repo_with_readme"
    mkdir -p "${repo_path}"
    cat > "${repo_path}/README.md" <<'EOF'
Task README content.
EOF

    run bash -lc "cd '${repo_path}' && AI_PROMPTS_VAULT_ROOT='${VAULT_ROOT}' MOCK_CLIPBOARD_FILE='${MOCK_CLIPBOARD_FILE}' PATH='${CLIPBOARD_STUB_DIR}:$PATH' '${AI_PROMPT_LAUNCHER}' task summarize-repo --copy"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"# Summarize Repo"* ]]
    [[ "${output}" == *"Task README content."* ]]

    run grep -q "Task README content." "${MOCK_CLIPBOARD_FILE}"
    [[ "${status}" -eq 0 ]]
}

@test "ai-prompt task help shows available presets" {
    run bash "${AI_PROMPT_LAUNCHER}" task help
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"review-diff"* ]]
    [[ "${output}" == *"write-commit-message"* ]]
    [[ "${output}" == *"summarize-repo"* ]]
}

@test "ai-prompt task explain shows preset behavior" {
    run bash "${AI_PROMPT_LAUNCHER}" task review-diff --explain
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Task: review-diff"* ]]
    [[ "${output}" == *"--git-diff --git-status"* ]]
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

@test "ai-prompt copy fails clearly when no clipboard backend is available" {
    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" PATH="${NO_CLIPBOARD_STUB_DIR}" /usr/bin/bash "${AI_PROMPT_LAUNCHER}" show review-diff --copy
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"No clipboard backend was found."* ]]
    [[ "${output}" == *"Supported backends: pbcopy, wl-copy, xclip, xsel, clip.exe"* ]]
}

@test "ai-prompt copy fails clearly when clip.exe reports an error" {
    local error_stub_dir="${TEST_TEMP_DIR}/error-clipboard-bin"
    mkdir -p "${error_stub_dir}"
    cat > "${error_stub_dir}/clip.exe" <<'EOF'
#!/usr/bin/bash
cat >/dev/null
printf 'ERROR: clipboard unavailable\n' >&2
exit 0
EOF
    chmod +x "${error_stub_dir}/clip.exe"

    run env AI_PROMPTS_VAULT_ROOT="${VAULT_ROOT}" PATH="${error_stub_dir}:${NO_CLIPBOARD_STUB_DIR}" /usr/bin/bash "${AI_PROMPT_LAUNCHER}" show review-diff --copy
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Clipboard backend clip.exe reported an error."* ]]
    [[ "${output}" == *"ERROR: clipboard unavailable"* ]]
}

@test "ai-prompt help shows the unified interface" {
    run bash "${AI_PROMPT_LAUNCHER}" help
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Usage: ai-prompt <command> [prompt-id]"* ]]
    [[ "${output}" == *"list"* ]]
    [[ "${output}" == *"show <prompt-id>"* ]]
    [[ "${output}" == *"render <prompt-id>"* ]]
    [[ "${output}" == *"task <task-name>"* ]]
    [[ "${output}" == *"--copy"* ]]
}
