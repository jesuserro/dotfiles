#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/git-ai-cursor-path.sh
source "$SCRIPT_DIR/lib/git-ai-cursor-path.sh"
# shellcheck source=lib/git-ai-common.sh
source "$SCRIPT_DIR/lib/git-ai-common.sh"

LEGACY_CURSOR_SETTINGS="${HOME}/.cursor/settings.json"
CURSOR_SETTINGS="$(cursor_editor_user_settings_path)"
CURSOR_SETTINGS_BACKUP="${CURSOR_SETTINGS}.backup"
WRAPPER_PATH="$(git_ai_wrapper_target_path)"

restore_backup() {
    if [[ -f "$CURSOR_SETTINGS_BACKUP" ]]; then
        cp "$CURSOR_SETTINGS_BACKUP" "$CURSOR_SETTINGS"
        rm -f "$CURSOR_SETTINGS_BACKUP"
        echo "Restored settings from backup"
        return 0
    fi
    return 1
}

remove_git_path_key() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 0
    fi

    if ! python3 -c "import json; json.load(open('$file', encoding='utf-8'))" 2>/dev/null; then
        echo "Error: $file is not valid JSON" >&2
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp)
    trap "rm -f '$tmp_file'" EXIT

    python3 <<PYEOF
import json
import os
import sys

settings_file = "$file"

try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        settings = json.load(f)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON in settings.json: {e}", file=sys.stderr)
    sys.exit(1)

if 'git.path' in settings:
    del settings['git.path']
    print(f"Removed git.path from {settings_file}")
else:
    print(f"No git.path key found in {settings_file}")

with open("$tmp_file", 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

import shutil
shutil.move("$tmp_file", settings_file)
PYEOF
}

# On WSL, git.path may have been written only to the Windows host settings; a stale copy
# can remain under ~/.config/Cursor (Linux). Remove it when disabling.
remove_wsl_stale_linux_git_path_if_different() {
    if ! cursor_is_wsl_linux; then
        return 0
    fi
    local linux_native
    linux_native=$(cursor_linux_native_user_settings_path)
    if [[ "$linux_native" == "$CURSOR_SETTINGS" ]]; then
        return 0
    fi
    if [[ -f "$linux_native" ]]; then
        remove_git_path_key "$linux_native" || true
    fi
}

remove_wrapper() {
    if [[ -f "$WRAPPER_PATH" ]]; then
        rm -f "$WRAPPER_PATH"
        echo "Removed git-ai-wrapper from $WRAPPER_PATH"
    else
        echo "No wrapper found at $WRAPPER_PATH"
    fi
}

main() {
    local restore=false

    if [[ "${1:-}" == "--restore-backup" ]]; then
        restore=true
    fi

    if [[ "$restore" == "true" ]] || [[ -f "$CURSOR_SETTINGS_BACKUP" ]]; then
        if restore_backup; then
            :
        elif [[ "$restore" == "true" ]]; then
            echo "Warning: --restore-backup specified but no backup found"
        fi
    else
        remove_git_path_key "$CURSOR_SETTINGS" || exit 1
        remove_wsl_stale_linux_git_path_if_different
        if [[ -f "$LEGACY_CURSOR_SETTINGS" ]]; then
            remove_git_path_key "$LEGACY_CURSOR_SETTINGS" || true
        fi
    fi

    remove_wrapper

    echo ""
    echo "Disabled git-ai-wrapper in Cursor."
    echo "Cursor will now use system git directly (unless overridden elsewhere)."
}

main "$@"
