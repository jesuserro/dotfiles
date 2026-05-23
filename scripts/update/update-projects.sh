#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/update/lib/environment.sh
source "${SCRIPT_DIR}/lib/environment.sh"
# shellcheck source=scripts/update/lib/results.sh
source "${SCRIPT_DIR}/lib/results.sh"
# shellcheck source=scripts/update/lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"

RUN_DIR="${DOTFILES_UPDATE_RUN_DIR:-$(new_run_dir)}"
LOG_DIR="${RUN_DIR}/logs"
mkdir -p "$LOG_DIR"
result_init "${RUN_DIR}/projects-results.tsv"

section "Personal projects"
PROJECT_DIR="${JESUSERRO_DIR:-$HOME/proyectos/jesuserro}"
if [[ ! -d "$PROJECT_DIR/.git" ]]; then
	result_warn "Projects" "jesuserro" "repository not found at ${PROJECT_DIR}"
else
	if git -C "$PROJECT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
		run_step "Projects" "jesuserro git" "${LOG_DIR}/projects-jesuserro-git.log" git -C "$PROJECT_DIR" pull --rebase --autostash
	else
		result_warn "Projects" "jesuserro git" "current branch has no upstream; configure upstream before pulling"
	fi
	python_bin="${PROJECT_DIR}/.venv/bin/python"
	if command -v uv >/dev/null 2>&1 && [[ -x "$python_bin" ]]; then
		run_step "Projects" "RenderCV" "${LOG_DIR}/projects-rendercv.log" uv pip install --python "$python_bin" -U "rendercv[full]==2.7"
	else
		result_warn "Projects" "RenderCV" "uv or ${python_bin} missing; RenderCV pin 2.7 not refreshed"
	fi
fi

section "Projects summary"
result_print_group "Projects" "${RUN_DIR}/projects-results.tsv" "Projects"
if result_has_incidents "${RUN_DIR}/projects-results.tsv"; then
	echo "Completed with project incidents. Logs: ${LOG_DIR}"
else
	echo "Completed without recorded project incidents. Logs: ${LOG_DIR}"
fi
