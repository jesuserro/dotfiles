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
	echo "INFO: GitNexus MCP/lock detected; running forced post-commit refresh."
fi

timeout_seconds=30
if ! command -v timeout >/dev/null 2>&1; then
	echo "WARN: GitNexus post-commit refresh skipped: timeout command not found; run gitnexus analyze --force . manually." >&2
	exit 0
fi

# shellcheck disable=SC2016
timeout "${timeout_seconds}s" bash -c \
	'source "$1"; gitnexus_analyze_here --force --skip-agents-md' \
	bash "$runtime_lib"
refresh_status=$?

case "$refresh_status" in
0)
	echo "INFO: GitNexus post-commit refresh completed."
	;;
124 | 137)
	echo "WARN: GitNexus post-commit refresh timed out after ${timeout_seconds}s; run gitnexus analyze --force . manually." >&2
	;;
*)
	echo "WARN: GitNexus post-commit refresh failed; run gitnexus analyze --force . manually." >&2
	;;
esac

exit 0
