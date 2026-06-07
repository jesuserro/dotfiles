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

gitnexus_home="${GITNEXUS_HOME:-$HOME/.gitnexus}"
registry_file="$gitnexus_home/registry.json"

if [[ -e "$gitnexus_home" && ! -w "$gitnexus_home" ]]; then
	echo "WARN: GitNexus post-commit skipped: ${gitnexus_home} is not writable." >&2
	echo "WARN: Fix ownership/permissions manually, then run: make gitnexus-status" >&2
	exit 0
fi

if [[ -e "$registry_file" && ! -w "$registry_file" ]]; then
	echo "WARN: GitNexus post-commit skipped: ${registry_file} is not writable." >&2
	echo "WARN: Check owner and permissions; do not run GitNexus with sudo." >&2
	exit 0
fi

if gitnexus_index_in_use "$repo_root"; then
	echo "WARN: GitNexus post-commit skipped: MCP/index lock is active; index may remain STALE." >&2
	echo "WARN: Close duplicate Cursor/GitNexus MCP sessions, then run: gnx-analyze-here --force --skip-agents-md --skip-skills" >&2
	exit 0
fi

timeout_seconds=30
if ! command -v timeout >/dev/null 2>&1; then
	echo "WARN: GitNexus post-commit refresh skipped: timeout command not found; run gnx-analyze-here --force --skip-agents-md --skip-skills manually." >&2
	exit 0
fi

# shellcheck disable=SC2016
timeout "${timeout_seconds}s" bash -c \
	'source "$1"; gitnexus_analyze_here --force --skip-agents-md --skip-skills' \
	bash "$runtime_lib"
refresh_status=$?

case "$refresh_status" in
0)
	echo "INFO: GitNexus post-commit refresh completed."
	;;
124 | 137)
	echo "WARN: GitNexus post-commit timed out after ${timeout_seconds}s; commit kept." >&2
	echo "WARN: If Cursor/GitNexus MCP is active, close duplicate sessions and run: gnx-analyze-here --force --skip-agents-md --skip-skills" >&2
	;;
*)
	echo "WARN: GitNexus post-commit refresh failed with exit code ${refresh_status}; commit kept." >&2
	echo "WARN: Run: gnx-analyze-here --force --skip-agents-md --skip-skills" >&2
	;;
esac

exit 0
