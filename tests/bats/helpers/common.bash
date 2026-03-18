#!/usr/bin/env bash
# Common helpers for bats tests
# Source this file from your test files: load '../helpers/common'

setup_temp_dir() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
}

teardown_temp_dir() {
    if [[ -n "$TEST_TEMP_DIR" && -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

create_git_repo() {
    local repo_path="$1"
    mkdir -p "$repo_path"
    git init -q "$repo_path"
    git -C "$repo_path" config user.email "test@example.com"
    git -C "$repo_path" config user.name "Test User"
    echo "initial" > "$repo_path/file.txt"
    git -C "$repo_path" add file.txt
    git -C "$repo_path" commit -q -m "initial"
}

create_git_repo_with_subdir() {
    local repo_path="$1"
    create_git_repo "$repo_path"
    mkdir -p "$repo_path/subdir/nested"
    echo "nested content" > "$repo_path/subdir/nested/file.txt"
    git -C "$repo_path" add subdir
    git -C "$repo_path" commit -q -m "add subdir"
}

create_non_git_dir() {
    local dir_path="$1"
    mkdir -p "$dir_path"
    echo "not a repo" > "$dir_path/file.txt"
}

mock_git_globally() {
    local mock_git="$1"
    cat > "$mock_git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "rev-parse" ]]; then
    if [[ "$2" == "--show-toplevel" ]]; then
        echo "$MOCK_GIT_REPO"
    elif [[ "$2" == "--is-inside-work-tree" ]]; then
        if [[ -n "$MOCK_GIT_REPO" ]]; then
            exit 0
        else
            exit 1
        fi
    elif [[ "$2" == "--verify" ]]; then
        if [[ -d "$MOCK_GIT_REPO/.git" ]]; then
            echo "$MOCK_GIT_REPO"
        else
            exit 1
        fi
    else
        exit 1
    fi
elif [[ "$1" == "log" ]]; then
    exit 0
elif [[ "$1" == "diff" ]]; then
    exit 0
elif [[ "$1" == "rev-list" ]]; then
    exit 0
elif [[ "$1" == "branch" ]]; then
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$mock_git"
}

get_dotfiles_dir() {
    if [[ -d "$HOME/dotfiles/.git" ]]; then
        echo "$HOME/dotfiles"
    else
        echo "${BATS_TEST_DIRNAME:-$(dirname "${BATS_FILENAME:-.}")}/../.."
    fi
}

skip_if_command_missing() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        skip "$cmd not installed"
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    if ! grep -q "$pattern" "$file"; then
        flunk "Expected file '$file' to contain '$pattern'"
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    if grep -q "$pattern" "$file"; then
        flunk "Expected file '$file' NOT to contain '$pattern'"
    fi
}
