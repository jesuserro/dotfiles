# =============================================================================
# Python dev
# =============================================================================

# Python path configuration (note: python3.* wildcard can be fragile; keep if it works for you)
export PYTHONPATH="${PYTHONPATH}:${HOME}/.local/lib/python3.*/site-packages"

export PYTHON_CONFIGURE_OPTS="--enable-shared"
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Poetry configuration
export POETRY_VENV_IN_PROJECT=1
export POETRY_CACHE_DIR="${HOME}/.cache/pypoetry"

# pip configuration
export PIP_REQUIRE_VIRTUALENV=true
export PIP_DISABLE_PIP_VERSION_CHECK=1

# Aliases
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Helpers
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

# Avoid shadowing the pytest binary with a same-named function
pytest_run() {
  if command -v pytest &> /dev/null; then
    python -m pytest "$@"
  else
    python -m unittest discover -s tests -p "test_*.py" "$@"
  fi
}
alias pytest='pytest_run'

# pyenv
if command -v pyenv &> /dev/null; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# conda
if [ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]; then
  source "${HOME}/miniconda3/etc/profile.d/conda.sh"
elif [ -f "${HOME}/anaconda3/etc/profile.d/conda.sh" ]; then
  source "${HOME}/anaconda3/etc/profile.d/conda.sh"
fi
