#!/usr/bin/env bash
# Read-only scan for plaintext secrets in local agent cache surfaces (e.g. Codex shell snapshots).
# Never prints full secret values. Does not delete or modify files.
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: diagnose-secret-surfaces.sh [PATH...]

Read-only diagnostic for plaintext secrets in local cache files.

Default path (when no args): ~/.codex/shell_snapshots if it exists.

Detects GitHub tokens, MCP env exports, and generic sensitive assignments
(*_TOKEN, *_PASSWORD, *_SECRET, *_KEY, POSTGRES_DSN, MINIO_*).

Exit 0 when clean; exit 1 when matches are found.
Never prints complete secret values.

See docs/TOKEN_GITHUB_GH.md for remediation (delete Codex shell snapshots).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	usage
	exit 0
fi

# shellcheck disable=SC2016
redact_line() {
	printf '%s\n' "$1" | python3 -c '
import re
import sys

line = sys.stdin.read().rstrip("\n")

patterns = [
    (re.compile(r"ghp_[A-Za-z0-9_]{10,}"), "ghp_<redacted>"),
    (re.compile(r"github_pat_[A-Za-z0-9_]{10,}"), "github_pat_<redacted>"),
    (
        re.compile(
            r"(?i)((?:export\s+)?(?:GH_TOKEN|GITHUB_TOKEN|GITHUB_PERSONAL_ACCESS_TOKEN|POSTGRES_DSN|MINIO_[A-Z0-9_]+|[A-Z0-9_]*(?:TOKEN|PASSWORD|SECRET|KEY))\s*=\s*)(['\''\"]?)([^'\''\"\s#]+)"
        ),
        r"\1\2<redacted>",
    ),
    (
        re.compile(
            r"(?i)((?:export\s+)?(?:GH_TOKEN|GITHUB_TOKEN|GITHUB_PERSONAL_ACCESS_TOKEN|POSTGRES_DSN|MINIO_[A-Z0-9_]+|[A-Z0-9_]*(?:TOKEN|PASSWORD|SECRET|KEY))\s*=\s*)(['\''\"])([^'\''\"]+)(['\''\"])"
        ),
        r"\1\2<redacted>\4",
    ),
]

for pattern, repl in patterns:
    line = pattern.sub(repl, line)

sys.stdout.write(line)
'
}

GREP_PATTERN='GH_TOKEN|GITHUB_TOKEN|GITHUB_PERSONAL_ACCESS_TOKEN|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|POSTGRES_DSN|[A-Za-z0-9_]+_(TOKEN|PASSWORD|SECRET|KEY)=|MINIO_[A-Za-z0-9_]+='

declare -a SCAN_PATHS=()
if (($# > 0)); then
	SCAN_PATHS=("$@")
elif [[ -d "${HOME}/.codex/shell_snapshots" ]]; then
	SCAN_PATHS=("${HOME}/.codex/shell_snapshots")
fi

printf 'Secret surface diagnostic (read-only)\n'

if ((${#SCAN_PATHS[@]} == 0)); then
	printf 'OK: no default scan path (~/.codex/shell_snapshots absent) and no paths given.\n'
	exit 0
fi

printf 'Scan paths:\n'
for path in "${SCAN_PATHS[@]}"; do
	printf '  - %s\n' "${path}"
done
printf '\n'

declare -a MATCH_FILES=()
for path in "${SCAN_PATHS[@]}"; do
	if [[ ! -e "${path}" ]]; then
		printf 'WARN: path does not exist: %s\n' "${path}" >&2
		continue
	fi
	while IFS= read -r file; do
		MATCH_FILES+=("${file}")
	done < <(grep -RIlE "${GREP_PATTERN}" "${path}" 2>/dev/null || true)
done

if ((${#MATCH_FILES[@]} == 0)); then
	printf 'OK: no sensitive patterns found.\n'
	exit 0
fi

# Deduplicate while preserving order.
declare -A seen=()
declare -a UNIQUE_FILES=()
for file in "${MATCH_FILES[@]}"; do
	[[ -n "${seen[$file]+x}" ]] && continue
	seen[$file]=1
	UNIQUE_FILES+=("${file}")
done

printf 'WARN: %d file(s) with sensitive patterns:\n' "${#UNIQUE_FILES[@]}"
for file in "${UNIQUE_FILES[@]}"; do
	printf '  %s\n' "${file}"
done
printf '\nRedacted context (max 5 lines per file):\n'

for file in "${UNIQUE_FILES[@]}"; do
	printf -- '--- %s ---\n' "${file}"
	count=0
	while IFS= read -r line; do
		redact_line "${line}" || true
		printf '\n'
		count=$((count + 1))
		if ((count >= 5)); then
			break
		fi
	done < <(grep -nE "${GREP_PATTERN}" "${file}" 2>/dev/null | head -5)
done

printf '\nRemediation (manual, local HOME only):\n'
printf '  rm -f ~/.codex/shell_snapshots/*.sh\n'
printf '  Re-run: %s\n' "$(basename "$0")"
printf '  See docs/TOKEN_GITHUB_GH.md\n'

exit 1
