#!/usr/bin/env bash
set -euo pipefail

if [[ "${DOTFILES_SKIP_HOOKS:-}" == "1" ]]; then
	echo "INFO: dotfiles hooks skipped (DOTFILES_SKIP_HOOKS=1)."
	exit 0
fi

if [[ "${DOTFILES_SKIP_TREEGEN:-}" == "1" ]]; then
	echo "INFO: treegen pre-commit skipped (DOTFILES_SKIP_TREEGEN=1)."
	exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "ERROR: treegen pre-commit could not resolve repository root." >&2
	exit 1
}
cd "$repo_root"

structure_file="$repo_root/STRUCTURE.md"
if [[ ! -f "$structure_file" ]]; then
	echo "INFO: treegen pre-commit skipped: STRUCTURE.md does not exist."
	exit 0
fi

before_hash="$(git hash-object "$structure_file")"
if ! "$repo_root/scripts/treegen.sh" --no-stage "$repo_root"; then
	echo "ERROR: treegen pre-commit failed; commit aborted." >&2
	exit 1
fi
after_hash="$(git hash-object "$structure_file")"

if [[ "$before_hash" != "$after_hash" ]]; then
	echo "ERROR: treegen updated STRUCTURE.md; commit aborted." >&2
	echo "Review the change, run 'git add STRUCTURE.md', and repeat 'git commit'." >&2
	exit 1
fi

exit 0
