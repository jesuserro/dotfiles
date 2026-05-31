#!/usr/bin/env bats
# chezmoi-drift-report: read-only diagnostic (no chezmoi apply).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	REPORT="${DOTFILES_DIR}/scripts/chezmoi-drift-report.sh"
	INSTALL_MK="${DOTFILES_DIR}/install.mk"
}

@test "chezmoi-drift-report script exists and is bash" {
	[[ -f "${REPORT}" ]]
	[[ -x "${REPORT}" ]] || true
	head -1 "${REPORT}" | grep -q bash
}

@test "install.mk exposes make chezmoi-drift-report" {
	grep -q '^chezmoi-drift-report:' "${INSTALL_MK}"
	grep -q 'scripts/chezmoi-drift-report.sh' "${INSTALL_MK}"
}

@test "chezmoi-drift-report does not execute chezmoi apply" {
	# Documented manual apply may appear in echo/note lines only.
	run grep -E '^\s*chezmoi(\s|$).*apply' "${REPORT}"
	[[ "${status}" -eq 1 ]]
}

@test "chezmoi-drift-report does not invoke external installers" {
	assert_file_not_matches "${REPORT}" 'curl\s+.*get\.chezmoi'
	assert_file_not_matches "${REPORT}" 'apt-get\s+install'
	assert_file_not_matches "${REPORT}" 'npm\s+install'
}

@test "chezmoi-drift-report documents Codex as manual decision" {
	grep -q 'Codex' "${REPORT}"
	grep -qE 'manual|decision|MM' "${REPORT}"
	grep -q 'dot_codex/config.toml.tmpl' "${REPORT}" ||
		grep -q '~/.codex/config.toml' "${REPORT}"
}

@test "chezmoi-drift-report mentions acotado launcher apply only as documentation" {
	grep -q 'mcp-git-launcher' "${REPORT}"
	grep -q 'mcp-postgres-launcher' "${REPORT}"
	grep -q 'not a global' "${REPORT}" || grep -q 'global chezmoi apply' "${REPORT}"
}

@test "docs/CHEZMOI.md documents drift audit and defers Codex" {
	local doc="${DOTFILES_DIR}/docs/CHEZMOI.md"
	grep -q 'Drift aceptado y auditoría' "${doc}"
	grep -q 'make chezmoi-drift-report' "${doc}"
	grep -q 'Codex' "${doc}"
	grep -q 'chezmoi apply' "${doc}"
}
