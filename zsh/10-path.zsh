# =============================================================================
# PATH (deduplicated)
# =============================================================================

# Fix PHP execution
path_prepend "/usr/bin"

# Local binaries (includes Cursor CLI)
path_append "$HOME/.local/bin"

# OpenCode CLI
path_prepend "$HOME/.opencode/bin"

# NPM Global packages
path_prepend "$HOME/.npm-global/bin"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
