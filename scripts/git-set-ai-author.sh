#!/usr/bin/env bash
set -euo pipefail

AGENT_NAME="${1:-}"
GIT_REAL="${GIT_REAL:-/usr/bin/git}"
DOTFILES_ROOT="${HOME}/.dotfiles"

declare -A AGENT_EMAILS=(
    [cursor]="cursor-agent@dotfiles.local"
    [codex]="codex-agent@dotfiles.local"
    [opencode]="opencode-agent@dotfiles.local"
)

declare -A AGENT_DISPLAY_NAMES=(
    [cursor]="Cursor Agent"
    [codex]="Codex Agent"
    [opencode]="OpenCode Agent"
)

show_usage() {
    cat <<EOF
Usage: git-set-ai-author <agent>

Set the AI agent that will author commits in the current repository.

Arguments:
    cursor      Set Cursor Agent as author
    codex       Set Codex Agent as author
    opencode    Set OpenCode Agent as author
    human       Clear AI author (use your default git identity)
    status      Show current AI author for this repo
    list        List available AI agents

Examples:
    git-set-ai-author cursor
    git-set-ai-author human
    git-set-ai-author status

EOF
}

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]\{2,\}$ ]]; then
        return 0
    fi
    return 1
}

validate_identity_format() {
    local identity="$1"
    if [[ "$identity" =~ ^.+[[:space:]].+\@.+\..+$ ]] && 
       [[ "$identity" == *"<"* ]] && 
       [[ "$identity" == *">"* ]]; then
        return 0
    fi
    return 1
}

get_repo_root() {
    local repo_root
    repo_root=$("$GIT_REAL" rev-parse --show-toplevel 2>/dev/null) || {
        echo "Error: Not in a git repository" >&2
        exit 1
    }
    echo "$repo_root"
}

get_ai_author_file() {
    local repo_root="$1"
    echo "${repo_root}/.git/ai-author/current"
}

read_current_author() {
    local author_file="$1"
    if [[ -f "$author_file" ]]; then
        cat "$author_file"
    fi
}

write_author() {
    local author_file="$1"
    local identity="$2"
    local repo_root
    repo_root=$(dirname "$author_file")
    mkdir -p "$(dirname "$author_file")"
    echo "$identity" > "$author_file"
}

clear_author() {
    local author_file="$1"
    if [[ -f "$author_file" ]]; then
        rm -f "$author_file"
    fi
    rmdir "$(dirname "$author_file")" 2>/dev/null || true
}

list_agents() {
    echo "Available AI agents:"
    echo
    for agent in cursor codex opencode; do
        local display="${AGENT_DISPLAY_NAMES[$agent]}"
        local email="${AGENT_EMAILS[$agent]}"
        echo "  $agent  ->  $display <$email>"
    done
    echo
    echo "  human  ->  (use default git identity)"
}

show_status() {
    local repo_root="$1"
    local author_file
    author_file=$(get_ai_author_file "$repo_root")
    local current
    current=$(read_current_author "$author_file")

    if [[ -z "$current" ]]; then
        echo "No AI author set for this repository."
        echo "Default git identity will be used."
    else
        echo "Current AI author: $current"
    fi
}

main() {
    case "${AGENT_NAME}" in
        cursor|codex|opencode)
            local repo_root
            repo_root=$(get_repo_root)
            local author_file
            author_file=$(get_ai_author_file "$repo_root")
            local display="${AGENT_DISPLAY_NAMES[$AGENT_NAME]}"
            local email="${AGENT_EMAILS[$AGENT_NAME]}"
            local identity="${display} <${email}>"

            if ! validate_identity_format "$identity"; then
                echo "Error: Invalid identity format generated" >&2
                exit 1
            fi

            write_author "$author_file" "$identity"
            echo "Set AI author to: $identity"
            ;;
        human)
            local repo_root
            repo_root=$(get_repo_root)
            local author_file
            author_file=$(get_ai_author_file "$repo_root")
            clear_author "$author_file"
            echo "Cleared AI author. Using default git identity."
            ;;
        status)
            local repo_root
            repo_root=$(get_repo_root)
            show_status "$repo_root"
            ;;
        list)
            list_agents
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            echo "Error: Unknown agent '$AGENT_NAME'" >&2
            echo "Run 'git-set-ai-author --help' for usage." >&2
            exit 1
            ;;
    esac
}

main "$@"
