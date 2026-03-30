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

backup_settings() {
    if [[ -f "$CURSOR_SETTINGS" ]]; then
        if python3 -c "import json; json.load(open('$CURSOR_SETTINGS', encoding='utf-8'))" 2>/dev/null; then
            cp "$CURSOR_SETTINGS" "$CURSOR_SETTINGS_BACKUP"
            echo "Backed up existing settings to $CURSOR_SETTINGS_BACKUP"
        else
            echo "Error: Existing settings file is not valid JSON" >&2
            exit 1
        fi
    fi
}

update_settings() {
    local git_path="$1"

    if [[ ! -f "$CURSOR_SETTINGS" ]]; then
        local dir
        dir=$(dirname "$CURSOR_SETTINGS")
        mkdir -p "$dir"
        echo "{}" >"$CURSOR_SETTINGS"
    fi

    if ! python3 -c "import json; json.load(open('$CURSOR_SETTINGS', encoding='utf-8'))" 2>/dev/null; then
        echo "Error: settings.json is not valid JSON and no backup exists" >&2
        exit 1
    fi

    local tmp_file
    tmp_file=$(mktemp)
    trap "rm -f '$tmp_file'" EXIT

    python3 <<PYEOF
import json
import sys

settings_file = "$CURSOR_SETTINGS"
git_path = "$git_path"

try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        settings = json.load(f)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON in settings.json: {e}", file=sys.stderr)
    sys.exit(1)

settings['git.path'] = git_path

with open("$tmp_file", 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

import shutil
shutil.move("$tmp_file", settings_file)
PYEOF

    echo "Updated git.path to: $git_path"
    echo "(in editor User settings: $CURSOR_SETTINGS)"
}

migrate_legacy_cursor_settings() {
    if [[ ! -f "$LEGACY_CURSOR_SETTINGS" ]]; then
        return 0
    fi
    if ! python3 -c "import json; json.load(open('$LEGACY_CURSOR_SETTINGS', encoding='utf-8'))" 2>/dev/null; then
        echo "Warning: $LEGACY_CURSOR_SETTINGS exists but is not valid JSON; skipping migration" >&2
        return 0
    fi

    python3 <<'PYEOF'
import json
import os
import sys

legacy = os.environ["LEGACY_CURSOR_SETTINGS"]
target = os.environ["CURSOR_SETTINGS"]
wrapper = os.environ["WRAPPER_PATH"]

try:
    with open(legacy, "r", encoding="utf-8") as f:
        old = json.load(f)
except json.JSONDecodeError:
    sys.exit(0)

if old.get("git.path") != wrapper:
    sys.exit(0)

# Remove stale git.path from legacy file so the editor is not misled into thinking it is configured there.
del old["git.path"]
if len(old) == 0:
    os.remove(legacy)
    print(f"Migrated: removed legacy-only file {legacy} (git.path now lives in editor User settings)")
else:
    with open(legacy, "w", encoding="utf-8") as f:
        json.dump(old, f, indent=2)
        f.write("\n")
    print(f"Migrated: removed git.path from {legacy} (editor reads {target})")
PYEOF
}

main() {
    export LEGACY_CURSOR_SETTINGS CURSOR_SETTINGS WRAPPER_PATH

    if [[ ! -f "$WRAPPER_PATH" ]]; then
        echo "Error: git-ai-wrapper not found at $WRAPPER_PATH" >&2
        echo "Official path: run \`chezmoi apply\` (links into ~/.local/bin via run_after_13)." >&2
        echo "Alternative: DOTFILES_ROOT=\$HOME/dotfiles scripts/install-git-ai-wrapper.sh (same symlinks)." >&2
        exit 1
    fi

    backup_settings
    update_settings "$WRAPPER_PATH"
    migrate_legacy_cursor_settings

    echo ""
    echo "Enabled git-ai-wrapper in Cursor (editor User settings)."
    echo "Reload the Cursor window if Source Control still uses another git binary."
}

main "$@"
