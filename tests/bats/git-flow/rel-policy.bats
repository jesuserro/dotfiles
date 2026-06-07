#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(get_dotfiles_dir)"
	GIT_REL="${DOTFILES_DIR}/scripts/git_rel.sh"
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
	echo "dev" >"$repo/dev.txt"
	git -C "$repo" add dev.txt
	git -C "$repo" commit -q -m "feat: dev"
	git -C "$repo" remote add origin "$remote"
	git -C "$repo" push -q origin main dev
}

init_custom_rel_repo() {
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
	git -C "$repo" branch -M trunk
	git -C "$repo" checkout -q -b develop
	echo "develop" >"$repo/develop.txt"
	git -C "$repo" add develop.txt
	git -C "$repo" commit -q -m "feat: develop"
	git -C "$repo" remote add upstream "$remote"
	git -C "$repo" push -q upstream trunk develop
}

@test "git_rel --print-policy prints defaults without Git operations" {
	cd "$TEST_TEMP_DIR"
	run bash "$GIT_REL" --print-policy
	[[ "$status" -eq 0 ]]
	[[ "$output" == "$(expected_defaults)" ]]
}

@test "git_rel invalid policy fails before repository validation" {
	cat >"${TEST_TEMP_DIR}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=banana
EOF

	cd "$TEST_TEMP_DIR"
	run bash "$GIT_REL"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"FLOW_MODE_TO_MAIN"* ]]
	[[ "$output" == *"banana"* ]]
	[[ "$output" != *"No estás dentro de un repositorio Git"* ]]
}

@test "git_rel PR mode is explicit and not implemented yet" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr
EOF

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"PR mode not implemented yet"* ]]
	[[ "$output" == *"FLOW_MODE_TO_MAIN=pr"* ]]
}

@test "git_rel validation command runs from repo root and aborts before merge" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local validation_log="${TEST_TEMP_DIR}/rel-validation.log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<EOF
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="pwd > '${validation_log}'; exit 42"
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add git flow policy"
	mkdir -p "${repo}/subdir"

	cd "${repo}/subdir"
	run bash "$GIT_REL"
	[[ "$status" -ne 0 ]]
	[[ "$(cat "$validation_log")" == "$repo" ]]
	[[ "$output" == *"Running validation:"* ]]
	[[ "$output" == *"Validation failed:"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
}

@test "git_rel uses configured remote and base branches before validation" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/upstream.git"
	local validation_log="${TEST_TEMP_DIR}/rel-policy-branch.log"
	init_custom_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<EOF
REMOTE_NAME=upstream
BASE_DEV_BRANCH=develop
BASE_MAIN_BRANCH=trunk
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="printf validated > '${validation_log}'; exit 42"
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add git flow policy"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -ne 0 ]]
	[[ "$(cat "$validation_log")" == "validated" ]]
	[[ "$output" == *"Iniciando release de develop a trunk"* ]]
	[[ "$output" == *"Validation failed:"* ]]
}
