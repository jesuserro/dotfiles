# =============================================================================
# fzf — fuzzy finder shell integration
# =============================================================================
# Optional APT package (system/packages/ubuntu.yaml). Shell starts cleanly if
# fzf is missing or APT example scripts are absent. Do not rely on Homebrew
# or Vim Plug installs; those are separate legacy paths.

if command -v fzf >/dev/null 2>&1; then
  for fzf_script in \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/doc/fzf/examples/completion.zsh
  do
    if [[ -r "$fzf_script" ]]; then
      # shellcheck source=/dev/null
      source "$fzf_script"
    fi
  done
fi
