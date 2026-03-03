# =============================================================================
# Local/private and user customizations
# =============================================================================

# Secrets (single source of truth)
[[ -f "$HOME/.secrets/codex.env" ]] && source "$HOME/.secrets/codex.env"

# gh CLI: priorizar token classic de ~/.config/gh/hosts.yml (scope project).
# GH_TOKEN/GITHUB_TOKEN del env sobreescriben hosts.yml; el fine-grained (github_pat_)
# no tiene permisos de Projects. Sin estas vars, gh usa hosts.yml.
unset -v GH_TOKEN GITHUB_TOKEN 2>/dev/null || true

# Local overrides (optional)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Aliases file
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

export EDITOR=vim
export VISUAL=vim