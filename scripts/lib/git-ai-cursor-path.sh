#!/usr/bin/env bash
# Cursor editor User settings.json path resolution (git.path).
# Sourced by git-set-ai-enable.sh and git-set-ai-disable.sh.
# Docs: docs/GIT_AI_CURSOR_SETTINGS.md
#
# Contract: if CURSOR_USER_SETTINGS_PATH is set, use it; else resolve by OS.
# On WSL Linux, prefer the Windows host path (Cursor UI) when /mnt/c and cmd.exe exist;
# otherwise fall back to ~/.config/Cursor/User/settings.json.
#
# Override: export CURSOR_USER_SETTINGS_PATH=/path/to/User/settings.json

# True when this shell runs as Linux inside WSL (kernel reports Microsoft/WSL).
cursor_is_wsl_linux() {
    [[ "$(uname -s)" == Linux ]] && [[ -f /proc/version ]] && grep -qiE 'microsoft|WSL' /proc/version
}

# Windows username for C:\Users\<name> (matches AppData\Roaming\Cursor).
cursor_wsl_windows_username() {
    local u
    if command -v cmd.exe >/dev/null 2>&1; then
        u=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
        [[ -n "$u" ]] && echo "$u" && return 0
    fi
    [[ -n "${USER:-}" ]] && echo "$USER"
}

# Path to Cursor User settings on the Windows host, visible from WSL via /mnt/c/...
# Returns 1 if the Windows drive is not available or username is empty.
cursor_wsl_windows_host_user_settings_path() {
    local win_user
    win_user=$(cursor_wsl_windows_username)
    [[ -z "$win_user" ]] && return 1
    [[ -d /mnt/c ]] || return 1
    echo "/mnt/c/Users/${win_user}/AppData/Roaming/Cursor/User/settings.json"
}

# Linux-native Cursor path (also used as WSL fallback when Windows host path is unavailable).
cursor_linux_native_user_settings_path() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json"
}

# Resolved path for editor User settings (where git.path belongs).
cursor_editor_user_settings_path() {
    if [[ -n "${CURSOR_USER_SETTINGS_PATH:-}" ]]; then
        echo "${CURSOR_USER_SETTINGS_PATH}"
        return 0
    fi

    case "$(uname -s)" in
        Darwin)
            echo "$HOME/Library/Application Support/Cursor/User/settings.json"
            ;;
        MINGW* | MSYS* | CYGWIN*)
            if [[ -n "${APPDATA:-}" ]]; then
                echo "$APPDATA/Cursor/User/settings.json"
            else
                echo "$HOME/AppData/Roaming/Cursor/User/settings.json"
            fi
            ;;
        Linux | *)
            if cursor_is_wsl_linux; then
                local win_path
                if win_path=$(cursor_wsl_windows_host_user_settings_path); then
                    echo "$win_path"
                    return 0
                fi
            fi
            cursor_linux_native_user_settings_path
            ;;
    esac
}
