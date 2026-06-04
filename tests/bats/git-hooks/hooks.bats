#!/usr/bin/env bats

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TREEGEN="${DOTFILES_DIR}/scripts/treegen.sh"
	PRE_COMMIT="${DOTFILES_DIR}/scripts/hooks/pre-commit-treegen.sh"
	POST_COMMIT="${DOTFILES_DIR}/scripts/hooks/post-commit-gitnexus.sh"
	INSTALLER="${DOTFILES_DIR}/scripts/install-git-hooks.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

init_repo() {
	local repo="$1"
	git init -q "$repo"
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "initial" >"$repo/file.txt"
	git -C "$repo" add file.txt
	git -c core.hooksPath=/dev/null -C "$repo" commit -q -m initial
}

copy_treegen_stack() {
	local repo="$1"
	mkdir -p "$repo/scripts/hooks"
	cp "$TREEGEN" "$repo/scripts/treegen.sh"
	cp "$PRE_COMMIT" "$repo/scripts/hooks/pre-commit-treegen.sh"
	chmod +x "$repo/scripts/treegen.sh" "$repo/scripts/hooks/pre-commit-treegen.sh"
}

copy_post_commit() {
	local repo="$1"
	mkdir -p "$repo/scripts/hooks" "$repo/scripts/lib"
	cp "$POST_COMMIT" "$repo/scripts/hooks/post-commit-gitnexus.sh"
	chmod +x "$repo/scripts/hooks/post-commit-gitnexus.sh"
}

copy_gitnexus_runtime() {
	local repo="$1"
	mkdir -p "$repo/scripts/lib" "$repo/scripts/update/lib"
	cp "${DOTFILES_DIR}/scripts/lib/gitnexus_runtime.sh" "$repo/scripts/lib/"
	cp "${DOTFILES_DIR}/scripts/update/lib/node_runtime.sh" "$repo/scripts/update/lib/"
}

copy_hook_entrypoints() {
	local repo="$1"
	mkdir -p "$repo/.githooks"
	cp "${DOTFILES_DIR}/.githooks/pre-commit" "${DOTFILES_DIR}/.githooks/post-commit" "$repo/.githooks/"
	chmod +x "$repo/.githooks/pre-commit" "$repo/.githooks/post-commit"
}

@test "treegen --no-stage updates STRUCTURE.md without staging it" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	echo "seed" >"$repo/STRUCTURE.md"
	git -C "$repo" add STRUCTURE.md
	git -c core.hooksPath=/dev/null -C "$repo" commit -q -m structure

	run "$TREEGEN" --no-stage "$repo"
	[[ "$status" -eq 0 ]]
	[[ -z "$(git -C "$repo" diff --cached --name-only)" ]]
	[[ -n "$(git -C "$repo" status --short STRUCTURE.md)" ]]
}

@test "treegen manual mode preserves automatic staging" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	echo "seed" >"$repo/STRUCTURE.md"

	run "$TREEGEN" "$repo"
	[[ "$status" -eq 0 ]]
	[[ "$(git -C "$repo" diff --cached --name-only)" == "STRUCTURE.md" ]]
}

@test "treegen is idempotent when the tree does not change" {
	local repo="${TEST_TEMP_DIR}/repo"
	local first_hash first_mtime
	init_repo "$repo"
	echo "seed" >"$repo/STRUCTURE.md"

	"$TREEGEN" --no-stage "$repo" >/dev/null
	first_hash="$(git -C "$repo" hash-object STRUCTURE.md)"
	first_mtime="$(stat -c %Y "$repo/STRUCTURE.md")"
	sleep 1

	run "$TREEGEN" --no-stage "$repo"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Unchanged:"* ]]
	[[ "$first_hash" == "$(git -C "$repo" hash-object STRUCTURE.md)" ]]
	[[ "$first_mtime" == "$(stat -c %Y "$repo/STRUCTURE.md")" ]]
}

@test "pre-commit skips when STRUCTURE.md does not exist" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	copy_treegen_stack "$repo"

	run bash -c "cd '$repo' && '$repo/scripts/hooks/pre-commit-treegen.sh'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"STRUCTURE.md does not exist"* ]]
}

@test "pre-commit fails when treegen changes STRUCTURE.md without staging it" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	copy_treegen_stack "$repo"
	echo "seed" >"$repo/STRUCTURE.md"
	git -C "$repo" add STRUCTURE.md
	git -c core.hooksPath=/dev/null -C "$repo" commit -q -m structure
	echo "new" >"$repo/new-file.txt"

	run bash -c "cd '$repo' && '$repo/scripts/hooks/pre-commit-treegen.sh'"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"treegen updated STRUCTURE.md"* ]]
	[[ -z "$(git -C "$repo" diff --cached --name-only)" ]]
}

@test "post-commit honors DOTFILES_SKIP_HOOKS" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	copy_post_commit "$repo"

	run env DOTFILES_SKIP_HOOKS=1 bash -c "cd '$repo' && '$repo/scripts/hooks/post-commit-gitnexus.sh'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DOTFILES_SKIP_HOOKS=1"* ]]
}

@test "post-commit honors DOTFILES_SKIP_GITNEXUS" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	copy_post_commit "$repo"

	run env DOTFILES_SKIP_GITNEXUS=1 bash -c "cd '$repo' && '$repo/scripts/hooks/post-commit-gitnexus.sh'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"DOTFILES_SKIP_GITNEXUS=1"* ]]
}

@test "post-commit forces refresh when GitNexus MCP or lock is active" {
	local repo="${TEST_TEMP_DIR}/repo"
	local trace="${TEST_TEMP_DIR}/trace"
	init_repo "$repo"
	copy_post_commit "$repo"
	cat >"$repo/scripts/lib/gitnexus_runtime.sh" <<'EOF'
gitnexus_index_in_use() { return 0; }
gitnexus_analyze_here() {
	printf '%s\n' "$*" >"$GNX_TRACE"
}
EOF

	run env GNX_TRACE="$trace" bash -c "cd '$repo' && '$repo/scripts/hooks/post-commit-gitnexus.sh'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"MCP/lock detected; running forced post-commit refresh"* ]]
	[[ "$output" == *"post-commit refresh completed"* ]]
	grep -q -- '--force --skip-agents-md' "$trace"
}

@test "post-commit remains successful when GitNexus analyze fails" {
	local repo="${TEST_TEMP_DIR}/repo"
	local trace="${TEST_TEMP_DIR}/trace"
	init_repo "$repo"
	copy_post_commit "$repo"
	cat >"$repo/scripts/lib/gitnexus_runtime.sh" <<'EOF'
gitnexus_index_in_use() { return 1; }
gitnexus_analyze_here() {
	printf '%s\n' "$*" >"$GNX_TRACE"
	return 1
}
EOF

	run env GNX_TRACE="$trace" bash -c "cd '$repo' && '$repo/scripts/hooks/post-commit-gitnexus.sh'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"refresh failed; run gitnexus analyze --force . manually"* ]]
	grep -q -- '--force --skip-agents-md' "$trace"
}

@test "post-commit timeout remains successful with a warning" {
	local repo="${TEST_TEMP_DIR}/repo"
	local fake_bin="${TEST_TEMP_DIR}/fake-bin"
	local trace="${TEST_TEMP_DIR}/timeout-trace"
	init_repo "$repo"
	copy_post_commit "$repo"
	mkdir -p "$fake_bin"
	cat >"$repo/scripts/lib/gitnexus_runtime.sh" <<'EOF'
gitnexus_index_in_use() { return 1; }
gitnexus_analyze_here() { return 99; }
EOF
	cat >"$fake_bin/timeout" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$TIMEOUT_TRACE"
exit 124
EOF
	chmod +x "$fake_bin/timeout"

	run env TIMEOUT_TRACE="$trace" PATH="$fake_bin:$PATH" \
		bash -c "cd '$repo' && '$repo/scripts/hooks/post-commit-gitnexus.sh'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"refresh timed out after 30s"* ]]
	grep -q '^30s ' "$trace"
}

@test "post-commit uses the shared managed Node runtime without aliases" {
	local repo="${TEST_TEMP_DIR}/repo"
	local fake_bin="${TEST_TEMP_DIR}/fake-bin"
	local managed_node="${TEST_TEMP_DIR}/managed/node"
	local trace="${TEST_TEMP_DIR}/trace"
	init_repo "$repo"
	copy_post_commit "$repo"
	copy_gitnexus_runtime "$repo"
	mkdir -p "$fake_bin" "$(dirname "$managed_node")"

	cat >"$fake_bin/node" <<'EOF'
#!/usr/bin/env bash
echo "v20.18.2"
EOF
	cat >"$managed_node" <<'EOF'
#!/usr/bin/env bash
echo "v24.16.0"
EOF
	cat >"$fake_bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
	cat >"$fake_bin/gitnexus" <<'EOF'
#!/usr/bin/env bash
echo "$*:$(command -v node):$(node --version)" >"$GNX_TRACE"
EOF
	chmod +x "$fake_bin/node" "$managed_node" "$fake_bin/pgrep" "$fake_bin/gitnexus"

	run env \
		GNX_TRACE="$trace" \
		DOTFILES_MANAGED_NODE_BIN="$managed_node" \
		PATH="$fake_bin:$PATH" \
		bash -c "cd '$repo' && '$repo/scripts/hooks/post-commit-gitnexus.sh'"

	[[ "$status" -eq 0 ]]
	grep -q '^analyze --force --skip-agents-md:' "$trace"
	grep -q 'node-runtime\..*/node:v24.16.0' "$trace"
}

@test "install-git-hooks configures local hooks path and is idempotent" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	copy_hook_entrypoints "$repo"

	run bash -c "cd '$repo' && bash '$INSTALLER'"
	[[ "$status" -eq 0 ]]
	[[ "$(git -C "$repo" config --local --get core.hooksPath)" == ".githooks" ]]

	run bash -c "cd '$repo' && bash '$INSTALLER'"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"already .githooks"* ]]
}

@test "install-git-hooks does not overwrite another local hooks path" {
	local repo="${TEST_TEMP_DIR}/repo"
	init_repo "$repo"
	copy_hook_entrypoints "$repo"
	git -C "$repo" config --local core.hooksPath custom-hooks

	run bash -c "cd '$repo' && bash '$INSTALLER'"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"refusing to overwrite"* ]]
	[[ "$(git -C "$repo" config --local --get core.hooksPath)" == "custom-hooks" ]]
}

@test "versioned hook entrypoints are executable delegators" {
	[[ -x "${DOTFILES_DIR}/.githooks/pre-commit" ]]
	[[ -x "${DOTFILES_DIR}/.githooks/post-commit" ]]
	grep -q 'scripts/hooks/pre-commit-treegen.sh' "${DOTFILES_DIR}/.githooks/pre-commit"
	grep -q 'scripts/hooks/post-commit-gitnexus.sh' "${DOTFILES_DIR}/.githooks/post-commit"
}

@test "install-git-hooks is explicit and discoverable" {
	grep -q '^install-git-hooks:' "${DOTFILES_DIR}/install.mk"
	[[ "$(grep '^install:' "${DOTFILES_DIR}/install.mk")" != *"install-git-hooks"* ]]
	[[ "$(grep '^update:' "${DOTFILES_DIR}/update.mk")" != *"install-git-hooks"* ]]
	run make -C "$DOTFILES_DIR" help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"make install-git-hooks"* ]]
}

@test "hook documentation covers behavior and escape variables" {
	local doc
	for doc in \
		"${DOTFILES_DIR}/docs/INSTALL.md" \
		"${DOTFILES_DIR}/docs/OPERATIONS_CHEATSHEET.md"; do
		grep -q 'make install-git-hooks' "$doc"
		grep -q 'DOTFILES_SKIP_HOOKS=1' "$doc"
		grep -q 'DOTFILES_SKIP_TREEGEN=1' "$doc"
		grep -q 'DOTFILES_SKIP_GITNEXUS=1' "$doc"
	done
}

@test "GitNexus hook policy documents forced best-effort refresh" {
	local policy="${DOTFILES_DIR}/docs/GITNEXUS_OPERATIONAL_POLICY.md"
	grep -q 'gitnexus analyze --force .' "$policy"
	grep -q '30 segundos' "$policy"
}
