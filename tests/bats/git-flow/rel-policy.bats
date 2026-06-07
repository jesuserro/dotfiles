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

@test "git_rel PR mode pr_auto creates PR and enables auto-merge with strategy" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-auto.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr_auto
MERGE_STRATEGY_TO_MAIN=squash
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_auto policy"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"pr create --base main --head dev --fill"* ]]
	[[ "$(cat "$gh_log")" == *"pr merge dev --squash --auto"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ "$output" != *"Creando tag"* ]]
	[[ "$(git branch --show-current)" == "dev" ]]
	run git tag -l 'v*'
	[[ -z "$output" ]]
}

@test "git_rel PR mode pr_immediate merges immediately with merge strategy" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-immediate.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr_immediate
MERGE_STRATEGY_TO_MAIN=merge
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_immediate policy"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"pr create --base main --head dev --fill"* ]]
	[[ "$(cat "$gh_log")" == *"pr merge dev --merge"* ]]
	[[ "$(cat "$gh_log")" != *"--auto"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
}

@test "git_rel PR mode manual does not call gh pr merge" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-manual.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: manual pr policy"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"pr create"* ]]
	[[ "$(cat "$gh_log")" != *"pr merge"* ]]
}

@test "git_rel --dry-run local mode prints planned actions without merge or push" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_rel_repo "$repo" "$remote"

	cd "$repo"
	run bash "$GIT_REL" --dry-run
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git rel policy flow (local)"* ]]
	[[ "$output" == *"Would merge 'dev' into 'main'"* ]]
	[[ "$output" == *"Would create release tag"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ "$output" != *"Creando tag"* ]]
	[[ "$(git branch --show-current)" == "dev" ]]
}

@test "git_rel --dry-run PR mode prints planned actions without gh pr create" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-dry-run.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr
OPEN_BROWSER=false
EOF

	cd "$repo"
	run bash "$GIT_REL" --dry-run
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git rel policy flow (pr)"* ]]
	[[ "$output" == *"Would create PR 'dev' -> 'main'"* ]]
	[[ "$output" == *"Would leave PR open for manual review"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_rel --dry-run pr_auto mode prints auto-merge plan without gh" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-auto-dry.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr_auto
MERGE_STRATEGY_TO_MAIN=squash
OPEN_BROWSER=false
EOF

	cd "$repo"
	run bash "$GIT_REL" --dry-run
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git rel policy flow (pr_auto)"* ]]
	[[ "$output" == *"Would enable auto-merge using strategy: squash"* ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_rel --dry-run pr_immediate mode prints immediate merge plan without gh" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-immediate-dry.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr_immediate
MERGE_STRATEGY_TO_MAIN=merge
OPEN_BROWSER=false
EOF

	cd "$repo"
	run bash "$GIT_REL" --dry-run
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git rel policy flow (pr_immediate)"* ]]
	[[ "$output" == *"Would merge PR immediately using strategy: merge"* ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_rel --dry-run without policy prints local legacy flow" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_rel_repo "$repo" "$remote"

	cd "$repo"
	run bash "$GIT_REL" --dry-run
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git rel policy flow (local)"* ]]
	[[ "$output" == *"Would merge 'dev' into 'main'"* ]]
}

@test "git_rel PR mode pushes dev and creates PR with gh fill" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-pr.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add pr policy"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Creating pull request for 'dev' into 'main'"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ "$output" != *"Creando tag"* ]]
	[[ "$(git branch --show-current)" == "dev" ]]
	[[ "$(cat "$gh_log")" == *"pr create --base main --head dev --fill"* ]]
	[[ "$(cat "$gh_log")" != *"pr merge"* ]]
	[[ "$(cat "$gh_log")" != *"--web"* ]]
	run git tag -l 'v*'
	[[ "$status" -eq 0 ]]
	[[ -z "$output" ]]
}

@test "git_rel PR mode respects OPEN_BROWSER with gh web flag" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-web.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr
OPEN_BROWSER=true
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add pr policy with browser"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"--web"* ]]
}

@test "git_rel PR mode aborts when validation fails before push or PR" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-rel-validation.log"
	install_gh_stub "$gh_log"
	init_rel_repo "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_MAIN=pr
VALIDATE_TO_MAIN=true
VALIDATE_CMD_TO_MAIN="false"
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: failing pr validation"

	cd "$repo"
	run bash "$GIT_REL"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"Validation failed:"* ]]
	[[ ! -s "$gh_log" ]]
	[[ "$output" != *"Haciendo merge"* ]]
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
