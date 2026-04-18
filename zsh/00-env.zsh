# =============================================================================
# Base env / defaults
# =============================================================================

export ORIGINAL_PATH="$PATH"

# Editor
export EDITOR="nvim"

# Canonical npm global prefix for user-owned CLI installs.
export NPM_CONFIG_PREFIX="$HOME/.npm-global"

# =============================================================================
# PATH helpers (avoid duplicates when sourcing multiple times)
# =============================================================================

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;                # already in PATH
    *) PATH="$1:$PATH" ;;
  esac
}

path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;                # already in PATH
    *) PATH="$PATH:$1" ;;
  esac
}
