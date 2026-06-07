#!/usr/bin/env bats
# Dotfiles-only GitNexus analyze policy: --skip-skills injection (ADR 0004).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	RUNTIME="${DOTFILES_DIR}/scripts/lib/gitnexus_runtime.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

link_core_utils() {
	local dir="$1"
	local cmd
	mkdir -p "$dir"
	for cmd in bash basename cat chmod command dirname env git grep head ln mkdir mktemp pwd rm tee tr; do
		if command -v "$cmd" >/dev/null 2>&1; then
			ln -sf "$(command -v "$cmd")" "${dir}/${cmd}"
		fi
	done
}

write_fake_node() {
	local path="$1" version="$2"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  echo "${version}"
  exit 0
fi
exit 0
EOF
	chmod +x "$path"
}

write_trace_gitnexus() {
	local path="$1"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${GNX_TRACE:-}" ]]; then
  printf '%s\n' "$*" >>"${GNX_TRACE}"
fi
exit 0
EOF
	chmod +x "$path"
}

init_git_repo() {
	local repo="$1"
	git -C "$repo" init -q
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "fixture" >"$repo/README.md"
	git -C "$repo" add README.md
	git -C "$repo" commit -q -m "init"
}

seed_dotfiles_markers() {
	local repo="$1"
	mkdir -p "$repo/docs/adr" "$repo/ai/assets/skills" "$repo/scripts/update/lib"
	touch "$repo/.chezmoi.toml"
	touch "$repo/docs/adr/0004-ai-assets-not-materialized.md"
	touch "$repo/scripts/validate-skills-structure.sh"
	cp "${DOTFILES_DIR}/scripts/lib/gitnexus_runtime.sh" "$repo/scripts/lib/"
	cp "${DOTFILES_DIR}/scripts/update/lib/node_runtime.sh" "$repo/scripts/update/lib/"
}

run_analyze_here() {
	local repo="$1"
	local trace="$2"
	shift 2

	local fake_home="${TEST_TEMP_DIR}/home"
	local shadow_bin="${TEST_TEMP_DIR}/shadow-bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local npm_prefix="${TEST_TEMP_DIR}/npm-prefix"

	link_core_utils "$shadow_bin"
	write_fake_node "${shadow_bin}/node" "v20.18.2"
	write_fake_node "$managed" "v24.16.0"
	write_trace_gitnexus "${npm_prefix}/bin/gitnexus"
	mkdir -p "$fake_home"

	run env \
		HOME="$fake_home" \
		DOTFILES_DIR="$repo" \
		DOTFILES_MANAGED_NODE_BIN="$managed" \
		DOTFILES_NPM_PREFIX="$npm_prefix" \
		NPM_CONFIG_PREFIX= \
		GNX_TRACE="$trace" \
		PATH="$shadow_bin:$npm_prefix/bin" \
		bash -c "cd '$repo' && source '$repo/scripts/lib/gitnexus_runtime.sh' && gitnexus_analyze_here $*"
}

bats_require_minimum_version 1.5.0

@test "dotfiles checkout analyze receives --skip-skills" {
	local repo="${TEST_TEMP_DIR}/dotfiles-fixture"
	local trace="${TEST_TEMP_DIR}/trace-dotfiles"
	mkdir -p "$repo/scripts/lib"
	seed_dotfiles_markers "$repo"
	init_git_repo "$repo"

	run_analyze_here "$repo" "$trace" --skip-agents-md
	[[ "$status" -eq 0 ]]
	grep -q -- '--skip-skills' "$trace"
	grep -q -- '--skip-agents-md' "$trace"
}

@test "non-dotfiles repo analyze does not receive --skip-skills" {
	local repo="${TEST_TEMP_DIR}/other-repo"
	local trace="${TEST_TEMP_DIR}/trace-other"
	mkdir -p "$repo/scripts/lib" "$repo/scripts/update/lib"
	cp "${DOTFILES_DIR}/scripts/lib/gitnexus_runtime.sh" "$repo/scripts/lib/"
	cp "${DOTFILES_DIR}/scripts/update/lib/node_runtime.sh" "$repo/scripts/update/lib/"
	init_git_repo "$repo"

	run_analyze_here "$repo" "$trace" --skip-agents-md
	[[ "$status" -eq 0 ]]
	grep -q -- '--skip-agents-md' "$trace"
	run grep -q -- '--skip-skills' "$trace"
	[[ "$status" -ne 0 ]]
}

@test "explicit --skip-skills is not duplicated in dotfiles checkout" {
	local repo="${TEST_TEMP_DIR}/dotfiles-fixture"
	local trace="${TEST_TEMP_DIR}/trace-explicit"
	mkdir -p "$repo/scripts/lib"
	seed_dotfiles_markers "$repo"
	init_git_repo "$repo"

	run_analyze_here "$repo" "$trace" --skip-agents-md --skip-skills
	[[ "$status" -eq 0 ]]
	[[ "$(grep -c -- '--skip-skills' "$trace")" -eq 1 ]]
}

@test "index-only is not altered by dotfiles analyze policy" {
	local repo="${TEST_TEMP_DIR}/dotfiles-fixture"
	local trace="${TEST_TEMP_DIR}/trace-index-only"
	mkdir -p "$repo/scripts/lib"
	seed_dotfiles_markers "$repo"
	init_git_repo "$repo"

	run_analyze_here "$repo" "$trace" --index-only
	[[ "$status" -eq 0 ]]
	run grep -q -- '--skip-skills' "$trace"
	[[ "$status" -ne 0 ]]
	grep -q -- '--index-only' "$trace"
}

@test "gitnexus_analyze_here in dotfiles fixture does not create .claude" {
	local repo="${TEST_TEMP_DIR}/dotfiles-fixture"
	local trace="${TEST_TEMP_DIR}/trace-no-claude"
	mkdir -p "$repo/scripts/lib"
	seed_dotfiles_markers "$repo"
	init_git_repo "$repo"

	run_analyze_here "$repo" "$trace" --force --skip-agents-md
	[[ "$status" -eq 0 ]]
	[[ ! -e "$repo/.claude" ]]
}

@test "runtime exposes dotfiles checkout detection helper" {
	grep -q '_gnx_is_dotfiles_checkout' "$RUNTIME"
	grep -q '_gnx_apply_dotfiles_analyze_policy' "$RUNTIME"
	grep -q '"--skip-skills"' "$RUNTIME"
}
