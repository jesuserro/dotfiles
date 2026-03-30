#!/usr/bin/env bash
# Shared helpers: ~/.local/bin materialization + repo / .git/ai-author paths.
# Cursor User/settings resolution stays in git-ai-cursor-path.sh.

# Default install location for symlinked binaries (official path with Chezmoi apply).
git_ai_local_bin_dir() {
    echo "${HOME}/.local/bin"
}

git_ai_wrapper_target_path() {
    echo "$(git_ai_local_bin_dir)/git-ai-wrapper"
}

git_ai_set_author_cli_target_path() {
    echo "$(git_ai_local_bin_dir)/git-set-ai-author"
}

# Symlink git-ai-wrapper and git-set-ai-author from a dotfiles source tree into ~/.local/bin.
# Optional second argument sets the log tag (default: git-ai).
git_ai_link_dotfiles_bins() {
    local source_dir="$1"
    local tag="${2:-git-ai}"
    local local_bin
    local_bin=$(git_ai_local_bin_dir)
    mkdir -p "$local_bin"
    echo "[$tag] Linking git-ai-wrapper and git-set-ai-author"
    ln -sf "${source_dir}/local/bin/git-ai-wrapper" "${local_bin}/git-ai-wrapper"
    echo "[$tag] Linked: ${local_bin}/git-ai-wrapper"
    ln -sf "${source_dir}/scripts/git-set-ai-author.sh" "${local_bin}/git-set-ai-author"
    echo "[$tag] Linked: ${local_bin}/git-set-ai-author"
}

# Repository root via GIT_REAL (empty if not inside a work tree).
git_ai_repo_root_or_empty() {
    local git_bin="${GIT_REAL:-/usr/bin/git}"
    "$git_bin" rev-parse --show-toplevel 2>/dev/null || true
}

# Print repo root or exit 1 (for CLI tools).
git_ai_repo_root_or_exit() {
    local root
    root=$(git_ai_repo_root_or_empty)
    if [[ -z "$root" ]]; then
        echo "Error: Not in a git repository" >&2
        exit 1
    fi
    echo "$root"
}

# Single-line state file for the current repo's AI author identity.
git_ai_author_state_path() {
    local repo_root="$1"
    echo "${repo_root}/.git/ai-author/current"
}
