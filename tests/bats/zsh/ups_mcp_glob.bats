#!/usr/bin/env bats

# Regression: the MCP servers loop inside ups() must not fail with `no matches
# found` under zsh's default `nomatch` when ~/.config/mcp/servers is missing or
# has no subdirectories. The fix uses the zsh nullglob qualifier `(N)` locally,
# without disabling `nomatch` globally.

setup() {
	if ! command -v zsh >/dev/null 2>&1; then
		skip "zsh not in PATH"
	fi
	ALIASES_FILE="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)/aliases"
	export ALIASES_FILE
}

@test "aliases is syntactically valid zsh" {
	run zsh -n "${ALIASES_FILE}"
	[[ "${status}" -eq 0 ]]
}

@test "MCP servers glob uses zsh (N) qualifier (not bare */)" {
	run grep -nE 'mcp/servers/\*\/\(N\)' "${ALIASES_FILE}"
	[[ "${status}" -eq 0 ]] || {
		echo "Expected zsh (N) nullglob qualifier on the MCP servers loop." >&2
		false
	}
	# And the legacy bare `for mcp_dir in "$HOME/.config/mcp/servers"/*/;` is gone.
	run grep -nE 'for[[:space:]]+mcp_dir[[:space:]]+in[[:space:]]+"\$HOME/\.config/mcp/servers"/\*/;' \
		"${ALIASES_FILE}"
	[[ "${status}" -ne 0 ]]
}

@test "glob (N) yields empty array when ~/.config/mcp/servers is missing" {
	local fake_home
	fake_home="$(mktemp -d)"
	run zsh -c '
		setopt nomatch
		HOME="'"${fake_home}"'"
		local -a dirs
		dirs=( "$HOME"/.config/mcp/servers/*/(N) )
		print "${#dirs[@]}"
	'
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "0" ]]
}

@test "glob (N) yields empty array when ~/.config/mcp/servers has no subdirs" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.config/mcp/servers"
	run zsh -c '
		setopt nomatch
		HOME="'"${fake_home}"'"
		local -a dirs
		dirs=( "$HOME"/.config/mcp/servers/*/(N) )
		print "${#dirs[@]}"
	'
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "0" ]]
}

@test "glob (N) lists subdirectories when present" {
	local fake_home
	fake_home="$(mktemp -d)"
	mkdir -p "${fake_home}/.config/mcp/servers/foo" \
		"${fake_home}/.config/mcp/servers/bar"
	run zsh -c '
		setopt nomatch
		HOME="'"${fake_home}"'"
		local -a dirs
		dirs=( "$HOME"/.config/mcp/servers/*/(N) )
		print "${#dirs[@]}"
	'
	rm -rf "${fake_home}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "2" ]]
}
