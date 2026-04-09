#!/usr/bin/env bash
# Shared helpers for prompt launchers backed by canonical markdown files in a vault.

set -euo pipefail

# Local/provisional default for this machine. This is not a semantic contract of the system.
DEFAULT_AI_PROMPTS_VAULT_ROOT="/mnt/c/Users/jesus/Documents/vault_trabajo"
AI_PROMPTS_RELATIVE_DIR="agents/prompts"
AI_PROMPT_CATALOG=(
    "understand-context"
    "plan-safe-change"
    "detect-errors"
)

ai_prompt_log_error() {
    printf '[prompt-launcher] %s\n' "$*" >&2
}

ai_prompt_resolved_vault_root() {
    printf '%s\n' "${AI_PROMPTS_VAULT_ROOT:-$DEFAULT_AI_PROMPTS_VAULT_ROOT}"
}

ai_prompt_list_supported() {
    printf '%s\n' "${AI_PROMPT_CATALOG[@]}"
}

ai_prompt_is_supported() {
    local prompt_name="$1"
    local supported_id

    for supported_id in "${AI_PROMPT_CATALOG[@]}"; do
        if [[ "$supported_id" == "$prompt_name" ]]; then
            return 0
        fi
    done

    return 1
}

ai_prompt_require_supported() {
    local prompt_name="$1"

    if ai_prompt_is_supported "$prompt_name"; then
        return 0
    fi

    ai_prompt_log_error "Unsupported prompt id: $prompt_name"
    ai_prompt_log_error "Supported prompt ids:"
    ai_prompt_list_supported | sed 's/^/[prompt-launcher]   - /' >&2
    return 1
}

ai_prompt_markdown_path() {
    local prompt_name="$1"
    local vault_root
    vault_root="$(ai_prompt_resolved_vault_root)"
    printf '%s/%s/%s.md\n' "$vault_root" "$AI_PROMPTS_RELATIVE_DIR" "$prompt_name"
}

ai_prompt_print() {
    local prompt_name="$1"
    local vault_root
    local prompt_path

    ai_prompt_require_supported "$prompt_name" || return 1

    vault_root="$(ai_prompt_resolved_vault_root)"
    prompt_path="$(ai_prompt_markdown_path "$prompt_name")"

    if [[ ! -d "$vault_root" ]]; then
        ai_prompt_log_error "Vault root not found."
        ai_prompt_log_error "Resolved vault root: $vault_root"
        ai_prompt_log_error "Prompt path attempted: $prompt_path"
        ai_prompt_log_error "Override with: AI_PROMPTS_VAULT_ROOT=/absolute/path/to/vault_trabajo"
        return 1
    fi

    if [[ ! -f "$prompt_path" ]]; then
        ai_prompt_log_error "Prompt markdown not found."
        ai_prompt_log_error "Resolved vault root: $vault_root"
        ai_prompt_log_error "Prompt path attempted: $prompt_path"
        ai_prompt_log_error "Override with: AI_PROMPTS_VAULT_ROOT=/absolute/path/to/vault_trabajo"
        return 1
    fi

    cat "$prompt_path"
}
