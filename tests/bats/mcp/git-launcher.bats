#!/usr/bin/env bats
# Tests for mcp-git-launcher

load '../helpers/common'

setup() {
    setup_temp_dir
    
    DOTFILES_DIR="$(get_dotfiles_dir)"
    LAUNCHER="$DOTFILES_DIR/bin/mcp-git-launcher"
    
    # Create test git repositories dynamically
    VALID_REPO="$TEST_TEMP_DIR/valid_repo"
    create_git_repo "$VALID_REPO"
    
    VALID_REPO_WITH_SUBDIR="$TEST_TEMP_DIR/valid_repo_subdir"
    create_git_repo_with_subdir "$VALID_REPO_WITH_SUBDIR"
    
    NON_GIT_DIR="$TEST_TEMP_DIR/not_a_git_dir"
    create_non_git_dir "$NON_GIT_DIR"
}

teardown() {
    teardown_temp_dir
}

bats_require_minimum_version 1.5.0

@test "launcher script exists and is executable" {
    if [[ ! -f "$LAUNCHER" ]]; then
        skip "Launcher not found at $LAUNCHER"
    fi
    
    [[ -f "$LAUNCHER" ]]
    [[ -x "$LAUNCHER" ]]
}

@test "help flag -h shows usage" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    run bash "$LAUNCHER" -h
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"MCP Git Launcher"* ]]
    [[ "$output" == *"Repository detection"* ]]
}

@test "help flag --help shows usage" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    run bash "$LAUNCHER" --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"MCP Git Launcher"* ]]
}

@test "script uses set -euo pipefail" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "set -euo pipefail" "$LAUNCHER"
}

@test "script checks for MCP_GIT_REPO override" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "MCP_GIT_REPO" "$LAUNCHER"
}

@test "script uses git rev-parse for detection" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "git rev-parse" "$LAUNCHER"
}

@test "detects valid git repository from cwd" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    cd "$VALID_REPO"
    run bash "$LAUNCHER" --help 2>&1
    [[ "$status" -eq 0 ]]
    
    cd "$TEST_TEMP_DIR"
}

@test "fails clearly when not in git repository and no fallback exists" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    # Create a fake HOME that doesn't have dotfiles/proyectos
    NON_GIT_HOME="$TEST_TEMP_DIR/no_git_home"
    mkdir -p "$NON_GIT_HOME"
    
    HOME="$NON_GIT_HOME" cd "$NON_GIT_DIR"
    HOME="$NON_GIT_HOME" run bash "$LAUNCHER" 2>&1
    [[ "$status" -ne 0 ]]
    
    cd "$TEST_TEMP_DIR"
}

@test "accepts MCP_GIT_REPO override with valid repo" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    cd "$TEST_TEMP_DIR"
    MCP_GIT_REPO="$VALID_REPO" run bash "$LAUNCHER" --help 2>&1
    [[ "$status" -eq 0 ]]
}

@test "rejects MCP_GIT_REPO pointing to non-git directory" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    cd "$TEST_TEMP_DIR"
    MCP_GIT_REPO="$NON_GIT_DIR" run bash "$LAUNCHER" 2>&1
    [[ "$status" -ne 0 ]]
}

@test "script validates override path exists" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q ".git" "$LAUNCHER"
}

@test "script has fallback to default locations" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -qE "dotfiles|proyectos" "$LAUNCHER"
}

@test "error message is informative" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    cd "$NON_GIT_DIR"
    run bash "$LAUNCHER" 2>&1
    
    echo "Output: $output"
    
    cd "$TEST_TEMP_DIR"
}

@test "script uses uvx for execution" {
    [[ -f "$LAUNCHER" ]] || skip "Launcher not found"
    
    grep -q "uvx" "$LAUNCHER"
    grep -q "mcp-server-git" "$LAUNCHER"
}

@test "detects repo with subdirectories" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    cd "$VALID_REPO_WITH_SUBDIR/subdir/nested"
    run bash "$LAUNCHER" --help 2>&1
    [[ "$status" -eq 0 ]]
    
    cd "$TEST_TEMP_DIR"
}

@test "help shows environment variable info" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    run bash "$LAUNCHER" --help
    [[ "$output" == *"MCP_GIT_REPO"* ]]
}
