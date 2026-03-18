#!/usr/bin/env bats
# Tests for mcp-filesystem-launcher

load '../helpers/common'

setup() {
    setup_temp_dir
    
    DOTFILES_DIR="$(get_dotfiles_dir)"
    LAUNCHER="$DOTFILES_DIR/bin/mcp-filesystem-launcher"
    
    # Create mock directories
    MOCK_ROOT="$TEST_TEMP_DIR/mock_root"
    mkdir -p "$MOCK_ROOT/allowed_dir"
    mkdir -p "$MOCK_ROOT/allowed_subdir/deep/nested"
    mkdir -p "$MOCK_ROOT/fake_prefix_issue"
    mkdir -p "$MOCK_ROOT/real_allowed"
}

teardown() {
    teardown_temp_dir
}

bats_require_minimum_version 1.5.0

@test "launcher script exists and is executable" {
    if [[ ! -x "$LAUNCHER" ]]; then
        skip "Launcher not found or not executable at $LAUNCHER"
    fi
    
    [[ -f "$LAUNCHER" ]]
    [[ -x "$LAUNCHER" ]]
}

@test "help flag -h shows usage" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    run bash "$LAUNCHER" -h
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"MCP Filesystem Launcher"* ]]
    [[ "$output" == *"Allowed roots"* ]]
}

@test "help flag --help shows usage" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    run bash "$LAUNCHER" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"MCP Filesystem Launcher"* ]]
}

@test "script uses set -euo pipefail" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "set -euo pipefail" "$LAUNCHER"
}

@test "script defines allowed roots" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "ALLOWED_ROOTS" "$LAUNCHER"
    grep -q "/home/jesus/dotfiles" "$LAUNCHER"
    grep -q "/home/jesus/proyectos" "$LAUNCHER"
    grep -q "/home/jesus/.config" "$LAUNCHER"
    grep -q "/mnt/c/Users/jesus/Documents/vault" "$LAUNCHER"
}

@test "realpath is used for path resolution" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "realpath" "$LAUNCHER"
}

@test "script uses npx for execution" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "npx" "$LAUNCHER"
}

@test "script handles non-resolvable paths with warning" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    run bash "$LAUNCHER" /nonexistent/path 2>&1
    [[ "$output" == *"WARNING"* ]]
}

@test "whitelist check uses proper directory boundary" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    # The script should have proper prefix matching (require / after root)
    grep -qE '== "\$root" /' "$LAUNCHER" || \
    grep -qE '== "\$root"/' "$LAUNCHER" || \
    grep -qE '\$root"/' "$LAUNCHER"
}

@test "ALLOWED_ROOTS is an array" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "ALLOWED_ROOTS=" "$LAUNCHER"
    grep -q '()' "$LAUNCHER" || grep -q "=(" "$LAUNCHER"
}

@test "script iterates over allowed roots" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q 'for root in' "$LAUNCHER"
}

@test "script adds additional paths to allowed list" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "ALL_PATHS" "$LAUNCHER"
    grep -qE '\+\=' "$LAUNCHER" || grep -q "+=(" "$LAUNCHER"
}

@test "script checks for is_allowed flag" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "is_allowed" "$LAUNCHER"
}

@test "help message lists all allowed roots" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    run bash "$LAUNCHER" --help
    [[ "$output" == *"/home/jesus/dotfiles"* ]]
    [[ "$output" == *"/home/jesus/proyectos"* ]]
    [[ "$output" == *"/home/jesus/.config"* ]]
    [[ "$output" == *"/mnt/c/Users/jesus/Documents/vault"* ]]
}

@test "exec is used for final command" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "^exec " "$LAUNCHER"
}
