#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/git_flow_policy.sh
source "${SCRIPT_DIR}/lib/git_flow_policy.sh"

usage() {
	cat <<'EOF'
Usage: scripts/git_flow_policy_print.sh [--policy-file PATH]

Prints the effective Git flow policy as stable KEY=value lines.
EOF
}

policy_file=".git-flow-policy.env"
policy_file_explicit=0

while [[ $# -gt 0 ]]; do
	case "$1" in
	--policy-file)
		policy_file="${2:-}"
		if [[ -z "$policy_file" ]]; then
			echo "git_flow_policy_print.sh: --policy-file requires a path" >&2
			exit 2
		fi
		policy_file_explicit=1
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "git_flow_policy_print.sh: unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

git_flow_policy_set_defaults
if [[ -f "$policy_file" || "$policy_file_explicit" -eq 1 ]]; then
	git_flow_policy_load_file "$policy_file"
fi
git_flow_policy_validate
git_flow_policy_print
