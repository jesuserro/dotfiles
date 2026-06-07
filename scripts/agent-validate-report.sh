#!/usr/bin/env bash
# Generate a Markdown report from an agent validation run (read-only wrapper).
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REPORT_DIR="${AGENT_VALIDATE_REPORT_DIR:-${DOTFILES_DIR}/build/agent-validation}"
REPORT_PATH="${AGENT_VALIDATE_REPORT_PATH:-${REPORT_DIR}/latest.md}"
VALIDATE_CMD="${AGENT_VALIDATE_CMD:-make agent-validate}"
TMP_OUTPUT="$(mktemp -t agent-validate-report.XXXXXX)"

cleanup() {
	rm -f "${TMP_OUTPUT}"
}
trap cleanup EXIT INT TERM

git_value() {
	if git -C "${DOTFILES_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		git -C "${DOTFILES_DIR}" "$@" 2>/dev/null || printf 'unknown'
	else
		printf 'unknown'
	fi
}

run_validation() {
	local exit_code=0
	(
		cd "${DOTFILES_DIR}"
		# shellcheck disable=SC2086
		eval "${VALIDATE_CMD}"
	) >"${TMP_OUTPUT}" 2>&1 || exit_code=$?
	printf '%s' "${exit_code}"
}

write_report() {
	local exit_code="$1"
	local verdict branch commit timestamp
	local report_parent

	verdict="FAIL"
	[[ "${exit_code}" -eq 0 ]] && verdict="PASS"

	branch="$(git_value branch --show-current)"
	commit="$(git_value rev-parse --short HEAD)"
	timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
	report_parent="$(dirname "${REPORT_PATH}")"
	mkdir -p "${report_parent}"

	{
		printf '# Agent Validation Report\n\n'
		printf '## Metadata\n\n'
		printf '| Field | Value |\n'
		printf '|-------|-------|\n'
		printf '| Timestamp | %s |\n' "${timestamp}"
		printf '| Repo | %s |\n' "${DOTFILES_DIR}"
		printf '| Branch | %s |\n' "${branch}"
		printf '| Commit | %s |\n' "${commit}"
		printf '| Report path | %s |\n\n' "${REPORT_PATH}"

		printf '## Verdict\n\n'
		printf '**%s** (exit code %s)\n\n' "${verdict}" "${exit_code}"

		printf '## Command\n\n'
		printf '    cd %s\n' "${DOTFILES_DIR}"
		printf '    %s\n\n' "${VALIDATE_CMD}"

		printf '## Output\n\n'
		printf '```text\n'
		cat "${TMP_OUTPUT}"
		printf '\n```\n\n'

		printf '## Known Issues\n\n'
		if [[ -d "${DOTFILES_DIR}/.claude/skills" ]]; then
			printf '%s\n' '- Checkout contains `.claude/skills/` — violates [ADR 0004](docs/adr/0004-ai-assets-not-materialized.md). Remove this directory from the repo; agent surfaces belong in HOME, not in the dotfiles checkout.'
		else
			printf '%s\n' '- (none detected)'
		fi
		if [[ "${exit_code}" -ne 0 ]] && grep -q '\.claude/skills' "${TMP_OUTPUT}" 2>/dev/null; then
			printf '%s\n' '- Validation output references `.claude/skills/` — consistent with ADR 0004 governance failure.'
		fi
		printf '\n'

		printf '## Next Steps\n\n'
		if [[ "${exit_code}" -eq 0 ]]; then
			printf '%s\n' '- Attach this report to handoffs or PR context if useful.'
			printf '%s\n' '- For stricter checks before merge, consider `make agent-validate-full`.'
		else
			printf '%s\n' '- Fix reported failures before handoff; this report does not replace remediation.'
			if [[ -d "${DOTFILES_DIR}/.claude/skills" ]]; then
				printf '%s\n' '- Remove `.claude/skills/` from the checkout (see ADR 0004).'
			fi
			printf '%s\n' '- Re-run: `make agent-validate-report` or `make agent-validate`.'
			printf '%s\n' '- For changed-files only: `make agent-validate-changed`.'
		fi
	} >"${REPORT_PATH}"

	printf '==> Wrote %s\n' "${REPORT_PATH}"
	printf '==> Verdict: %s (exit %s)\n' "${verdict}" "${exit_code}"
}

main() {
	local exit_code
	exit_code="$(run_validation)"
	write_report "${exit_code}"
	return "${exit_code}"
}

main "$@"
