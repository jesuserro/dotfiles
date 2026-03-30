#!/usr/bin/env bash
set -euo pipefail

WRAPPER_SOURCE="${DOTFILES_ROOT:-$HOME/dotfiles}/local/bin/git-ai-wrapper"
WRAPPER_TARGET="${HOME}/.local/bin/git-ai-wrapper"

main() {
    if [[ ! -f "$WRAPPER_SOURCE" ]]; then
        echo "Error: Source wrapper not found at $WRAPPER_SOURCE" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$WRAPPER_TARGET")"

    if [[ -f "$WRAPPER_TARGET" ]]; then
        echo "Removing existing wrapper at $WRAPPER_TARGET"
        rm -f "$WRAPPER_TARGET"
    fi

    cp "$WRAPPER_SOURCE" "$WRAPPER_TARGET"
    chmod +x "$WRAPPER_TARGET"

    echo "Installed git-ai-wrapper to $WRAPPER_TARGET"

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo ""
        echo "Warning: ~/.local/bin is not in your PATH."
        echo "Add this to your shell config:"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

main "$@"
