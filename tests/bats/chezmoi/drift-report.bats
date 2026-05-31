#!/usr/bin/env bats
# chezmoi-drift-report: read-only diagnostic (no chezmoi apply).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	REPORT="${DOTFILES_DIR}/scripts/chezmoi-drift-report.sh"
	INSTALL_MK="${DOTFILES_DIR}/install.mk"
	CHEZMOI_DOC="${DOTFILES_DIR}/docs/CHEZMOI.md"
	OPS_CHEATSHEET="${DOTFILES_DIR}/docs/OPERATIONS_CHEATSHEET.md"
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

@test "chezmoi-drift-report documents Codex governance and acotado apply" {
	grep -q 'Codex' "${REPORT}"
	grep -qE 'acotado|versioned|data\.codex|MM' "${REPORT}"
	grep -q 'dot_codex/private_config.toml.tmpl' "${REPORT}" ||
		grep -q '~/.codex/config.toml' "${REPORT}"
}

@test "chezmoi-drift-report mentions acotado launcher apply only as documentation" {
	grep -q 'mcp-git-launcher' "${REPORT}"
	grep -q 'mcp-postgres-launcher' "${REPORT}"
	grep -q 'mcp-gitnexus-launcher' "${REPORT}"
	grep -q 'mcp-filesystem-launcher' "${REPORT}"
	grep -q 'not a global' "${REPORT}" || grep -q 'global chezmoi apply' "${REPORT}"
}

@test "chezmoi-drift-report explains R means Run for chezmoiscripts" {
	grep -qiE 'R means Run|Run \(the hook' "${REPORT}"
	grep -q 'Scripts (.chezmoiscripts)' "${REPORT}"
	grep -q 'ACCEPTED: expected Chezmoi script run entries' "${REPORT}"
	grep -q 'run_before_00_backup_rc_files.sh.tmpl' "${REPORT}"
	grep -q 'run_after_00_gen_secrets.sh.tmpl' "${REPORT}"
}

@test "chezmoi-drift-report does not describe script R lines as phantom or orphan state" {
	assert_file_not_matches "${REPORT}" '[Pp]hantom'
	run grep -qiE 'orphan|huérfano|restos de renombre|old script|estado huérfano' "${REPORT}"
	[[ "${status}" -eq 1 ]]
}

@test "chezmoi-drift-report warns against global apply and forget for script R lines" {
	grep -qiE 'apply globally|global apply|apply global' "${REPORT}"
	grep -q 'chezmoi forget' "${REPORT}"
	grep -q 'mcp-secrets.env' "${REPORT}"
}

@test "chezmoi-drift-report documents optional local exclude scripts" {
	grep -q 'exclude = \["scripts"\]' "${REPORT}"
	grep -qiE 'optional local|not versioned|comodidad local' "${REPORT}"
}

@test "docs/CHEZMOI.md documents drift audit and Codex governance" {
	grep -q 'Drift aceptado y auditoría' "${CHEZMOI_DOC}"
	grep -q 'make chezmoi-drift-report' "${CHEZMOI_DOC}"
	grep -q 'Codex' "${CHEZMOI_DOC}"
	grep -q 'data.codex' "${CHEZMOI_DOC}"
	grep -q 'chezmoi apply' "${CHEZMOI_DOC}"
}

@test "docs/CHEZMOI.md explains script R as Run not removed" {
	grep -q 'Scripts `.chezmoiscripts` y columna `R`' "${CHEZMOI_DOC}"
	grep -qiE 'R.*Run|Run.*apply' "${CHEZMOI_DOC}"
	assert_file_not_matches "${CHEZMOI_DOC}" '[Pp]hantom'
	run grep -qiE 'restos del estado persistente|tras renombrar hooks' "${CHEZMOI_DOC}"
	[[ "${status}" -eq 1 ]]
}

@test "docs/OPERATIONS_CHEATSHEET.md describes script R as expected Run noise" {
	grep -qiE 'R.*Run|Run.*apply' "${OPS_CHEATSHEET}"
	grep -q 'make chezmoi-drift-report' "${OPS_CHEATSHEET}"
	assert_file_not_matches "${OPS_CHEATSHEET}" '[Ff]antasma'
	run grep -qi 'restos de estado' "${OPS_CHEATSHEET}"
	[[ "${status}" -eq 1 ]]
}
