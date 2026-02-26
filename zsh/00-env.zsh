# =============================================================================
# Base env / defaults
# =============================================================================

export ORIGINAL_PATH="$PATH"

# Editor
export EDITOR="nvim"

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