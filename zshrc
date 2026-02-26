# Enable Powerlevel10k instant prompt. Keep close to the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# Modular Zsh config (dotfiles)
# =============================================================================

ZSH_DOTFILES_DIR="$HOME/dotfiles/zsh"

# Load modules in order (if present)
for f in \
  "$ZSH_DOTFILES_DIR/00-env.zsh" \
  "$ZSH_DOTFILES_DIR/10-path.zsh" \
  "$ZSH_DOTFILES_DIR/20-omz.zsh" \
  "$ZSH_DOTFILES_DIR/30-python.zsh" \
  "$ZSH_DOTFILES_DIR/90-local.zsh"
do
  [[ -f "$f" ]] && source "$f"
done