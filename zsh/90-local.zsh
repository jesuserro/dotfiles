# =============================================================================
# Local/private and user customizations
# =============================================================================

# MCP secrets (~/.config/mcp-secrets.env via ~/.secrets/codex.env) are sourced
# at runtime by MCP wrappers (codex-mcp-github, etc.), not in interactive shells.
# Exporting GH_TOKEN/GITHUB_TOKEN here would override `gh auth switch`.
# Opt-in debugging only: DOTFILES_SOURCE_MCP_SECRETS=1 source ~/.secrets/codex.env
if [[ -n "${DOTFILES_SOURCE_MCP_SECRETS:-}" && -f "$HOME/.secrets/codex.env" ]]; then
  source "$HOME/.secrets/codex.env"
fi

# Local overrides (optional)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Aliases file
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

export EDITOR=vim
export VISUAL=vim
