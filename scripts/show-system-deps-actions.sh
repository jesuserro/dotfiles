#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER="${DOTFILES_ROOT}/scripts/lib/system_deps.py"

usage() {
    cat <<'EOF'
Usage: scripts/show-system-deps-actions.sh [--include-optional] [--include-present] [--inventory PATH ...]

Shows recommended actions to reconcile declarative dependencies that are not
currently available. This is especially useful for external:* and
environment:* entries after running deps-check.
EOF
}

detect_default_inventories() {
    local os_id="" os_like=""
    local -a files=(
        "${DOTFILES_ROOT}/system/packages/common.yaml"
        "${DOTFILES_ROOT}/system/packages/tooling.yaml"
    )

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-}"
        os_like="${ID_LIKE:-}"
    fi

    if [[ "${os_id}" == "ubuntu" || "${os_id}" == "debian" || "${os_like}" == *"debian"* ]]; then
        files+=("${DOTFILES_ROOT}/system/packages/ubuntu.yaml")
    fi

    if [[ -r /proc/version ]] && grep -qi microsoft /proc/version; then
        files+=("${DOTFILES_ROOT}/system/packages/wsl.yaml")
    fi

    printf '%s\n' "${files[@]}"
}

format_subject() {
    local package="$1"
    local command_name="$2"

    if [[ "${package}" == "${command_name}" ]]; then
        printf '%s' "${package}"
    else
        printf '%s -> %s' "${package}" "${command_name}"
    fi
}

format_origin() {
    local manager="$1"
    local install_method="$2"

    if [[ "${manager}" == "apt" ]]; then
        printf 'apt'
    elif [[ -n "${install_method}" ]]; then
        printf '%s:%s' "${manager}" "${install_method}"
    else
        printf '%s' "${manager}"
    fi
}

include_optional=0
include_present=0
inventory_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-optional)
            include_optional=1
            shift
            ;;
        --include-present)
            include_present=1
            shift
            ;;
        --inventory)
            if [[ $# -lt 2 ]]; then
                echo "show-system-deps-actions.sh: --inventory requires a path" >&2
                exit 2
            fi
            inventory_args+=("--inventory" "$2")
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "show-system-deps-actions.sh: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ ! -x "${HELPER}" ]]; then
    echo "show-system-deps-actions.sh: helper not found: ${HELPER}" >&2
    exit 1
fi

if [[ ${#inventory_args[@]} -eq 0 ]]; then
    while IFS= read -r inventory; do
        inventory_args+=("--inventory" "${inventory}")
    done < <(detect_default_inventories)
fi

python_cmd="${PYTHON:-python3}"
if ! command -v "${python_cmd}" >/dev/null 2>&1; then
    echo "show-system-deps-actions.sh: python3 is required to read the inventory" >&2
    exit 1
fi

python_args=("${HELPER}" "actions" "${inventory_args[@]}")
if [[ ${include_optional} -eq 1 ]]; then
    python_args+=("--include-optional")
fi

shown=0

while IFS=$'\t' read -r requirement package command platform capability manager install_method action_kind action_summary action_command source_file; do
    [[ -n "${package}" ]] || continue

    present=0
    if command -v "${command}" >/dev/null 2>&1; then
        present=1
    fi

    if [[ ${present} -eq 1 && ${include_present} -ne 1 ]]; then
        continue
    fi

    shown=1
    subject="$(format_subject "${package}" "${command}")"
    origin="$(format_origin "${manager}" "${install_method}")"

    if [[ ${present} -eq 1 ]]; then
        printf 'OK   %-28s [%s]\n' "${subject}" "${origin}"
    elif [[ "${requirement}" == "required" ]]; then
        printf 'MISS %-28s [%s]\n' "${subject}" "${origin}"
    else
        printf 'SKIP %-28s [%s]\n' "${subject}" "${origin}"
    fi

    printf '  Why: %s\n' "${action_summary}"
    printf '  Do:  %s\n' "${action_command}"
    printf '\n'
done < <("${python_cmd}" "${python_args[@]}")

if [[ ${shown} -eq 0 ]]; then
    echo "No dependency actions to show."
fi
