#!/usr/bin/env bash
# Dotfiles operational agent gate — read-only, non-destructive.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VERBOSE="${AGENT_VALIDATE_VERBOSE:-0}"
SECURITY_ONLINE="${SECURITY_ONLINE:-0}"
FAILURES=0

log() {
	printf '==> %s\n' "$*"
}

warn() {
	printf 'WARN: %s\n' "$*" >&2
}

verbose() {
	if [[ "${VERBOSE}" == "1" ]]; then
		printf '    %s\n' "$*"
	fi
}

run_required() {
	local label="$1"
	shift
	log "${label}"
	if "$@"; then
		verbose "PASS: ${label}"
		return 0
	fi
	warn "FAIL: ${label}"
	FAILURES=$((FAILURES + 1))
}

run_optional() {
	local label="$1"
	shift
	log "${label} (informational)"
	if "$@"; then
		verbose "PASS: ${label}"
	else
		warn "SKIP/WARN: ${label} — non-blocking"
	fi
}

main() {
	log "Dotfiles agent validation gate (read-only)"
	verbose "DOTFILES_DIR=${DOTFILES_DIR}"
	verbose "SECURITY_ONLINE=${SECURITY_ONLINE}"

	if git -C "${DOTFILES_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		run_required "git diff whitespace check (diff --check HEAD)" \
			git -C "${DOTFILES_DIR}" diff --check HEAD || true
	else
		warn "Not a git worktree; skipping git diff --check"
	fi

	run_required "canonical skills structure" \
		bash "${DOTFILES_DIR}/scripts/validate-skills-structure.sh" || true

	run_required "MCP governance" \
		make -C "${DOTFILES_DIR}" --no-print-directory ai-mcp-governance || true

	run_required "changed-file validation" \
		env SECURITY_ONLINE="${SECURITY_ONLINE}" \
		bash "${DOTFILES_DIR}/scripts/agent-validate-changed.sh" || true

	run_required "documentation contract tests" \
		make -C "${DOTFILES_DIR}" --no-print-directory bats-docs || true

	run_required "agent regression index" \
		make -C "${DOTFILES_DIR}" --no-print-directory bats-agent || true

	run_required "update readiness (read-only)" \
		make -C "${DOTFILES_DIR}" --no-print-directory update-check || true

	run_optional "GitNexus status" \
		make -C "${DOTFILES_DIR}" --no-print-directory gitnexus-status || true

	printf '\n'
	if [[ "${FAILURES}" -eq 0 ]]; then
		log "Dotfiles agent validation completed successfully"
		return 0
	fi

	warn "Dotfiles agent validation failed (${FAILURES} required step(s))"
	if [[ -d "${DOTFILES_DIR}/.claude/skills" ]]; then
		warn "Checkout contains .claude/skills/ — violates ADR 0004; remove before skills gate passes"
	fi
	return 1
}

main "$@"
