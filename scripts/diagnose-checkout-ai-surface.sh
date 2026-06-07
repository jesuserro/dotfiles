#!/usr/bin/env bash
# Read-only diagnostic for checkout-local .claude runtime surface (ADR 0004).
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_ROOT="${DOTFILES_DIR}/.claude"
SKILLS_ROOT="${CLAUDE_ROOT}/skills"
GITNEXUS_SKILLS="${SKILLS_ROOT}/gitnexus"
CANONICAL_GITNEXUS="${DOTFILES_DIR}/ai/assets/skills/gitnexus"

printf 'Checkout AI surface diagnostic (read-only)\n'
printf 'DOTFILES_DIR=%s\n\n' "${DOTFILES_DIR}"

if [[ ! -e "${CLAUDE_ROOT}" ]]; then
	printf 'OK: .claude/ is absent from checkout.\n'
	exit 0
fi

printf 'WARN: .claude/ exists in checkout (ADR 0004 violation).\n'
if [[ -L "${CLAUDE_ROOT}" ]]; then
	printf '  Type: symlink -> %s\n' "$(readlink "${CLAUDE_ROOT}")"
elif [[ -d "${CLAUDE_ROOT}" ]]; then
	printf '  Type: directory\n'
else
	printf '  Type: other (not directory/symlink)\n'
fi

if [[ -d "${GITNEXUS_SKILLS}" ]]; then
	printf '\nFound .claude/skills/gitnexus/\n'
	local_sample="${GITNEXUS_SKILLS}/gitnexus-cli/SKILL.md"
	if [[ -f "${local_sample}" ]] && grep -q 'npx gitnexus analyze' "${local_sample}" 2>/dev/null; then
		printf '  Pattern: upstream GitNexus skills (likely from gitnexus analyze without --skip-skills)\n'
	elif [[ -f "${local_sample}" ]] && [[ -f "${CANONICAL_GITNEXUS}/gitnexus-cli/SKILL.md" ]]; then
		if cmp -s "${local_sample}" "${CANONICAL_GITNEXUS}/gitnexus-cli/SKILL.md"; then
			printf '  Pattern: matches canonical ai/assets/skills/gitnexus/ (manual copy)\n'
		else
			printf '  Pattern: diverges from canonical ai/assets/skills/gitnexus/\n'
		fi
	fi
fi

printf '\nRemediation:\n'
printf '  rm -rf %s/.claude/\n' "${DOTFILES_DIR}"
printf '  Use gnx-analyze-here (dotfiles runtime injects --skip-skills) instead of npx gitnexus analyze.\n'
printf '  Canonical GitNexus skills: %s/\n' "${CANONICAL_GITNEXUS}"
printf '  See docs/adr/0004-ai-assets-not-materialized.md and docs/GITNEXUS_OPERATIONAL_POLICY.md\n'

exit 1
