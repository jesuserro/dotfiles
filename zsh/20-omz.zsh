# =============================================================================
# Oh My Zsh
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
  autoupdate
  azure
  chezmoi
  colored-man-pages
  colorize
  command-not-found
  debian
  dirhistory
  docker
  docker-compose
  extract
  gh
  git
  gitignore
  history
  jsontools
  npm
  python
  rsync
  systemd
  tmux
  urltools
  uv
  virtualenv
  vi-mode
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
