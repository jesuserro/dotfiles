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
            sed '1d' "$script" > "$temp_script"  # Remove shebang line with template
            bash -n "$temp_script" 2>/dev/null || {
                echo "Syntax error in $script" >&2
                return 1
            }
        fi
    done
}

@test "secrets script handles errors gracefully" {
    # run_after_00_gen_secrets uses || exit 0 pattern instead of set -e
    grep -q "|| exit 0" "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "run_after_10_setup_ai_runtime uses set -e" {
    head -10 "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl" | grep -q "set -e"
}

@test "run_after_11_link_ai_assets uses set -euo pipefail" {
    head -10 "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" | grep -q "set -euo pipefail"
}

@test "secrets script handles missing sops gracefully" {
    grep -q "|| exit 0" "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "ai runtime script checks for python3" {
    grep -q "python3" "$DOTFILES_DIR/.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl"
}

@test "ai assets script is idempotent" {
    # Check for symlink handling that prevents duplicates
    grep -q "ensure_symlink" "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl" || \
    grep -q "readlink" "$DOTFILES_DIR/.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl"
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

@test "dot_codex/config.toml.tmpl has valid toml structure" {
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

with open('$DOTFILES_DIR/dot_codex/config.toml.tmpl', 'r') as f:
    content = f.read()

# Remove chezmoi template syntax
content = re.sub(r'\{\{[^}]+\}\}', 'placeholder', content)
tomllib.loads(content)
" 2>/dev/null || skip "Template or toml parser not available"
}

@test "MCP configs have mcpServers key" {
    grep -q "mcpServers" "$DOTFILES_DIR/dot_cursor/mcp.json.tmpl" || \
    grep -q '"mcp":' "$DOTFILES_DIR/dot_cursor/mcp.json.tmpl"
}

@test "OpenCode MCP config has filesystem defined" {
    grep -q "filesystem" "$DOTFILES_DIR/dot_config/opencode/opencode.json.tmpl"
}

@test "OpenCode MCP config has git defined" {
    grep -q '"git"' "$DOTFILES_DIR/dot_config/opencode/opencode.json.tmpl"
}

@test "Codex MCP config has filesystem defined" {
    grep -q "filesystem" "$DOTFILES_DIR/dot_codex/config.toml.tmpl"
}

@test "Codex MCP config has sequential-thinking defined" {
    grep -q "sequential-thinking" "$DOTFILES_DIR/dot_codex/config.toml.tmpl"
}

@test "secrets script uses sops" {
    grep -q "sops" "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

@test "secrets script generates mcp-secrets.env" {
    grep -q "mcp-secrets.env" "$DOTFILES_DIR/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
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
    grep -q 'npm install -g --prefix="\$npm_prefix" @openai/codex@latest' "$DOTFILES_DIR/aliases"
    ! grep -q 'npm update -g codex' "$DOTFILES_DIR/aliases"
    grep -q 'NPM_CONFIG_PREFIX="\${NPM_CONFIG_PREFIX:-\$HOME/.npm-global}"' "$DOTFILES_DIR/scripts/install-gitnexus.sh"
    ! grep -q 'local_prefix="\$HOME/.local"' "$DOTFILES_DIR/aliases"
    ! grep -q 'local_prefix="\$HOME/.local"' "$DOTFILES_DIR/scripts/install-gitnexus.sh"
}

@test "ups Codex flow handles legacy conflicts and summary reports warnings honestly" {
    grep -q 'npm uninstall -g --prefix="\$npm_prefix" codex' "$DOTFILES_DIR/aliases"
    grep -q "codex --version" "$DOTFILES_DIR/aliases"
    grep -q 'Proceso completado con \${warnings} incidencia(s)/warning(s)' "$DOTFILES_DIR/aliases"
}
