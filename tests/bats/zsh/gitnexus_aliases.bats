#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

link_core_utils() {
	local dir="$1"
	local cmd
	mkdir -p "$dir"
	for cmd in bash basename cat chmod command dirname env git grep head ln mkdir mktemp pwd rm tr; do
		if command -v "$cmd" >/dev/null 2>&1; then
			ln -sf "$(command -v "$cmd")" "${dir}/${cmd}"
		fi
	done
}

write_fake_node() {
	local path="$1" version="$2" label="$3"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  echo "${version}"
  exit 0
fi
if [[ -n "\${GNX_ALIAS_TRACE:-}" ]]; then
  echo "${label}:node:\${1:-}" >> "\${GNX_ALIAS_TRACE}"
fi
exit 0
EOF
	chmod +x "$path"
}

write_fake_gitnexus() {
	local path="$1"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${GNX_ALIAS_TRACE:-}" ]]; then
  echo "gitnexus:${*}" >> "${GNX_ALIAS_TRACE}"
  echo "gitnexus-node:$(command -v node):$(node --version)" >> "${GNX_ALIAS_TRACE}"
fi
case "${1:-}" in
  analyze) exit 0 ;;
  status) exit 1 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "$path"
}

write_fake_docker() {
	local path="$1"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "$path"
}

@test "gnx-analyze-here uses managed Node overlay when effective Node is too old" {
	if ! command -v zsh >/dev/null 2>&1; then
		skip "zsh not in PATH"
	fi

	local zsh_bin
	zsh_bin="$(command -v zsh)"
	local fake_home="${TEST_TEMP_DIR}/home"
	local shadow_bin="${TEST_TEMP_DIR}/home/.cursor-server/bin/hash"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local npm_prefix="${TEST_TEMP_DIR}/npm-prefix"
	local trace="${TEST_TEMP_DIR}/trace.log"
	local repo="${TEST_TEMP_DIR}/repo"

	link_core_utils "$shadow_bin"
	write_fake_docker "${shadow_bin}/docker"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v24.15.0" "managed"
	write_fake_gitnexus "${npm_prefix}/bin/gitnexus"
	mkdir -p "$fake_home" "$repo/.git"

	run env \
		HOME="$fake_home" \
		DOTFILES_DIR="$DOTFILES_DIR" \
		DOTFILES_MANAGED_NODE_BIN="$managed" \
		DOTFILES_NPM_PREFIX="$npm_prefix" \
		NPM_CONFIG_PREFIX= \
		GNX_ALIAS_TRACE="$trace" \
		PATH="$shadow_bin:$npm_prefix/bin" \
		"$zsh_bin" -c "cd '$repo' && source '$DOTFILES_DIR/aliases' && gnx-analyze-here"

	[[ "$status" -eq 0 ]] || {
		echo "$output" >&2
		false
	}
	grep -q '^gitnexus:analyze$' "$trace"
	grep -q 'gitnexus-node:.*/node-runtime\.[^:]*\/node:v24.15.0' "$trace"
	assert_file_not_contains "$trace" 'gitnexus-node:.*v20.18.2'
}

@test "gnx-analyze-here fails before GitNexus analyze when no compatible Node is available" {
	if ! command -v zsh >/dev/null 2>&1; then
		skip "zsh not in PATH"
	fi

	local zsh_bin
	zsh_bin="$(command -v zsh)"
	local fake_home="${TEST_TEMP_DIR}/home"
	local shadow_bin="${TEST_TEMP_DIR}/shadow/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local npm_prefix="${TEST_TEMP_DIR}/npm-prefix"
	local trace="${TEST_TEMP_DIR}/trace.log"
	local repo="${TEST_TEMP_DIR}/repo"

	link_core_utils "$shadow_bin"
	write_fake_docker "${shadow_bin}/docker"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v20.18.2" "managed"
	write_fake_gitnexus "${npm_prefix}/bin/gitnexus"
	mkdir -p "$fake_home" "$repo/.git"

	run env \
		HOME="$fake_home" \
		DOTFILES_DIR="$DOTFILES_DIR" \
		DOTFILES_MANAGED_NODE_BIN="$managed" \
		DOTFILES_NPM_PREFIX="$npm_prefix" \
		NPM_CONFIG_PREFIX= \
		GNX_ALIAS_TRACE="$trace" \
		PATH="$shadow_bin:$npm_prefix/bin" \
		"$zsh_bin" -c "cd '$repo' && source '$DOTFILES_DIR/aliases' && gnx-analyze-here"

	[[ "$status" -eq 1 ]]
	[[ "$output" == *"make update-check"* ]]
	if [[ -f "$trace" ]]; then
		assert_file_not_contains "$trace" '^gitnexus:analyze$'
	fi
}
