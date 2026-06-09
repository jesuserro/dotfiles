#!/usr/bin/env bash
# Generate a Markdown report from an agent validation run (read-only wrapper).
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REPORT_DIR="${AGENT_VALIDATE_REPORT_DIR:-${DOTFILES_DIR}/build/agent-validation}"
REPORT_PATH="${AGENT_VALIDATE_REPORT_PATH:-${REPORT_DIR}/latest.md}"
DEFAULT_TARGET="agent-validate"
VALIDATE_TARGET="${AGENT_VALIDATE_TARGET:-}"
VALIDATE_CMD_LEGACY="${AGENT_VALIDATE_CMD:-}"
COMMAND_TEXT="make ${DEFAULT_TARGET}"
UNSUPPORTED_SELECTOR_MESSAGE="ERROR: unsupported validation selector for agent-validate-report. Use AGENT_VALIDATE_TARGET with one of: agent-validate agent-validate-changed agent-validate-full agent-validate-audit test-fast"
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

is_allowed_target() {
	case "$1" in
	agent-validate | agent-validate-changed | agent-validate-full | agent-validate-audit | test-fast)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

legacy_cmd_to_target() {
	case "$1" in
	"make agent-validate")
		printf '%s\n' 'agent-validate'
		;;
	"make agent-validate-changed")
		printf '%s\n' 'agent-validate-changed'
		;;
	"make agent-validate-full")
		printf '%s\n' 'agent-validate-full'
		;;
	"make agent-validate-audit")
		printf '%s\n' 'agent-validate-audit'
		;;
	"make test-fast")
		printf '%s\n' 'test-fast'
		;;
	*)
		return 1
		;;
	esac
}

resolve_target() {
	local target

	if [[ -n "${VALIDATE_TARGET}" ]]; then
		target="${VALIDATE_TARGET}"
	elif [[ -n "${VALIDATE_CMD_LEGACY}" ]]; then
		if ! target="$(legacy_cmd_to_target "${VALIDATE_CMD_LEGACY}")"; then
			printf '%s\n' "${UNSUPPORTED_SELECTOR_MESSAGE}" >&2
			printf '%s\n' "${UNSUPPORTED_SELECTOR_MESSAGE}" >"${TMP_OUTPUT}"
			return 2
		fi
		printf 'WARN: AGENT_VALIDATE_CMD is deprecated; use AGENT_VALIDATE_TARGET=%s\n' "${target}" >"${TMP_OUTPUT}"
	else
		target="${DEFAULT_TARGET}"
	fi

	if ! is_allowed_target "${target}"; then
		printf '%s\n' "${UNSUPPORTED_SELECTOR_MESSAGE}" >&2
		printf '%s\n' "${UNSUPPORTED_SELECTOR_MESSAGE}" >"${TMP_OUTPUT}"
		return 2
	fi

	printf '%s\n' "${target}"
}

run_validation() {
	local target="$1"
	local exit_code=0
	(
		cd "${DOTFILES_DIR}"
		make "${target}"
	) >>"${TMP_OUTPUT}" 2>&1 || exit_code=$?
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
		printf '    %s\n\n' "${COMMAND_TEXT}"

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
	local exit_code target

	if target="$(resolve_target)"; then
		COMMAND_TEXT="make ${target}"
		exit_code="$(run_validation "${target}")"
		write_report "${exit_code}"
		return "${exit_code}"
	else
		exit_code=$?
		COMMAND_TEXT='(not run: unsupported selector)'
		write_report "${exit_code}"
		return "${exit_code}"
	fi
}

main "$@"
