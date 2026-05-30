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
	echo "initial" >"$repo_path/file.txt"
	git -C "$repo_path" add file.txt
	git -C "$repo_path" commit -q -m "initial"
}

create_git_repo_with_subdir() {
	local repo_path="$1"
	create_git_repo "$repo_path"
	mkdir -p "$repo_path/subdir/nested"
	echo "nested content" >"$repo_path/subdir/nested/file.txt"
	git -C "$repo_path" add subdir
	git -C "$repo_path" commit -q -m "add subdir"
}

create_non_git_dir() {
	local dir_path="$1"
	mkdir -p "$dir_path"
	echo "not a repo" >"$dir_path/file.txt"
}

mock_git_globally() {
	local mock_git="$1"
	cat >"$mock_git" <<'EOF'
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
	if [[ -n "${DOTFILES_DIR:-}" && -f "${DOTFILES_DIR}/tests/Makefile.tests" ]]; then
		echo "${DOTFILES_DIR}"
		return
	fi

	local start="${BATS_TEST_DIRNAME:-$(dirname "${BATS_FILENAME:-.}")}"

	if command -v git &>/dev/null; then
		local top
		top="$(git -C "$start" rev-parse --show-toplevel 2>/dev/null || true)"
		if [[ -n "$top" && -f "$top/tests/Makefile.tests" ]]; then
			echo "$top"
			return
		fi
	fi

	local dir="$start"
	while [[ "$dir" != "/" ]]; do
		if [[ -f "$dir/tests/Makefile.tests" ]]; then
			echo "$dir"
			return
		fi
		dir="$(dirname "$dir")"
	done

	if [[ -d "$HOME/dotfiles/.git" ]]; then
		echo "$HOME/dotfiles"
		return
	fi

	echo "${start}/../.."
}

skip_if_command_missing() {
	local cmd="$1"
	if ! command -v "$cmd" &>/dev/null; then
		skip "$cmd not installed"
	fi
}

assert_fail() {
	printf '%s\n' "$*" >&2
	return 1
}

assert_file_contains() {
	local file="$1"
	local pattern="$2"
	local output status
	set +e
	output="$(grep -n -- "$pattern" "$file" 2>&1)"
	status=$?
	set -e
	if [[ "$status" -ne 0 ]]; then
		assert_fail "Expected file '$file' to contain '$pattern'; grep status ${status}: ${output}"
	fi
}

assert_file_not_contains() {
	local file="$1"
	local pattern="$2"
	local output status
	[[ -e "$file" ]] || return 0
	set +e
	output="$(grep -n -- "$pattern" "$file" 2>&1)"
	status=$?
	set -e
	if [[ "$status" -eq 0 ]]; then
		assert_fail "Expected file '$file' NOT to contain '$pattern', but found: ${output}"
	elif [[ "$status" -ne 1 ]]; then
		assert_fail "Could not search file '$file' for '$pattern'; grep status ${status}: ${output}"
	fi
}

assert_file_not_matches() {
	local file="$1"
	local regex="$2"
	local output status
	[[ -e "$file" ]] || return 0
	set +e
	output="$(grep -En -- "$regex" "$file" 2>&1)"
	status=$?
	set -e
	if [[ "$status" -eq 0 ]]; then
		assert_fail "Expected file '$file' NOT to match regex '$regex', but found: ${output}"
	elif [[ "$status" -ne 1 ]]; then
		assert_fail "Could not search file '$file' for regex '$regex'; grep status ${status}: ${output}"
	fi
}

assert_tree_not_matches() {
	local regex="$1"
	shift
	local output status
	set +e
	output="$(grep -Rni -- "$regex" "$@" 2>&1)"
	status=$?
	set -e
	if [[ "$status" -eq 0 ]]; then
		assert_fail "Expected paths NOT to match regex '$regex', but found: ${output}"
	elif [[ "$status" -ne 1 ]]; then
		assert_fail "Could not recursively search for regex '$regex'; grep status ${status}: ${output}"
	fi
}

assert_find_no_results() {
	local description="$1"
	shift
	local output status
	set +e
	output="$(find "$@" -print 2>&1)"
	status=$?
	set -e
	if [[ "$status" -ne 0 ]]; then
		assert_fail "Find failed while checking '${description}'; status ${status}: ${output}"
	fi
	if [[ -n "$output" ]]; then
		assert_fail "Expected no results for '${description}', but found: ${output}"
	fi
}

assert_find_output_not_matches() {
	local description="$1"
	local regex="$2"
	shift 2
	local output status
	set +e
	output="$(find "$@" -print 2>&1)"
	status=$?
	set -e
	if [[ "$status" -ne 0 ]]; then
		assert_fail "Find failed while checking '${description}'; status ${status}: ${output}"
	fi
	if printf '%s\n' "$output" | grep -Eq -- "$regex"; then
		assert_fail "Expected find output for '${description}' NOT to match regex '$regex', but found: ${output}"
	fi
}
