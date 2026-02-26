# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# PATH Configuration
# =============================================================================

# Saving the original PATH
export ORIGINAL_PATH=$PATH

# Edit the PATH to fix PHP execution
export PATH=/usr/bin:$PATH

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# =============================================================================
# Oh My Zsh
# =============================================================================

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
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

source $ZSH/oh-my-zsh.sh

# =============================================================================
# 🐍 Python Development Configuration
# =============================================================================

# Python path configuration (ojo: python3.* es frágil; mantener si te funciona)
export PYTHONPATH="${PYTHONPATH}:${HOME}/.local/lib/python3.*/site-packages"

export PYTHON_CONFIGURE_OPTS="--enable-shared"
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Poetry configuration
export POETRY_VENV_IN_PROJECT=1
export POETRY_CACHE_DIR="${HOME}/.cache/pypoetry"

# pip configuration
export PIP_REQUIRE_VIRTUALENV=true
export PIP_DISABLE_PIP_VERSION_CHECK=1

# Python development aliases
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'
alias deactivate='deactivate'

pyclean() {
  find . -type f -name "*.py[co]" -delete
  find . -type d -name "__pycache__" -delete
  find . -type d -name "*.egg-info" -exec rm -rf {} +
  find . -type d -name ".pytest_cache" -exec rm -rf {} +
  find . -type d -name ".mypy_cache" -exec rm -rf {} +
  echo "🧹 Python cache files cleaned"
}

pyreq() {
  if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
  elif [ -f "pyproject.toml" ]; then
    poetry install
  elif [ -f "Pipfile" ]; then
    pipenv install
  else
    echo "❌ No requirements file found (requirements.txt, pyproject.toml, or Pipfile)"
  fi
}

# No pises el binario pytest con una función homónima
pytest_run() {
  if command -v pytest &> /dev/null; then
    python -m pytest "$@"
  else
    python -m unittest discover -s tests -p "test_*.py" "$@"
  fi
}
alias pytest='pytest_run'

# Python version management
if command -v pyenv &> /dev/null; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Conda configuration
if [ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]; then
  source "${HOME}/miniconda3/etc/profile.d/conda.sh"
elif [ -f "${HOME}/anaconda3/etc/profile.d/conda.sh" ]; then
  source "${HOME}/anaconda3/etc/profile.d/conda.sh"
fi

# =============================================================================
# Editor
# =============================================================================

export EDITOR='nvim'

# =============================================================================
# Additional PATH Exports
# =============================================================================

# Local binaries (includes Cursor CLI)
export PATH="$PATH:$HOME/.local/bin"

# NPM Global packages
export PATH="$HOME/.npm-global/bin:$PATH"

# Local config (apikeys) - optional
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Powerlevel10k config (load once at the end)
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
[[ -f ~/dotfiles/powerlevel10k/p10k.zsh ]] && source ~/dotfiles/powerlevel10k/p10k.zsh