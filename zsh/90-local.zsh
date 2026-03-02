# =============================================================================
# Local/private and user customizations
# =============================================================================

# Secrets (single source of truth)
[[ -f "$HOME/.secrets/codex.env" ]] && source "$HOME/.secrets/codex.env"

# Local overrides (optional)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Aliases file
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"