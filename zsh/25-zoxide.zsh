# =============================================================================
# zoxide — smarter directory jumper
# =============================================================================
# Replaces the Oh My Zsh `z` plugin while preserving the `z <query>` habit.
# Optional APT package (system/packages/ubuntu.yaml). Shell starts cleanly if
# zoxide is missing. Do not enable OMZ plugin `z` alongside this module.
# Optional history import: zoxide import --from=z "$HOME/.z"

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
