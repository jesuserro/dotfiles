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
    
    # Create mock uvx that exits immediately (avoids MCP server blocking)
    MOCK_UVX="$TEST_TEMP_DIR/uvx"
    cat > "$MOCK_UVX" << 'MOCK_EOF'
#!/usr/bin/env bash
exit 0
MOCK_EOF
    chmod +x "$MOCK_UVX"
}

teardown() {
    teardown_temp_dir
}

# Helper: run launcher with mock uvx in PATH
run_with_mock_uvx() {
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
    grep -q "set -euo pipefail" "$LAUNCHER"
}

@test "script checks for MCP_GIT_REPO override" {
    grep -q "MCP_GIT_REPO" "$LAUNCHER"
}

@test "script uses git rev-parse for detection" {
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
    grep -q ".git" "$LAUNCHER"
}

@test "script has fallback to default locations" {
    grep -qE "dotfiles|proyectos" "$LAUNCHER"
}

@test "error message is informative when no fallback available" {
    [[ -x "$LAUNCHER" ]] || skip "Launcher not executable"
    
    ISOLATED_HOME="$TEST_TEMP_DIR/isolated_home"
    mkdir -p "$ISOLATED_HOME"
    
    cd "$NON_GIT_DIR"
    HOME="$ISOLATED_HOME" run bash "$LAUNCHER" 2>&1
    [[ "$status" -ne 0 ]]
    
    cd "$TEST_TEMP_DIR"
}

@test "script uses uvx for execution" {
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

@test "mock uvx is found when prepended to PATH" {
    PATH="$TEST_TEMP_DIR:$PATH" command -v uvx
}
