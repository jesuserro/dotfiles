# =============================================================================
# PATH (deduplicated)
# =============================================================================

# Fix PHP execution
path_prepend "/usr/bin"

# OpenCode CLI
path_prepend "$HOME/.opencode/bin"

# NPM Global packages
path_prepend "$NPM_CONFIG_PREFIX/bin"

# Agent-first local commands should win over npm-global shims.
path_prepend "$HOME/.local/bin"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
