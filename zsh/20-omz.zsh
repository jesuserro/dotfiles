# =============================================================================
# Oh My Zsh
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
  autoupdate
  aws
  colored-man-pages
  colorize
  composer
  dirhistory
  docker
  extract
  gh
  git
  history
  jsontools
  pip
  python
  tmux
  virtualenv
  vi-mode
  wp-cli
  z
  zsh-autosuggestions
  zsh-completions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Powerlevel10k (load once, after OMZ). Chezmoi materializes ~/.p10k.zsh as a
# symlink to $HOME/dotfiles/powerlevel10k/p10k.zsh — do not source both paths.
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"