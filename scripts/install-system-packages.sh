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
		"${DOTFILES_ROOT}/system/packages/tooling.yaml" \
		"${DOTFILES_ROOT}/system/packages/ubuntu.yaml"

	if [[ -r /proc/version ]] && grep -qi microsoft /proc/version; then
		printf '%s\n' "${DOTFILES_ROOT}/system/packages/wsl.yaml"
	fi
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
	-h | --help)
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

# Safety belt: if a hyphen variant slipped through env (script called directly,
# bypassing the Make-level guard), force dry-run and warn. We never silently
# normalise DRY-RUN -> DRY_RUN; the goal is defensive safety, not convenience.
for _bad_var in "DRY-RUN" "dry-run" "Dry-Run" "DRYRUN"; do
	_bad_val="$(printenv "${_bad_var}" 2>/dev/null || true)"
	case "${_bad_val}" in
	1 | true | TRUE | yes | YES | on | ON)
		echo "install-system-packages.sh: detected unsupported env variant '${_bad_var}=${_bad_val}'; forcing --dry-run. Use DRY_RUN=1 next time." >&2
		dry_run=1
		;;
	esac
done
unset _bad_var _bad_val

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

# Preflight: check which packages have an installation candidate in APT.
# Avoids the opaque "E: Unable to locate package <x>" failure halfway through
# the install. system_deps.py 'packages' already returns required-only by
# default, so any package missing here counts as required and must abort.
#
# Parsing is done in pure bash to avoid SIGPIPE (exit 141) under `pipefail`
# when awk/head would close the pipe early before apt-cache flushes its output.
if command -v apt-cache >/dev/null 2>&1; then
	available_pkgs=()
	missing_pkgs=()
	for _pkg in "${packages[@]}"; do
		_policy_out="$(apt-cache policy "${_pkg}" 2>/dev/null || true)"
		_candidate=""
		while IFS= read -r _line; do
			if [[ "${_line}" == *Candidate:* ]]; then
				# Strip the "  Candidate: " prefix (trim leading whitespace + label).
				_candidate="${_line#*Candidate:}"
				_candidate="${_candidate## }"
				break
			fi
		done <<<"${_policy_out}"
		if [[ -z "${_candidate}" || "${_candidate}" == "(none)" ]]; then
			missing_pkgs+=("${_pkg}")
		else
			available_pkgs+=("${_pkg}")
		fi
	done
	unset _pkg _policy_out _candidate _line

	if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
		echo "APT preflight: the following required packages have no installation candidate in this distro's APT sources:" >&2
		printf '  - %s\n' "${missing_pkgs[@]}" >&2
		echo "" >&2
		echo "These packages should be classified as external (see system/packages/tooling.yaml)" >&2
		echo "or installed via a dedicated opt-in installer (e.g. 'make install-sops', 'make install-uv')." >&2
		echo "Aborting before apt-get install to avoid an opaque failure." >&2
		exit 2
	fi

	if [[ ${#available_pkgs[@]} -eq 0 ]]; then
		echo "APT preflight: no installable packages remain. Nothing to do." >&2
		exit 2
	fi
	packages=("${available_pkgs[@]}")
fi

"${apt_runner[@]}" update
DEBIAN_FRONTEND=noninteractive "${apt_runner[@]}" install -y "${packages[@]}"
