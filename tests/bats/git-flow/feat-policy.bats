#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(get_dotfiles_dir)"
	GIT_FEAT="${DOTFILES_DIR}/scripts/git_feat.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

expected_defaults() {
	cat <<'EOF'
FLOW_MODE_TO_DEV=local
FLOW_MODE_TO_MAIN=local
VALIDATE_TO_DEV=false
VALIDATE_TO_MAIN=false
VALIDATE_CMD_TO_DEV=make validate
VALIDATE_CMD_TO_MAIN=make validate-full
MERGE_STRATEGY_TO_DEV=merge
MERGE_STRATEGY_TO_MAIN=merge
DELETE_FEATURE_BRANCH=true
OPEN_BROWSER=true
REMOTE_NAME=origin
BASE_DEV_BRANCH=dev
BASE_MAIN_BRANCH=main
FEATURE_BRANCH_PREFIX=feature/
EOF
}

init_feat_repo() {
	local repo="$1"
	mkdir -p "$repo"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "base" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -C "$repo" commit -q -m "initial"
	git -C "$repo" checkout -q -b dev
	git -C "$repo" checkout -q -b feature/demo
	echo "feature" >"$repo/feature.txt"
	git -C "$repo" add feature.txt
	git -C "$repo" commit -q -m "feat: demo"
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

@test "git_feat --print-policy prints defaults without Git operations" {
	cd "$TEST_TEMP_DIR"
	run bash "$GIT_FEAT" --print-policy
	[[ "$status" -eq 0 ]]
	[[ "$output" == "$(expected_defaults)" ]]
}

@test "git_feat invalid policy fails before repository validation" {
	cat >"${TEST_TEMP_DIR}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=banana
EOF

	cd "$TEST_TEMP_DIR"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV"* ]]
	[[ "$output" == *"banana"* ]]
	[[ "$output" != *"No estás dentro de un repositorio Git"* ]]
}

@test "git_feat PR mode is explicit and not implemented yet" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_feat_repo "$repo"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr
EOF

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"PR mode not implemented yet"* ]]
	[[ "$output" == *"FLOW_MODE_TO_DEV=pr"* ]]
}

@test "git_feat validation command runs from repo root and aborts before merge" {
	local repo="${TEST_TEMP_DIR}/repo"
	local validation_log="${TEST_TEMP_DIR}/feat-validation.log"
	init_feat_repo "$repo"
	cat >"${repo}/.git-flow-policy.env" <<EOF
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="pwd > '${validation_log}'; exit 42"
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add git flow policy"
	mkdir -p "${repo}/subdir"

	cd "${repo}/subdir"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	[[ "$(cat "$validation_log")" == "$repo" ]]
	[[ "$output" == *"Running validation:"* ]]
	[[ "$output" == *"Validation failed:"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
}

@test "git_feat uses configured dev branch and feature prefix before validation" {
	local repo="${TEST_TEMP_DIR}/repo"
	local validation_log="${TEST_TEMP_DIR}/feat-policy-branch.log"
	mkdir -p "$repo"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "base" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -C "$repo" commit -q -m "initial"
	git -C "$repo" checkout -q -b integration
	git -C "$repo" checkout -q -b topic/demo
	echo "topic" >"$repo/topic.txt"
	git -C "$repo" add topic.txt
	git -C "$repo" commit -q -m "feat: topic"
	cat >"${repo}/.git-flow-policy.env" <<EOF
BASE_DEV_BRANCH=integration
FEATURE_BRANCH_PREFIX=topic/
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="printf validated > '${validation_log}'; exit 42"
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add git flow policy"
	mkdir -p "${repo}/subdir"

	cd "${repo}/subdir"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	[[ "$(cat "$validation_log")" == "validated" ]]
	[[ "$output" == *"Integrando feature 'demo' en integration"* ]]
	[[ "$output" != *"ni 'feature/demo' existe"* ]]
}

@test "git_feat default policy archives the feature branch after merge" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"

	cd "$repo"
	run bash -c "printf 's\n' | '${GIT_FEAT}' --no-changelog demo"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Rama archivada como 'archive/feature/demo'"* ]]
	git show-ref --verify --quiet refs/heads/archive/feature/demo
	run git show-ref --verify --quiet refs/heads/feature/demo
	[[ "$status" -ne 0 ]]
	git ls-remote --exit-code --heads origin archive/feature/demo >/dev/null
}

@test "git_feat preserves feature branch when DELETE_FEATURE_BRANCH is false" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
DELETE_FEATURE_BRANCH=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: preserve feature branch"
	git -C "$repo" push -q origin feature/demo

	cd "$repo"
	run bash -c "printf 's\n' | '${GIT_FEAT}' --no-changelog demo"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"INFO: Feature branch preserved by policy: feature/demo"* ]]
	git show-ref --verify --quiet refs/heads/feature/demo
	run git show-ref --verify --quiet refs/heads/archive/feature/demo
	[[ "$status" -ne 0 ]]
	git ls-remote --exit-code --heads origin feature/demo >/dev/null
	run git ls-remote --exit-code --heads origin archive/feature/demo
	[[ "$status" -ne 0 ]]
}
