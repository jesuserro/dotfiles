#!/usr/bin/env bats
# Cross-doc consistency: no global chezmoi apply as normal day-to-day flow.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	GUIA="${DOTFILES_DIR}/docs/GUIA_MCP_AI.md"
	OPERATIONS="${DOTFILES_DIR}/docs/OPERATIONS.md"
	AGENT_WORKFLOW="${DOTFILES_DIR}/docs/AGENT_WORKFLOW.md"
	AI_REPO_MAP="${DOTFILES_DIR}/docs/AI_REPO_MAP.md"
	VALIDATION_MATRIX="${DOTFILES_DIR}/docs/VALIDATION_MATRIX.md"
	AGENTS="${DOTFILES_DIR}/AGENTS.md"
	DOCS_README="${DOTFILES_DIR}/docs/README.md"
	AI_README="${DOTFILES_DIR}/ai/README.md"
	HANDOFFS_DIR="${DOTFILES_DIR}/ai/assets/handoffs"
	SKILLS_README="${DOTFILES_DIR}/ai/assets/skills/README.md"
	AGENT_REVIEW_SKILL="${DOTFILES_DIR}/ai/assets/skills/ops/dotfiles-agent-review/SKILL.md"
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

@test "docs/AGENT_WORKFLOW.md exists with required sections" {
	[[ -f "${AGENT_WORKFLOW}" ]]
	grep -q '^## 1\. Propósito' "${AGENT_WORKFLOW}"
	grep -q 'PLAN' "${AGENT_WORKFLOW}"
	grep -q 'BUILD' "${AGENT_WORKFLOW}"
	grep -q 'AUDIT' "${AGENT_WORKFLOW}"
	grep -q 'VALIDATION_MATRIX.md' "${AGENT_WORKFLOW}"
}

@test "docs/AI_REPO_MAP.md exists and distinguishes from STRUCTURE.md" {
	[[ -f "${AI_REPO_MAP}" ]]
	grep -q 'STRUCTURE.md' "${AI_REPO_MAP}"
	grep -qE 'No sustituye|diferencia|inventario' "${AI_REPO_MAP}"
	grep -q '^## 3\. Mapa por carpetas' "${AI_REPO_MAP}"
}

@test "docs/VALIDATION_MATRIX.md exists with required zones" {
	[[ -f "${VALIDATION_MATRIX}" ]]
	local zone
	for zone in \
		'zsh/' \
		'scripts/' \
		'scripts/update/' \
		'scripts/hooks/' \
		'ai/assets/skills/' \
		'ai/assets/mcps/' \
		'ai/runtime/mcp/' \
		'docs/' \
		'tests/' \
		'.chezmoiscripts/' \
		'dot_local/bin/' \
		'bin/' \
		'system/packages/' \
		'Makefile'; do
		grep -qF "${zone}" "${VALIDATION_MATRIX}" || {
			echo "missing zone: ${zone}" >&2
			return 1
		}
	done
}

@test "AGENTS.md links docs/AGENT_WORKFLOW.md after gitnexus block" {
	grep -q 'docs/AGENT_WORKFLOW.md' "${AGENTS}"
	# Manual section must follow the auto-generated gitnexus block.
	awk '/<!-- gitnexus:end -->/,0' "${AGENTS}" | grep -q 'AGENT_WORKFLOW.md'
}

@test "docs/README.md links agent-first docs" {
	grep -q 'AGENT_WORKFLOW.md' "${DOCS_README}"
	grep -q 'AI_REPO_MAP.md' "${DOCS_README}"
	grep -q 'VALIDATION_MATRIX.md' "${DOCS_README}"
}

@test "ai/README.md links agent workflow or repo map" {
	grep -qE 'AGENT_WORKFLOW\.md|AI_REPO_MAP\.md' "${AI_README}"
}

@test "handoffs README and five templates exist" {
	[[ -f "${HANDOFFS_DIR}/README.md" ]]
	local template
	for template in cursor-plan cursor-build cursor-audit codex-build chatgpt-review; do
		[[ -f "${HANDOFFS_DIR}/${template}.md" ]] || {
			echo "missing template: ${template}.md" >&2
			return 1
		}
	done
}

@test "each handoff template has required sections" {
	local template file
	for template in cursor-plan cursor-build cursor-audit codex-build chatgpt-review; do
		file="${HANDOFFS_DIR}/${template}.md"
		grep -qi 'modo de trabajo' "${file}" || {
			echo "${template}: missing modo de trabajo" >&2
			return 1
		}
		grep -qi 'alcance permitido' "${file}" || {
			echo "${template}: missing alcance permitido" >&2
			return 1
		}
		grep -qi 'fuera de alcance' "${file}" || {
			echo "${template}: missing fuera de alcance" >&2
			return 1
		}
		grep -qi 'formato de informe' "${file}" || {
			echo "${template}: missing formato de informe" >&2
			return 1
		}
	done
}

@test "handoff templates avoid triple-backtick code fences" {
	local template file
	for template in cursor-plan cursor-build cursor-audit codex-build chatgpt-review README; do
		file="${HANDOFFS_DIR}/${template}.md"
		run grep -q '```' "${file}"
		[[ "${status}" -eq 1 ]] || {
			echo "${template}: contains triple backticks" >&2
			return 1
		}
	done
}

@test "dotfiles-agent-review skill exists with required sections" {
	[[ -f "${AGENT_REVIEW_SKILL}" ]]
	grep -q '^name: dotfiles-agent-review' "${AGENT_REVIEW_SKILL}"
	grep -q '## When to Use' "${AGENT_REVIEW_SKILL}"
	grep -q '## Inputs Expected' "${AGENT_REVIEW_SKILL}"
	grep -q '## Checklist' "${AGENT_REVIEW_SKILL}"
	grep -q '## Output' "${AGENT_REVIEW_SKILL}"
}

@test "AGENT_WORKFLOW.md links handoffs and dotfiles-agent-review skill" {
	grep -q 'ai/assets/handoffs' "${AGENT_WORKFLOW}"
	grep -q 'dotfiles-agent-review' "${AGENT_WORKFLOW}"
}

@test "skills README registers dotfiles-agent-review" {
	grep -q 'dotfiles-agent-review' "${SKILLS_README}"
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
