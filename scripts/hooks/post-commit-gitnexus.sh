#!/usr/bin/env bash
set -u

if [[ "${DOTFILES_SKIP_HOOKS:-}" == "1" ]]; then
	echo "INFO: dotfiles hooks skipped (DOTFILES_SKIP_HOOKS=1)."
	exit 0
fi

if [[ "${DOTFILES_SKIP_GITNEXUS:-}" == "1" ]]; then
	echo "INFO: GitNexus post-commit skipped (DOTFILES_SKIP_GITNEXUS=1)."
	exit 0
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "WARN: GitNexus post-commit could not resolve repository root." >&2
	exit 0
}
cd "$repo_root" || {
	echo "WARN: GitNexus post-commit could not enter repository root." >&2
	exit 0
}

export DOTFILES_DIR="$repo_root"
runtime_lib="$repo_root/scripts/lib/gitnexus_runtime.sh"
if [[ ! -r "$runtime_lib" ]]; then
	echo "WARN: GitNexus post-commit skipped: runtime helper not found." >&2
	exit 0
fi
# shellcheck source=scripts/lib/gitnexus_runtime.sh
source "$runtime_lib"

if gitnexus_index_in_use "$repo_root"; then
	echo "WARN: GitNexus post-commit skipped: index is in use; run gnx-analyze-here --skip-agents-md later." >&2
	exit 0
fi

if ! gitnexus_analyze_here --skip-agents-md; then
	echo "WARN: GitNexus post-commit refresh failed; commit remains successful." >&2
fi

exit 0
