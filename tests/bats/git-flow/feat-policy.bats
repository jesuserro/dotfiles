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

@test "git_feat PR mode pr_auto creates PR and enables auto-merge with strategy" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-auto.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_auto
MERGE_STRATEGY_TO_DEV=squash
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_auto policy"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"pr create --base dev --head feature/demo"* ]]
	[[ "$(cat "$gh_log")" == *"pr merge feature/demo --squash --auto"* ]]
	[[ "$(cat "$gh_log")" != *"pr merge feature/demo --merge --auto"* ]]
}

install_gh_stub_configurable() {
	local log="$1"
	local auto_error_mode="${2:-success}"
	local bin_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "$bin_dir"
	cat >"${bin_dir}/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_STUB_LOG"
if [[ "$*" == *"pr merge"* && "$*" == *"--auto"* ]]; then
	case "${GH_AUTO_ERROR:-success}" in
	clean)
		printf 'GraphQL: Pull request Pull request is in clean status (enablePullRequestAutoMerge)\n' >&2
		exit 1
		;;
	other)
		printf 'GraphQL: merge not allowed due to repository rules\n' >&2
		exit 1
		;;
	esac
fi
if [[ "$*" == *"pr create"* ]]; then
	printf 'https://github.com/example/repo/pull/1\n'
fi
exit 0
EOF
	chmod +x "${bin_dir}/gh"
	export GH_STUB_LOG="$log"
	export GH_AUTO_ERROR="$auto_error_mode"
	export PATH="${bin_dir}:${PATH}"
}

@test "git_feat PR mode pr_auto falls back to immediate merge on clean status" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-auto-clean.log"
	install_gh_stub_configurable "$gh_log" clean
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_auto
MERGE_STRATEGY_TO_DEV=merge
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_auto clean fallback"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -eq 0 ]]
	grep -qx 'pr merge feature/demo --merge --auto' "$gh_log"
	grep -qx 'pr merge feature/demo --merge' "$gh_log"
	[[ "$output" == *"auto-merge unavailable (PR already clean)"* ]]
}

@test "git_feat PR mode pr_auto does not fallback on unrelated gh merge errors" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-auto-other.log"
	install_gh_stub_configurable "$gh_log" other
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_auto
MERGE_STRATEGY_TO_DEV=merge
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_auto other error"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	local feat_output="$output"
	grep -qx 'pr merge feature/demo --merge --auto' "$gh_log"
	run ! grep -qx 'pr merge feature/demo --merge' "$gh_log"
	[[ "$feat_output" == *"Error al aplicar merge del Pull Request"* ]]
}

@test "git_feat PR mode pr_immediate merges immediately with rebase strategy" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-immediate.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_immediate
MERGE_STRATEGY_TO_DEV=rebase
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_immediate policy"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"pr create --base dev --head feature/demo"* ]]
	[[ "$(cat "$gh_log")" == *"pr merge feature/demo --rebase"* ]]
	[[ "$(cat "$gh_log")" != *"--auto"* ]]
}

@test "git_feat PR mode manual does not call gh pr merge" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-manual.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: manual pr policy"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$gh_log")" == *"pr create"* ]]
	[[ "$(cat "$gh_log")" != *"pr merge"* ]]
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

@test "git_feat without argument uses current feature branch in local mode" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
DELETE_FEATURE_BRANCH=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: preserve current feature branch"
	git -C "$repo" push -q origin feature/demo

	cd "$repo"
	run bash -c "printf 's\n' | '${GIT_FEAT}' --no-changelog"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Integrando 'feature/demo' en 'dev'"* ]]
	[[ "$output" == *"INFO: Feature branch preserved by policy: feature/demo"* ]]
	git show-ref --verify --quiet refs/heads/feature/demo
}

@test "git_feat without argument outside feature branch fails before merge" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"
	git -C "$repo" checkout -q dev

	cd "$repo"
	run bash "$GIT_FEAT" --no-changelog
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"ERROR: git feat without a branch argument must be run from a feature/ branch."* ]]
	[[ "$output" == *"Current branch: dev"* ]]
	[[ "$output" == *"Expected prefix: feature/"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	run git show-ref --verify --quiet refs/heads/archive/feature/demo
	[[ "$status" -ne 0 ]]
}

@test "git_feat without argument in detached HEAD fails clearly" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"
	git -C "$repo" checkout -q --detach HEAD

	cd "$repo"
	run bash "$GIT_FEAT" --no-changelog
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"ERROR: git feat without a branch argument requires a named current branch."* ]]
	[[ "$output" != *"Haciendo merge"* ]]
}

@test "git_feat without argument respects configured feature prefix" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	git init -q --bare "$remote"
	mkdir -p "$repo"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "base" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -C "$repo" commit -q -m "initial"
	git -C "$repo" branch -M main
	git -C "$repo" checkout -q -b integration
	git -C "$repo" remote add origin "$remote"
	git -C "$repo" push -q origin main integration
	git -C "$repo" checkout -q -b feat/demo
	echo "feat" >"$repo/feat.txt"
	git -C "$repo" add feat.txt
	git -C "$repo" commit -q -m "feat: custom prefix"
	git -C "$repo" push -q origin feat/demo
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
BASE_DEV_BRANCH=integration
FEATURE_BRANCH_PREFIX=feat/
DELETE_FEATURE_BRANCH=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: custom prefix policy"
	git -C "$repo" push -q origin feat/demo

	cd "$repo"
	run bash -c "printf 's\n' | '${GIT_FEAT}' --no-changelog"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Integrando 'feat/demo' en 'integration'"* ]]
	[[ "$output" == *"INFO: Feature branch preserved by policy: feat/demo"* ]]
}

@test "git_feat without argument rejects branch outside configured feature prefix" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FEATURE_BRANCH_PREFIX=feat/
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: custom prefix mismatch"

	cd "$repo"
	run bash "$GIT_FEAT" --no-changelog
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"ERROR: git feat without a branch argument must be run from a feat/ branch."* ]]
	[[ "$output" == *"Current branch: feature/demo"* ]]
	[[ "$output" == *"Expected prefix: feat/"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
}

@test "git_feat PR mode validates pushes current feature branch and creates PR" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/upstream.git"
	local validation_log="${TEST_TEMP_DIR}/pr-validation.log"
	local gh_log="${TEST_TEMP_DIR}/gh.log"
	install_gh_stub "$gh_log"

	git init -q --bare "$remote"
	mkdir -p "$repo"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "base" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -C "$repo" commit -q -m "initial"
	git -C "$repo" branch -M main
	git -C "$repo" checkout -q -b integration
	git -C "$repo" remote add upstream "$remote"
	git -C "$repo" push -q upstream main integration
	git -C "$repo" checkout -q -b topic/demo
	echo "topic" >"$repo/topic.txt"
	git -C "$repo" add topic.txt
	git -C "$repo" commit -q -m "feat: topic"
	cat >"${repo}/.git-flow-policy.env" <<EOF
FLOW_MODE_TO_DEV=pr
REMOTE_NAME=upstream
BASE_DEV_BRANCH=integration
FEATURE_BRANCH_PREFIX=topic/
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="printf validated > '${validation_log}'"
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: add pr policy"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -eq 0 ]]
	[[ "$(cat "$validation_log")" == "validated" ]]
	[[ "$output" == *"Creating pull request for 'topic/demo' into 'integration'"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ "$output" != *"Archivando rama"* ]]
	[[ "$(git branch --show-current)" == "topic/demo" ]]
	git ls-remote --exit-code --heads upstream topic/demo >/dev/null
	[[ "$(cat "$gh_log")" == *"pr create --base integration --head topic/demo"* ]]
	[[ "$(cat "$gh_log")" != *"--web"* ]]
	run git show-ref --verify --quiet refs/heads/archive/topic/demo
	[[ "$status" -ne 0 ]]
}

@test "git_feat PR mode without argument uses current feature branch" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-no-arg.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr policy without arg"

	cd "$repo"
	run bash "$GIT_FEAT"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Creating pull request for 'feature/demo' into 'dev'"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ "$(git branch --show-current)" == "feature/demo" ]]
	[[ "$(cat "$gh_log")" == *"pr create --base dev --head feature/demo"* ]]
}

@test "git_feat PR mode aborts when validation fails before push or PR" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	git -C "$repo" push -q origin --delete feature/demo
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr
VALIDATE_TO_DEV=true
VALIDATE_CMD_TO_DEV="false"
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: failing pr validation"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"Validation failed:"* ]]
	run git ls-remote --exit-code --heads origin feature/demo
	[[ "$status" -ne 0 ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_feat PR mode requires the current branch to match feature prefix" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	git -C "$repo" checkout -q dev
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr policy on dev"

	cd "$repo"
	run bash "$GIT_FEAT" demo
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"requires current branch to start with 'feature/'"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_feat --dry-run local mode prints planned actions without merge or push" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	init_feat_repo_with_remote "$repo" "$remote"

	cd "$repo"
	run bash "$GIT_FEAT" --dry-run --no-changelog demo
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git feat local flow"* ]]
	[[ "$output" == *"Would merge 'feature/demo' into 'dev'"* ]]
	[[ "$output" == *"Would push 'dev' to 'origin'"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ "$(git branch --show-current)" == "feature/demo" ]]
}

@test "git_feat --dry-run PR mode prints planned actions without gh pr create" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-dry-run.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr dry-run policy"

	cd "$repo"
	run bash "$GIT_FEAT" --dry-run demo
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git feat PR flow"* ]]
	[[ "$output" == *"Would create PR 'feature/demo' -> 'dev'"* ]]
	[[ "$output" == *"Would leave PR open for manual review"* ]]
	[[ "$output" != *"Haciendo merge"* ]]
	[[ ! -s "$gh_log" ]]
	[[ "$(git branch --show-current)" == "feature/demo" ]]
}

@test "git_feat --dry-run pr_auto mode prints auto-merge plan without gh" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-auto-dry.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_auto
MERGE_STRATEGY_TO_DEV=squash
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_auto dry-run policy"

	cd "$repo"
	run bash "$GIT_FEAT" --dry-run demo
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git feat PR flow (pr_auto)"* ]]
	[[ "$output" == *"Would enable auto-merge using strategy: squash"* ]]
	[[ ! -s "$gh_log" ]]
}

@test "git_feat --dry-run pr_immediate mode prints immediate merge plan without gh" {
	local repo="${TEST_TEMP_DIR}/repo"
	local remote="${TEST_TEMP_DIR}/origin.git"
	local gh_log="${TEST_TEMP_DIR}/gh-feat-immediate-dry.log"
	install_gh_stub "$gh_log"
	init_feat_repo_with_remote "$repo" "$remote"
	cat >"${repo}/.git-flow-policy.env" <<'EOF'
FLOW_MODE_TO_DEV=pr_immediate
MERGE_STRATEGY_TO_DEV=rebase
OPEN_BROWSER=false
EOF
	git -C "$repo" add .git-flow-policy.env
	git -C "$repo" commit -q -m "test: pr_immediate dry-run policy"

	cd "$repo"
	run bash "$GIT_FEAT" --dry-run demo
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DRY RUN: git feat PR flow (pr_immediate)"* ]]
	[[ "$output" == *"Would merge PR immediately using strategy: rebase"* ]]
	[[ ! -s "$gh_log" ]]
}
