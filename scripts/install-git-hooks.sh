#!/usr/bin/env bash
# Configure repository-local native Git hooks for this checkout.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "ERROR: install-git-hooks must run inside a Git repository." >&2
	exit 1
}
hooks_dir="$repo_root/.githooks"

if [[ ! -d "$hooks_dir" ]]; then
	echo "ERROR: hooks directory not found: $hooks_dir" >&2
	exit 1
fi

for hook in pre-commit post-commit; do
	if [[ ! -x "$hooks_dir/$hook" ]]; then
		echo "ERROR: hook is missing or not executable: $hooks_dir/$hook" >&2
		exit 1
	fi
done

current_hooks_path="$(git -C "$repo_root" config --local --get core.hooksPath || true)"
case "$current_hooks_path" in
"")
	git -C "$repo_root" config --local core.hooksPath .githooks
	echo "OK: configured local core.hooksPath=.githooks"
	;;
.githooks)
	echo "OK: local core.hooksPath is already .githooks"
	;;
*)
	echo "ERROR: local core.hooksPath is already '$current_hooks_path'; refusing to overwrite it." >&2
	echo "Resolve it manually, then rerun: make install-git-hooks" >&2
	exit 1
	;;
esac
