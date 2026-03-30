#!/usr/bin/env bash
# Secundario / compatibilidad: misma materialización que Chezmoi (ln -sf).
# Camino oficial: chezmoi apply → run_after_13_link_git_ai_wrapper.sh.tmpl

set -euo pipefail

if command -v python3 >/dev/null 2>&1; then
    SCRIPT_DIR="$(python3 -c "import os,sys; print(os.path.dirname(os.path.realpath(sys.argv[1])))" "${BASH_SOURCE[0]}")"
else
    _s="${BASH_SOURCE[0]}"
    while [[ -h "$_s" ]]; do
        _d="$(cd "$(dirname "$_s")" && pwd)"
        _l="$(readlink "$_s")"
        [[ "$_l" == /* ]] && _s="$_l" || _s="$_d/$_l"
    done
    SCRIPT_DIR="$(cd "$(dirname "$_s")" && pwd)"
    unset _s _d _l
fi
# shellcheck source=lib/git-ai-common.sh
source "$SCRIPT_DIR/lib/git-ai-common.sh"

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

main() {
    if [[ ! -f "${DOTFILES_ROOT}/local/bin/git-ai-wrapper" ]]; then
        echo "Error: Source wrapper not found under ${DOTFILES_ROOT}/local/bin/git-ai-wrapper" >&2
        exit 1
    fi

    git_ai_link_dotfiles_bins "$DOTFILES_ROOT" "install-git-ai"

    if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        echo ""
        echo "Warning: ~/.local/bin is not in your PATH."
        echo "Add this to your shell config:"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

main "$@"
