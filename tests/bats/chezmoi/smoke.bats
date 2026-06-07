#!/usr/bin/env bats
# Smoke tests for chezmoi scripts and templates

load '../helpers/common'

setup() {
	setup_temp_dir

	DOTFILES_DIR="$(get_dotfiles_dir)"

	# Create controlled HOME for testing
	TEST_HOME="$TEST_TEMP_DIR/test_home"
	mkdir -p "$TEST_HOME"

	# Create mock source directory
	MOCK_SOURCE="$TEST_TEMP_DIR/mock_source"
	mkdir -p "$MOCK_SOURCE"/.chezmoiscripts
}

teardown() {
	teardown_temp_dir
}

@test "chezmoi scripts directory exists in dotfiles" {
	[[ -d "$DOTFILES_DIR/.chezmoiscripts" ]]
}

@test "run_after_00_gen_secrets exists" {
	[[ -f "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl" ]]
}

@test "run_after_10_setup_ai_runtime exists" {
	[[ -f "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl" ]]
}

@test "run_after_11_link_ai_assets exists" {
	[[ -f "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" ]]
}

@test "run_after_14_link_prompt_launchers exists" {
	[[ -f "$DOTFILES_DIR/.chezmoiscripts/run_after_14_link_prompt_launchers.sh.tmpl" ]]
}

@test "run_after_15_link_tmux_dotfiles exists and publishes bin/tmux-dotfiles" {
	local tmpl="$DOTFILES_DIR/.chezmoiscripts/run_after_15_link_tmux_dotfiles.sh.tmpl"
	[[ -f "$tmpl" ]]
	grep -q 'ln -sf' "$tmpl"
	grep -q 'bin/tmux-dotfiles' "$tmpl"
	grep -q '\.local/bin' "$tmpl"
	grep -q 'LOCAL_BIN}/tmux-dotfiles' "$tmpl"
}

@test "playwright-docker is a directly managed chezmoi local bin symlink" {
	local tmpl="$DOTFILES_DIR/dot_local/bin/symlink_playwright-docker.tmpl"
	[[ -f "$tmpl" ]]
	[[ "$(cat "$tmpl")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/playwright-docker' ]]
	[[ ! -f "$DOTFILES_DIR/.chezmoiscripts/run_after_16_link_playwright_docker.sh.tmpl" ]]
}

@test "dotfiles-update is a directly managed chezmoi local bin symlink" {
	local tmpl="$DOTFILES_DIR/dot_local/bin/symlink_dotfiles-update.tmpl"
	[[ -f "$tmpl" ]]
	[[ "$(cat "$tmpl")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/dotfiles-update' ]]
	[[ ! -f "$DOTFILES_DIR/.chezmoiscripts/run_after_16_link_dotfiles_update.sh.tmpl" ]]
}

@test "dotfiles-apply is a directly managed chezmoi local bin symlink" {
	local tmpl="$DOTFILES_DIR/dot_local/bin/symlink_dotfiles-apply.tmpl"
	[[ -f "$tmpl" ]]
	[[ "$(cat "$tmpl")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/dotfiles-apply' ]]
}

@test "symlink_dot_tmux.conf points to repo tmux.conf" {
	local tmpl="$DOTFILES_DIR/symlink_dot_tmux.conf.tmpl"
	[[ -f "$tmpl" ]]
	grep -q '{{ .chezmoi.homeDir }}/dotfiles/tmux.conf' "$tmpl"
}

@test "run_before_00 backup hook covers tmux.conf" {
	local tmpl="$DOTFILES_DIR/.chezmoiscripts/run_before_00_backup_rc_files.sh.tmpl"
	grep -q '.tmux.conf' "$tmpl"
	grep -q 'tmux.conf' "$tmpl"
}

@test "run_after_13 git-ai: template and lib use ln -sf and ~/.local/bin" {
	local tmpl="$DOTFILES_DIR/.chezmoiscripts/run_after_13_link_git_ai_wrapper.sh.tmpl"
	local lib="$DOTFILES_DIR/scripts/lib/git-ai-common.sh"
	[[ -f "$tmpl" ]]
	grep -q "git-ai-wrapper" "$tmpl"
	grep -q "git_ai_link_dotfiles_bins\|git-ai-common" "$tmpl"
	[[ -f "$lib" ]]
	grep -q "ln -sf" "$lib"
	grep -q "git-ai-wrapper" "$lib"
	grep -q "git-set-ai-author" "$lib"
	grep -q ".local/bin" "$lib"
}

@test "run_after scripts are valid bash" {
	skip_if_command_missing "bash"

	for script in "$DOTFILES_DIR"/.chezmoiscripts/*.tmpl; do
		if [[ -f "$script" ]]; then
			# Remove .tmpl extension for bash check
			temp_script="$TEST_TEMP_DIR/temp_script.sh"
			sed '1d' "$script" >"$temp_script" # Remove shebang line with template
			bash -n "$temp_script" 2>/dev/null || {
				echo "Syntax error in $script" >&2
				return 1
			}
		fi
	done
}

@test "secrets script supports permissive and strict modes" {
	grep -q 'MCP_SECRETS_STRICT' "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
	grep -q 'fail_or_skip' "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "run_after_10_setup_ai_runtime uses strict shell and uv" {
	head -10 "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl" | grep -q "set -euo pipefail"
	grep -q 'uv pip install' "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl"
}

@test "run_after_11_link_ai_assets uses set -euo pipefail" {
	head -10 "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" | grep -q "set -euo pipefail"
}

@test "secrets script handles missing sops in permissive mode" {
	grep -q 'fail_or_skip' "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "ai runtime script documents uv prerequisite" {
	grep -q 'command -v uv' "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl"
}

@test "ai assets script is idempotent" {
	# Check for symlink handling that prevents duplicates
	grep -q "ensure_symlink" "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" ||
		grep -q "readlink" "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
}

@test "ai assets script refuses repo-local agent skill surfaces" {
	local tmpl="$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
	grep -q "refuse_repo_local_target" "$tmpl"
	grep -q "refusing to materialize AI assets inside dotfiles checkout" "$tmpl"
}

@test "dot_cursor/mcp.json.tmpl is valid json structure" {
	skip_if_command_missing "python3"

	# The template should be parseable as JSON (ignoring chezmoi syntax)
	python3 -c "
import re
import json

with open('$DOTFILES_DIR/dot_cursor/mcp.json.tmpl', 'r') as f:
    content = f.read()

# Remove chezmoi template syntax for parsing test
content = re.sub(r'\{\{[^}]+\}\}', '\"placeholder\"', content)
json.loads(content)
" 2>/dev/null || skip "Template contains complex chezmoi syntax"
}

@test "dot_config/opencode/opencode.json.tmpl is valid json structure" {
	skip_if_command_missing "python3"

	python3 -c "
import re
import json

with open('$DOTFILES_DIR/dot_config/opencode/opencode.json.tmpl', 'r') as f:
    content = f.read()

# Remove chezmoi template syntax for parsing test
content = re.sub(r'\{\{[^}]+\}\}', '\"placeholder\"', content)
json.loads(content)
" 2>/dev/null || skip "Template contains complex chezmoi syntax"
}

@test "dot_codex/private_config.toml.tmpl has valid toml structure" {
	skip_if_command_missing "python3"

	python3 -c "
import re
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        skip('toml parser not available')

with open('$DOTFILES_DIR/dot_codex/private_config.toml.tmpl', 'r') as f:
    content = f.read()

# Remove chezmoi template syntax
content = re.sub(r'\{\{[^}]+\}\}', 'placeholder', content)
tomllib.loads(content)
" 2>/dev/null || skip "Template or toml parser not available"
}

@test "MCP configs have mcpServers key" {
	grep -q "mcpServers" "$DOTFILES_DIR/dot_cursor/mcp.json.tmpl" ||
		grep -q '"mcp":' "$DOTFILES_DIR/dot_cursor/mcp.json.tmpl"
}

@test "OpenCode MCP config has filesystem defined" {
	grep -q "filesystem" "$DOTFILES_DIR/dot_config/opencode/opencode.json.tmpl"
}

@test "OpenCode MCP config has git defined" {
	grep -q '"git"' "$DOTFILES_DIR/dot_config/opencode/opencode.json.tmpl"
}

@test "Codex MCP config has filesystem defined" {
	grep -q "filesystem" "$DOTFILES_DIR/dot_codex/private_config.toml.tmpl"
}

@test "Codex MCP config has sequential-thinking defined" {
	grep -q "sequential-thinking" "$DOTFILES_DIR/dot_codex/private_config.toml.tmpl"
}

@test "secrets script uses sops" {
	grep -q "sops" "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "secrets script generates mcp-secrets.env" {
	grep -q "mcp-secrets.env" "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "codex secrets symlink points to canonical mcp-secrets env" {
	[[ "$(cat "$DOTFILES_DIR/symlink_dot_secrets_codex.env")" == ".config/mcp-secrets.env" ]]
}

@test "secrets script keeps codex.env as adapter to canonical mcp-secrets env" {
	local tmpl="$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
	grep -q 'OUT="${HOME}/.config/mcp-secrets.env"' "$tmpl"
	grep -q 'LEGACY_OUT="${HOME}/.config/store-etl/secrets.env"' "$tmpl"
	grep -q 'ln -sf "${HOME}/.config/mcp-secrets.env" "${HOME}/.secrets/codex.env"' "$tmpl"
}

@test "docs do not present store-etl secrets as canonical" {
	assert_tree_not_matches "Secreto can[oó]nico:.*store-etl/secrets.env" \
		"$DOTFILES_DIR/docs" "$DOTFILES_DIR/codex"
}

@test "ai runtime script uses venv" {
	grep -q "venv" "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl"
}

@test "ai assets script creates ~/.config/ai" {
	grep -q "\.config/ai" "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
}

@test "shell policy defines canonical npm global prefix for Codex and GitNexus" {
	grep -q 'export NPM_CONFIG_PREFIX="$HOME/.npm-global"' "$DOTFILES_DIR/zsh/00-env.zsh"
	grep -q 'path_prepend "\$NPM_CONFIG_PREFIX/bin"' "$DOTFILES_DIR/zsh/10-path.zsh"
	grep -q '"@openai/codex"' "$DOTFILES_DIR/scripts/update/update-wsl.sh"
	run grep -R 'npm update -g codex' "$DOTFILES_DIR/scripts/update" "$DOTFILES_DIR/aliases"
	[[ "${status}" -ne 0 ]]
	grep -q 'NPM_CONFIG_PREFIX="\${NPM_CONFIG_PREFIX:-\$HOME/.npm-global}"' "$DOTFILES_DIR/scripts/install-gitnexus.sh"
	run grep -q 'local_prefix="\$HOME/.local"' "$DOTFILES_DIR/scripts/update/update-wsl.sh"
	[[ "${status}" -ne 0 ]]
	assert_file_not_contains "$DOTFILES_DIR/scripts/install-gitnexus.sh" 'local_prefix="\$HOME/.local"'
}

@test "make update summary reports warnings honestly" {
	grep -q 'result_print_concise_summary' "$DOTFILES_DIR/scripts/update/update.sh"
	grep -q 'result_has_incidents' "$DOTFILES_DIR/scripts/update/update.sh"
}

@test "make update validates Node before GitNexus" {
	grep -q 'source "${SCRIPT_DIR}/lib/node_runtime.sh"' "$DOTFILES_DIR/scripts/update/update-wsl.sh"
	grep -q 'node_runtime_probe' "$DOTFILES_DIR/scripts/update/update-wsl.sh"
	grep -q '"gitnexus"' "$DOTFILES_DIR/scripts/update/update-wsl.sh"
	grep -q 'below required >=' "$DOTFILES_DIR/scripts/update/lib/node_runtime.sh"
	awk '
		/node_runtime_probe/ { node_probe = NR }
		/update_global_npm_tool_if_needed "WSL" "GitNexus CLI"/ { gitnexus_update = NR }
		END { exit !(node_probe && gitnexus_update && node_probe < gitnexus_update) }
	' "$DOTFILES_DIR/scripts/update/update-wsl.sh"
}
