#!/usr/bin/env bats
set -euo pipefail

CLI_SCRIPT="${HOME}/dotfiles/scripts/git-set-ai-author.sh"
WRAPPER_SOURCE="${HOME}/dotfiles/local/bin/git-ai-wrapper"

GIT_REAL="${GIT_REAL:-/usr/bin/git}"
HUMAN_NAME="Jesús Erro"
HUMAN_EMAIL="olagato@gmail.com"

setup() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    "$GIT_REAL" init
    "$GIT_REAL" config user.name "Test User"
    "$GIT_REAL" config user.email "test@example.com"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

export GIT_REAL

get_author_file() {
    echo ".git/ai-author/current"
}

@test "passthrough: non-commit commands work" {
    export PATH="${HOME}/dotfiles/local/bin:$PATH"
    export GIT_REAL=/usr/bin/git
    
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    run "$wrapper" status
    [ "$status" -eq 0 ]
}

@test "commit without ai-author file uses default identity" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    echo "test content" > file.txt
    "$GIT_REAL" add file.txt
    
    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" || true
    
    run "$GIT_REAL" log --format="%an|%ae|%cn|%ce" -1
    [ "$status" -eq 0 ]
}

@test "commit with valid ai-author file sets author" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    local author_file
    author_file=$(get_author_file)
    mkdir -p "$(dirname "$author_file")"
    echo "Cursor Agent <cursor-agent@dotfiles.local>" > "$author_file"
    
    echo "test content" > file.txt
    "$GIT_REAL" add file.txt
    
    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" || true
    
    run "$GIT_REAL" log --format="%an|%ae" -1
    [[ "$output" == "Cursor Agent|cursor-agent@dotfiles.local" ]]
}

@test "commit with invalid ai-author file falls back to human identity" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    local author_file
    author_file=$(get_author_file)
    mkdir -p "$(dirname "$author_file")"
    echo "invalid-format-without-email" > "$author_file"
    
    echo "test content" > file.txt
    "$GIT_REAL" add file.txt
    
    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" || true
    
    run "$GIT_REAL" log --format="%an|%ae" -1
    [[ "$output" == "$HUMAN_NAME|$HUMAN_EMAIL" ]]
}

@test "commit with --author=value preserves author" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    echo "test content" > file.txt
    "$GIT_REAL" add file.txt
    
    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" --author="Custom Author <custom@example.com>" || true
    
    run "$GIT_REAL" log --format="%an|%ae" -1
    [[ "$output" == "Custom Author|custom@example.com" ]]
}

@test "commit with --author value (space) preserves author" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    echo "test content" > file.txt
    "$GIT_REAL" add file.txt
    
    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" --author "Space Author <space@example.com>" || true
    
    run "$GIT_REAL" log --format="%an|%ae" -1
    [[ "$output" == "Space Author|space@example.com" ]]
}

@test "git-set-ai-author cursor sets correct identity" {
    cp "$CLI_SCRIPT" "$TEST_DIR/git-set-ai-author"
    chmod +x "$TEST_DIR/git-set-ai-author"
    
    run "$TEST_DIR/git-set-ai-author" cursor
    [ "$status" -eq 0 ]
    
    local author_file
    author_file=$(get_author_file)
    run cat "$author_file"
    [[ "$output" == "Cursor Agent <cursor-agent@dotfiles.local>" ]]
}

@test "git-set-ai-author human clears identity" {
    cp "$CLI_SCRIPT" "$TEST_DIR/git-set-ai-author"
    chmod +x "$TEST_DIR/git-set-ai-author"
    
    "$TEST_DIR/git-set-ai-author" cursor
    
    run "$TEST_DIR/git-set-ai-author" human
    [ "$status" -eq 0 ]
    
    local author_file
    author_file=$(get_author_file)
    [ ! -f "$author_file" ]
}

@test "git-set-ai-author status shows current state" {
    cp "$CLI_SCRIPT" "$TEST_DIR/git-set-ai-author"
    chmod +x "$TEST_DIR/git-set-ai-author"
    
    run "$TEST_DIR/git-set-ai-author" status
    [ "$status" -eq 0 ]
    [[ "$output" == *"No AI author set"* ]]
    
    "$TEST_DIR/git-set-ai-author" cursor
    
    run "$TEST_DIR/git-set-ai-author" status
    [ "$status" -eq 0 ]
    [[ "$output" == *"Cursor Agent"* ]]
}

@test "git-set-ai-author list shows all agents" {
    cp "$CLI_SCRIPT" "$TEST_DIR/git-set-ai-author"
    chmod +x "$TEST_DIR/git-set-ai-author"
    
    run "$TEST_DIR/git-set-ai-author" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"cursor"* ]]
    [[ "$output" == *"codex"* ]]
    [[ "$output" == *"opencode"* ]]
    [[ "$output" == *"cursor-agent@dotfiles.local"* ]]
    [[ "$output" == *"codex-agent@dotfiles.local"* ]]
    [[ "$output" == *"opencode-agent@dotfiles.local"* ]]
}

@test "committer is always set to human identity" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"
    
    local author_file
    author_file=$(get_author_file)
    mkdir -p "$(dirname "$author_file")"
    echo "Cursor Agent <cursor-agent@dotfiles.local>" > "$author_file"
    
    echo "test content" > file.txt
    "$GIT_REAL" add file.txt
    
    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" || true
    
    run "$GIT_REAL" log --format="%cn|%ce" -1
    [[ "$output" == "$HUMAN_NAME|$HUMAN_EMAIL" ]]
}

@test "commit strips human --author so AI file still applies (Cursor Source Control)" {
    local wrapper="$TEST_DIR/git-wrapper"
    cp "$WRAPPER_SOURCE" "$wrapper"
    chmod +x "$wrapper"

    local author_file
    author_file=$(get_author_file)
    mkdir -p "$(dirname "$author_file")"
    echo "OpenCode Agent <opencode-agent@dotfiles.local>" > "$author_file"

    echo "test content" > file.txt
    "$GIT_REAL" add file.txt

    GIT_AUTHOR_NAME="" GIT_AUTHOR_EMAIL="" \
        GIT_COMMITTER_NAME="" GIT_COMMITTER_EMAIL="" \
        "$wrapper" commit -m "Test commit" --author "${HUMAN_NAME} <${HUMAN_EMAIL}>" || true

    run "$GIT_REAL" log --format="%an|%ae|%cn|%ce" -1
    [[ "$output" == "OpenCode Agent|opencode-agent@dotfiles.local|${HUMAN_NAME}|${HUMAN_EMAIL}" ]]
}
