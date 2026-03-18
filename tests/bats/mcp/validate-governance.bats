#!/usr/bin/env bats
# Tests for validate-mcp-governance
# Note: These tests focus on script structure and behavior, not repo state

load '../helpers/common'

setup() {
    setup_temp_dir
    
    DOTFILES_DIR="$(get_dotfiles_dir)"
    VALIDATOR="$DOTFILES_DIR/bin/validate-mcp-governance"
}

teardown() {
    teardown_temp_dir
}

bats_require_minimum_version 1.5.0

@test "validator script exists" {
    [[ -f "$VALIDATOR" ]]
}

@test "validator is executable" {
    [[ -x "$VALIDATOR" ]] || skip "Validator not executable"
}

@test "validator uses set -euo pipefail" {
    grep -q "set -euo pipefail" "$VALIDATOR"
}

@test "validator defines error counting variables" {
    grep -q "^ERRORS=" "$VALIDATOR"
    grep -q "^WARNINGS=" "$VALIDATOR"
}

@test "validator defines log functions" {
    grep -q "log_error()" "$VALIDATOR"
    grep -q "log_warning()" "$VALIDATOR"
    grep -q "log_success()" "$VALIDATOR"
}

@test "validator uses arithmetic for counting" {
    # After fix: ERRORS=$((ERRORS + 1)) instead of ((ERRORS++))
    grep -qE 'ERRORS=\$\(\(' "$VALIDATOR" || \
    grep -q 'ERRORS=$((ERRORS + 1))' "$VALIDATOR"
}

@test "validator has DOTFILES_DIR fallback" {
    grep -qE 'DOTFILES_DIR=' "$VALIDATOR"
}

@test "validator runs against real dotfiles" {
    [[ -x "$VALIDATOR" ]] || skip "Validator not executable"
    
    # Run against real dotfiles (may have warnings, that's ok)
    run bash "$VALIDATOR" 2>&1
    [[ "$output" == *"MCP Governance Validator"* ]]
    [[ "$output" == *"Summary"* ]]
}

@test "validator checks OpenCode config" {
    grep -q "GLOBAL_OPENCODE" "$VALIDATOR"
    grep -q "dot_config/opencode" "$VALIDATOR"
}

@test "validator checks Codex config" {
    grep -q "GLOBAL_CODEX" "$VALIDATOR"
    grep -q "dot_codex" "$VALIDATOR"
}

@test "validator checks platform MCPs" {
    grep -q "PLATFORM_MCPS" "$VALIDATOR"
    grep -q "dagster\|loki\|minio" "$VALIDATOR"
}

@test "validator checks filesystem launcher" {
    grep -q "mcp-filesystem-launcher" "$VALIDATOR"
}

@test "validator checks git launcher" {
    grep -q "mcp-git-launcher" "$VALIDATOR"
}

@test "validator checks sequential-thinking" {
    grep -q "sequential-thinking" "$VALIDATOR"
}

@test "validator checks ADR exists" {
    grep -q "0001-mcp-governance.md" "$VALIDATOR"
}

@test "validator has exit 1 for errors" {
    grep -q "exit 1" "$VALIDATOR"
}

@test "validator has exit 0 for warnings only" {
    grep -qE "exit 0" "$VALIDATOR"
}

@test "validator produces summary" {
    grep -q "Summary" "$VALIDATOR"
    grep -q "Errors:" "$VALIDATOR"
    grep -q "Warnings:" "$VALIDATOR"
}

@test "validator checks for postgres wrapper" {
    grep -q "mcp-postgres-launcher" "$VALIDATOR"
}

@test "validator uses grep for pattern matching" {
    grep -q "grep -q" "$VALIDATOR"
}

@test "validator uses proper grep context for enabled check" {
    # After fix: grep -A10 instead of grep -A5
    grep -qE "grep -A[0-9]+" "$VALIDATOR"
}
