#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(get_dotfiles_dir)"
	GIT_FEAT="${DOTFILES_DIR}/scripts/git_feat.sh"
	GIT_REL="${DOTFILES_DIR}/scripts/git_rel.sh"
	POLICY_PRINT="${DOTFILES_DIR}/scripts/git_flow_policy_print.sh"
	POLICY_FILE="${DOTFILES_DIR}/.git-flow-policy.env"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

install_gh_stub() {
	local log="$1"
	local bin_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "$bin_dir"
	cat >"${bin_dir}/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_STUB_LOG"
printf 'https://github.com/example/repo/pull/1\n'
EOF
	chmod +x "${bin_dir}/gh"
	export GH_STUB_LOG="$log"
	export PATH="${bin_dir}:${PATH}"
}

init_feat_repo_with_remote() {
	local repo="$1"
	local remote="$2"
	git init -q --bare "$remote"
	mkdir -p "$repo"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "base" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -C "$repo" commit -q -m "initial"
	git -C "$repo" branch -M main
	git -C "$repo" checkout -q -b dev
	git -C "$repo" remote add origin "$remote"
	git -C "$repo" push -q origin main dev
	git -C "$repo" checkout -q -b feature/demo
	echo "feature" >"$repo/feature.txt"
	git -C "$repo" add feature.txt
	git -C "$repo" commit -q -m "feat: demo"
	git -C "$repo" push -q origin feature/demo
}

init_rel_repo() {
	local repo="$1"
	local remote="$2"
	git init -q --bare "$remote"
	mkdir -p "$repo"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "base" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -C "$repo" commit -q -m "initial"
	git -C "$repo" branch -M main
	git -C "$repo" checkout -q -b dev
	echo "dev change" >"$repo/dev.txt"
	git -C "$repo" add dev.txt
	git -C "$repo" commit -q -m "dev change"
	git -C "$repo" remote add origin "$remote"
	git -C "$repo" push -q origin main dev
}

@test "dotfiles .git-flow-policy.env parses successfully" {
	[[ -f "$POLICY_FILE" ]]
	run bash "$POLICY_PRINT" --policy-file "$POLICY_FILE"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV=pr"* ]]
	[[ "$output" == *"FLOW_MODE_TO_MAIN=pr"* ]]
	[[ "$output" == *"VALIDATE_TO_DEV=true"* ]]
	[[ "$output" == *"VALIDATE_TO_MAIN=true"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_DEV=make agent-validate"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_MAIN=make agent-validate-full"* ]]
	[[ "$output" != *"pr_auto"* ]]
	[[ "$output" != *"pr_immediate"* ]]
}

@test "git_feat --print-policy reflects dotfiles policy" {
	cd "$DOTFILES_DIR"
	run bash "$GIT_FEAT" --print-policy
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV=pr"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_DEV=make agent-validate"* ]]
	[[ "$output" == *"DELETE_FEATURE_BRANCH=true"* ]]
}

@test "git_rel --print-policy reflects dotfiles policy" {
	cd "$DOTFILES_DIR"
	run bash "$GIT_REL" --print-policy
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_MAIN=pr"* ]]
	[[ "$output" == *"VALIDATE_CMD_TO_MAIN=make agent-validate-full"* ]]
	[[ "$output" == *"OPEN_BROWSER=false"* ]]
}

@test "git_feat --dry-run with dotfiles policy does not call gh" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-dotfiles-feat-dry.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cp "$POLICY_FILE" "${repo}/.git-flow-policy.env"
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: dotfiles policy"

	cd "$repo"
	run bash "$GIT_FEAT" --dry-run demo
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git feat PR flow (pr)"* ]]
	[[ "$output" == *"Would create PR 'feature/demo' -> 'dev'"* ]]
	[[ "$output" == *"Would leave PR open for manual review"* ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_rel --dry-run with dotfiles policy does not call gh" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-dotfiles-rel-dry.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cp "$POLICY_FILE" "${repo}/.git-flow-policy.env"
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: dotfiles policy"

	cd "$repo"
	run bash "$GIT_REL" --dry-run
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git rel policy flow (pr)"* ]]
	[[ "$output" == *"Would create PR 'dev' -> 'main'"* ]]
	[[ "$output" == *"Would leave PR open for manual review"* ]]
	[[ ! -s "$gh_log" ]]
}
