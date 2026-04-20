#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER="${DOTFILES_ROOT}/scripts/lib/system_deps.py"

usage() {
    cat <<'EOF'
Usage: scripts/check-system-deps.sh [--include-optional] [--inventory PATH ...]

Checks the declarative system dependency inventory and reports which commands
are currently available in PATH.
EOF
}

detect_default_inventories() {
    local os_id="" os_like=""
    local -a files=("${DOTFILES_ROOT}/system/packages/common.yaml")

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-}"
        os_like="${ID_LIKE:-}"
    fi

    if [[ "${os_id}" == "ubuntu" || "${os_id}" == "debian" || "${os_like}" == *"debian"* ]]; then
        files+=("${DOTFILES_ROOT}/system/packages/ubuntu.yaml")
    fi

    printf '%s\n' "${files[@]}"
}

include_optional=0
inventory_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-optional)
            include_optional=1
            shift
            ;;
        --inventory)
            if [[ $# -lt 2 ]]; then
                echo "check-system-deps.sh: --inventory requires a path" >&2
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
            echo "check-system-deps.sh: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ ! -x "${HELPER}" ]]; then
    echo "check-system-deps.sh: helper not found: ${HELPER}" >&2
    exit 1
fi

if [[ ${#inventory_args[@]} -eq 0 ]]; then
    while IFS= read -r inventory; do
        inventory_args+=("--inventory" "${inventory}")
    done < <(detect_default_inventories)
fi

python_cmd="${PYTHON:-python3}"
if ! command -v "${python_cmd}" >/dev/null 2>&1; then
    echo "check-system-deps.sh: python3 is required to read the inventory" >&2
    exit 1
fi

python_args=("${HELPER}" "list" "${inventory_args[@]}")
if [[ ${include_optional} -eq 1 ]]; then
    python_args+=("--include-optional")
fi

required_ok=0
required_missing=0
optional_ok=0
optional_missing=0

format_subject() {
    local package="$1"
    local command_name="$2"

    if [[ "${package}" == "${command_name}" ]]; then
        printf '%s' "${package}"
    else
        printf '%s -> %s' "${package}" "${command_name}"
    fi
}

while IFS=$'\t' read -r requirement package command platform capability note source_file; do
    [[ -n "${package}" ]] || continue
    subject="$(format_subject "${package}" "${command}")"

    if command -v "${command}" >/dev/null 2>&1; then
        if [[ "${requirement}" == "required" ]]; then
            printf 'OK   %-28s [required]\n' "${subject}"
        else
            printf 'INFO %-28s [optional]\n' "${subject}"
        fi
        if [[ "${requirement}" == "required" ]]; then
            required_ok=$((required_ok + 1))
        else
            optional_ok=$((optional_ok + 1))
        fi
    else
        if [[ "${requirement}" == "required" ]]; then
            printf 'MISS %-28s [required]\n' "${subject}"
        else
            printf 'SKIP %-28s [optional]\n' "${subject}"
        fi
        if [[ "${requirement}" == "required" ]]; then
            required_missing=$((required_missing + 1))
        else
            optional_missing=$((optional_missing + 1))
        fi
    fi
done < <("${python_cmd}" "${python_args[@]}")

echo ""
printf 'Summary: required ok=%d missing=%d | optional ok=%d missing=%d\n' \
    "${required_ok}" "${required_missing}" "${optional_ok}" "${optional_missing}"

if [[ ${required_missing} -gt 0 ]]; then
    exit 1
fi
