#!/usr/bin/env bats
# Cross-doc consistency: no global chezmoi apply as normal day-to-day flow.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	GUIA="${DOTFILES_DIR}/docs/GUIA_MCP_AI.md"
	OPERATIONS="${DOTFILES_DIR}/docs/OPERATIONS.md"
}

@test "GUIA_MCP_AI.md mentions make chezmoi-drift-report" {
	grep -q 'make chezmoi-drift-report' "${GUIA}"
}

@test "GUIA_MCP_AI.md links to OPERATIONS_CHEATSHEET" {
	grep -q 'OPERATIONS_CHEATSHEET' "${GUIA}"
}

@test "GUIA_MCP_AI.md section 1 does not open with global chezmoi apply only" {
	local section
	section="$(awk '/^## 1\. Aplicar cambios/,/^## 2\./' "${GUIA}")"
	[[ -n "${section}" ]]
	echo "${section}" | grep -q 'make chezmoi-drift-report'
	# Bare global apply (no path argument) must not be the recommended first-step block.
	run bash -c "echo \"\${section}\" | grep -E 'chezmoi.*apply[[:space:]]*$'"
	[[ "${status}" -eq 1 ]]
}

@test "OPERATIONS.md existing-machine flow uses drift report not global apply" {
	local section
	section="$(awk '/^## Máquina existente/,/^## Cambios de zsh/' "${OPERATIONS}")"
	[[ -n "${section}" ]]
	echo "${section}" | grep -q 'make chezmoi-drift-report'
	echo "${section}" | grep -q 'OPERATIONS_CHEATSHEET'
	run bash -c "echo \"\${section}\" | grep -E 'chezmoi --source=.*apply[[:space:]]*$'"
	[[ "${status}" -eq 1 ]]
}

@test "OPERATIONS.md describes chezmoiscripts R as Run not phantom drift" {
	assert_file_not_matches "${OPERATIONS}" '[Ff]antasma|[Pp]hantom'
	grep -qiE 'R.*Run|Run.*apply|chezmoiscripts' "${OPERATIONS}"
	grep -q 'make chezmoi-drift-report' "${OPERATIONS}"
}

@test "global chezmoi apply is framed as bootstrap or conscious human action" {
	local doc line
	for doc in "${GUIA}" "${OPERATIONS}"; do
		run grep -n 'chezmoi.*apply' "${doc}"
		[[ "${status}" -eq 0 ]]
		while IFS= read -r line; do
			# Lines that mention bare/global apply must also qualify context on same or adjacent doc theme.
			if [[ "${line}" =~ chezmoi.*apply ]] && [[ ! "${line}" =~ /\.[a-zA-Z0-9_~/] ]] && [[ ! "${line}" =~ apply[[:space:]]+-i ]]; then
				run grep -Eiq 'bootstrap|inicial|consciente|manual|controlad|global no es|no es el flujo normal|DOTFILES_APPLY|recuperaci' "${doc}"
				[[ "${status}" -eq 0 ]]
			fi
		done < <(grep 'chezmoi.*apply' "${doc}" || true)
	done
}
