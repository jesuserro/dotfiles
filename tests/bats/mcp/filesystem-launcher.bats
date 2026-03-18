#!/usr/bin/env bats
# Tests for mcp-filesystem-launcher

load '../helpers/common'

setup() {
    setup_temp_dir
    
    DOTFILES_DIR="$(get_dotfiles_dir)"
    LAUNCHER="$DOTFILES_DIR/bin/mcp-filesystem-launcher"
    
    # Create mock directories for testing
    MOCK_ROOT="$TEST_TEMP_DIR/mock_root"
    mkdir -p "$MOCK_ROOT/allowed_dir"
    mkdir -p "$MOCK_ROOT/allowed_subdir/deep/nested"
    
    # Create mock npx that exits immediately (avoids MCP server blocking)
    MOCK_NPX="$TEST_TEMP_DIR/npx"
    cat > "$MOCK_NPX" << 'MOCK_EOF'
#!/usr/bin/env bash
exit 0
MOCK_EOF
    chmod +x "$MOCK_NPX"
}

teardown() {
    teardown_temp_dir
}

# Helper: run launcher with mock npx in PATH
run_with_mock_npx() {
    PATH="$TEST_TEMP_DIR:$PATH" bash "$LAUNCHER" "$@" 2>&1
}

bats_require_minimum_version 1.5.0

@test "launcher script exists and is executable" {
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
    grep -q "set -euo pipefail" "$LAUNCHER"
}

@test "script defines allowed roots" {
    grep -q "ALLOWED_ROOTS" "$LAUNCHER"
    grep -q "/home/jesus/dotfiles" "$LAUNCHER"
    grep -q "/home/jesus/proyectos" "$LAUNCHER"
    grep -q "/home/jesus/.config" "$LAUNCHER"
    grep -q "/mnt/c/Users/jesus/Documents/vault" "$LAUNCHER"
}

@test "realpath is used for path resolution" {
    grep -q "realpath" "$LAUNCHER"
}

@test "script uses npx for execution" {
    grep -q "npx" "$LAUNCHER"
}

@test "script handles non-resolvable paths with warning" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    # Uses mock npx to avoid blocking
    run run_with_mock_npx /nonexistent/path
    [[ "$output" == *"WARNING"* ]]
}

@test "whitelist check uses proper directory boundary" {
    grep -qE '== "\$root" /' "$LAUNCHER" || \
    grep -qE '== "\$root"/' "$LAUNCHER" || \
    grep -qE '\$root"/' "$LAUNCHER"
}

@test "ALLOWED_ROOTS is an array" {
    grep -q "ALLOWED_ROOTS=" "$LAUNCHER"
    grep -q '()' "$LAUNCHER" || grep -q "=(" "$LAUNCHER"
}

@test "script iterates over allowed roots" {
    grep -q 'for root in' "$LAUNCHER"
}

@test "script adds additional paths to allowed list" {
    grep -q "ALL_PATHS" "$LAUNCHER"
    grep -qE '\+\=' "$LAUNCHER" || grep -q "+=(" "$LAUNCHER"
}

@test "script checks for is_allowed flag" {
    grep -q "is_allowed" "$LAUNCHER"
}

@test "help message lists all allowed roots" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    run bash "$LAUNCHER" --help
    [[ "$output" == *"/home/jesus/dotfiles"* ]]
    [[ "$output" == *"/home/jesus/proyectos"* ]]
    [[ "$output" == *"/home/jesus/.config"* ]]
    [[ "$output" == *"/mnt/c/Users/jesus/Documents/vault"* ]]
}

@test "exec is used for final command" {
    grep -q "^exec " "$LAUNCHER"
}

@test "mock npx is found when prepended to PATH" {
    PATH="$TEST_TEMP_DIR:$PATH" command -v npx
}
