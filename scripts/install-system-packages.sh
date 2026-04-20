#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER="${DOTFILES_ROOT}/scripts/lib/system_deps.py"

usage() {
    cat <<'EOF'
Usage: scripts/install-system-packages.sh [--dry-run] [--include-optional] [--inventory PATH ...]

Installs the declarative system dependency inventory for Ubuntu/Debian using apt-get.
EOF
}

is_debian_like() {
    local os_id="" os_like=""
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-}"
        os_like="${ID_LIKE:-}"
    fi

    [[ "${os_id}" == "ubuntu" || "${os_id}" == "debian" || "${os_like}" == *"debian"* ]]
}

default_inventories() {
    printf '%s\n' \
        "${DOTFILES_ROOT}/system/packages/common.yaml" \
        "${DOTFILES_ROOT}/system/packages/ubuntu.yaml"
}

dry_run=0
include_optional=0
inventory_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            dry_run=1
            shift
            ;;
        --include-optional)
            include_optional=1
            shift
            ;;
        --inventory)
            if [[ $# -lt 2 ]]; then
                echo "install-system-packages.sh: --inventory requires a path" >&2
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
            echo "install-system-packages.sh: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! is_debian_like; then
    echo "install-system-packages.sh: this installer currently supports only Debian/Ubuntu via apt-get" >&2
    exit 1
fi

if [[ ! -x "${HELPER}" ]]; then
    echo "install-system-packages.sh: helper not found: ${HELPER}" >&2
    exit 1
fi

if [[ ${#inventory_args[@]} -eq 0 ]]; then
    while IFS= read -r inventory; do
        inventory_args+=("--inventory" "${inventory}")
    done < <(default_inventories)
fi

python_cmd="${PYTHON:-python3}"
if ! command -v "${python_cmd}" >/dev/null 2>&1; then
    echo "install-system-packages.sh: python3 is required to read the inventory" >&2
    exit 1
fi

python_args=("${HELPER}" "packages" "--manager" "apt" "${inventory_args[@]}")
if [[ ${include_optional} -eq 1 ]]; then
    python_args+=("--include-optional")
fi

mapfile -t packages < <("${python_cmd}" "${python_args[@]}")

if [[ ${#packages[@]} -eq 0 ]]; then
    echo "install-system-packages.sh: no packages resolved from the selected inventory" >&2
    exit 1
fi

if command -v sudo >/dev/null 2>&1 && [[ ${EUID} -ne 0 ]]; then
    apt_runner=(sudo apt-get)
else
    apt_runner=(apt-get)
fi

echo "Resolved apt packages:"
printf '  - %s\n' "${packages[@]}"
echo ""

if [[ ${dry_run} -eq 1 ]]; then
	echo "Dry run:"
	printf '  '
	printf '%q ' "${apt_runner[@]}"
	printf 'update\n'
	printf '  '
	printf '%q ' "${apt_runner[@]}"
	printf 'install -y'
	printf ' %q' "${packages[@]}"
	printf '\n'
	exit 0
fi

"${apt_runner[@]}" update
DEBIAN_FRONTEND=noninteractive "${apt_runner[@]}" install -y "${packages[@]}"
