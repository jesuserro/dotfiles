#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: clean-runtime-skills [--dry-run] [--prune-broken-symlinks] [--yes]

Scans runtime skill surfaces and, only with both --prune-broken-symlinks
and --yes, removes broken symlinks under allowed roots.

Allowed roots:
  ~/.claude/skills
  ~/.config/opencode/skills

Options:
  --dry-run                 List findings without deleting (default)
  --prune-broken-symlinks   Mark broken symlinks for pruning
  --yes                     Confirm pruning when paired with --prune-broken-symlinks
  --help                    Show this help
EOF
}

prune_broken=0
yes=0

while (($#)); do
	case "$1" in
	--dry-run)
		:
		;;
	--prune-broken-symlinks)
		prune_broken=1
		;;
	--yes)
		yes=1
		;;
	--help | -h)
		usage
		exit 0
		;;
	*)
		usage >&2
		exit 2
		;;
	esac
	shift
done

roots=(
	"${HOME}/.claude/skills"
	"${HOME}/.config/opencode/skills"
)

is_under_allowed_root() {
	local path="$1"
	local root
	for root in "${roots[@]}"; do
		case "${path}" in
		"${root}"/*)
			return 0
			;;
		esac
	done
	return 1
}

scan_entry() {
	local entry="$1"
	if [[ -L "${entry}" ]]; then
		if [[ -e "${entry}" ]]; then
			printf 'VALID-SYMLINK: %s -> %s\n' "${entry}" "$(readlink "${entry}")"
			return
		fi

		printf 'BROKEN-SYMLINK: %s -> %s\n' "${entry}" "$(readlink "${entry}")"
		if [[ "${prune_broken}" -eq 1 && "${yes}" -eq 1 ]]; then
			if is_under_allowed_root "${entry}"; then
				rm -- "${entry}"
				printf 'PRUNED: %s\n' "${entry}"
			else
				printf 'SKIP-OUTSIDE-ROOT: %s\n' "${entry}"
			fi
		elif [[ "${prune_broken}" -eq 1 ]]; then
			printf 'WOULD-PRUNE: %s (add --yes to delete)\n' "${entry}"
		else
			printf 'DRY-RUN: %s not deleted\n' "${entry}"
		fi
	elif [[ -d "${entry}" ]]; then
		printf 'UNMANAGED-DIR: %s (not touched)\n' "${entry}"
	elif [[ -f "${entry}" ]]; then
		printf 'UNMANAGED-FILE: %s (not touched)\n' "${entry}"
	else
		printf 'UNMANAGED-OTHER: %s (not touched)\n' "${entry}"
	fi
}

printf 'Runtime skills cleanup diagnostic\n'
if [[ "${prune_broken}" -eq 1 && "${yes}" -eq 1 ]]; then
	printf 'Mode: prune broken symlinks with explicit confirmation\n'
else
	printf 'Mode: dry-run\n'
fi

for root in "${roots[@]}"; do
	if [[ ! -e "${root}" && ! -L "${root}" ]]; then
		printf 'MISSING-ROOT: %s\n' "${root}"
		continue
	fi
	if [[ -L "${root}" ]]; then
		printf 'ROOT-SYMLINK: %s -> %s (not touched)\n' "${root}" "$(readlink "${root}")"
		continue
	fi
	if [[ ! -d "${root}" ]]; then
		printf 'UNUSABLE-ROOT: %s (not a directory)\n' "${root}"
		continue
	fi

	printf 'ROOT: %s\n' "${root}"
	while IFS= read -r entry; do
		scan_entry "${entry}"
	done < <(find "${root}" -mindepth 1 -maxdepth 1 -print | sort)
done

exit 0
