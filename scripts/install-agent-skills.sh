#!/usr/bin/env bash
# Install opt-in external AI skills governed by this dotfiles repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${DOTFILES_ROOT:-${SCRIPT_DIR}/..}" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"
# shellcheck source=scripts/update/lib/results.sh
source "${SCRIPT_DIR}/update/lib/results.sh"
# shellcheck source=scripts/update/lib/logging.sh
source "${SCRIPT_DIR}/update/lib/logging.sh"
# shellcheck source=scripts/update/lib/node_runtime.sh
source "${SCRIPT_DIR}/update/lib/node_runtime.sh"

dry_run=0
run_dir=""
overlay=""
original_path="${PATH}"
npm_prefix="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-${HOME}/.npm-global}}"
readonly CANONICAL_SKILLS_DIR="${DOTFILES_ROOT}/ai/assets/skills"
readonly MATT_SKILL_SOURCE="mattpocock/skills"
readonly INSTALL_CMD=(npx skills add "${MATT_SKILL_SOURCE}" -y -g)
readonly -a MATT_ROOT_SKILL_NAMES=(
	caveman
	design-an-interface
	diagnose
	edit-article
	git-guardrails-claude-code
	grill-me
	grill-with-docs
	handoff
	improve-codebase-architecture
	migrate-to-shoehorn
	obsidian-vault
	prototype
	qa
	request-refactor-plan
	review
	scaffold-exercises
	setup-matt-pocock-skills
	setup-pre-commit
	tdd
	teach
	to-issues
	to-prd
	triage
	ubiquitous-language
	write-a-skill
	writing-beats
	writing-fragments
	writing-shape
	zoom-out
)

usage() {
	cat <<'EOF'
Usage: scripts/install-agent-skills.sh [--dry-run]

Installs the opt-in external Matt Pocock Skills catalog governed by dotfiles.

Current v1 source:
  - mattpocock/skills (full catalog)

After install, removes accidental Matt symlinks from ai/assets/skills/ so the
canonical local tree stays clean.

This script never runs from make update. Public targets:
  make install-mattpocock-skills
  make update-ai-skills
EOF
}

dry() {
	[[ "${dry_run}" -eq 1 ]] || install_is_truthy "${DRY_RUN:-}"
}

print_command() {
	printf '%q' "${INSTALL_CMD[0]}"
	local arg
	for arg in "${INSTALL_CMD[@]:1}"; do
		printf ' %q' "${arg}"
	done
	printf '\n'
}

cleanup() {
	PATH="${original_path}"
	node_runtime_cleanup_overlay "${overlay:-}"
	if [[ -n "${run_dir:-}" && -d "${run_dir}" ]]; then
		rmdir "${run_dir}" 2>/dev/null || true
	fi
}

find_bin() {
	if command -v find >/dev/null 2>&1; then
		command -v find
	elif [[ -x /usr/bin/find ]]; then
		printf '/usr/bin/find\n'
	fi
}

cleanup_mattpocock_repo_symlinks() {
	local find_cmd path removed=0

	if [[ ! -d "${CANONICAL_SKILLS_DIR}" ]]; then
		return 0
	fi

	find_cmd="$(find_bin || true)"
	if [[ -n "${find_cmd}" ]]; then
		while IFS= read -r -d '' path || [[ -n "${path:-}" ]]; do
			if dry; then
				info "DRY_RUN: would remove Matt symlink: ${path}"
				continue
			fi

			rm -f "${path}"
			info "Removed Matt symlink from canonical skills tree: ${path}"
			removed=$((removed + 1))
		done < <("${find_cmd}" "${CANONICAL_SKILLS_DIR}" -type l -print0 2>/dev/null)
	else
		for name in "${MATT_ROOT_SKILL_NAMES[@]}"; do
			path="${CANONICAL_SKILLS_DIR}/${name}"
			[[ -L "${path}" ]] || continue

			if dry; then
				info "DRY_RUN: would remove Matt symlink: ${path}"
				continue
			fi

			rm -f "${path}"
			info "Removed Matt symlink from canonical skills tree: ${path}"
			removed=$((removed + 1))
		done
	fi

	if [[ -e "${CANONICAL_SKILLS_DIR}/mattpocock" ]]; then
		if dry; then
			info "DRY_RUN: would remove vendor path: ${CANONICAL_SKILLS_DIR}/mattpocock"
		else
			rm -rf "${CANONICAL_SKILLS_DIR}/mattpocock"
			info "Removed vendor path from canonical skills tree: ${CANONICAL_SKILLS_DIR}/mattpocock"
			removed=$((removed + 1))
		fi
	fi

	if ! dry && [[ "${removed}" -gt 0 ]]; then
		ok "Removed ${removed} accidental Matt artifact(s) from ai/assets/skills/"
	fi
}

assert_canonical_skills_clean() {
	local find_cmd link

	find_cmd="$(find_bin || true)"
	if [[ -n "${find_cmd}" ]]; then
		while IFS= read -r -d '' link || [[ -n "${link:-}" ]]; do
			fail "Canonical skills tree still contains symlink: ${link}"
			exit 1
		done < <("${find_cmd}" "${CANONICAL_SKILLS_DIR}" -type l -print0 2>/dev/null)
	else
		for name in "${MATT_ROOT_SKILL_NAMES[@]}"; do
			link="${CANONICAL_SKILLS_DIR}/${name}"
			if [[ -L "${link}" ]]; then
				fail "Canonical skills tree still contains symlink: ${link}"
				exit 1
			fi
		done
	fi

	if [[ -e "${CANONICAL_SKILLS_DIR}/mattpocock" ]]; then
		fail "Canonical skills tree must not contain ai/assets/skills/mattpocock/"
		exit 1
	fi
}

fail_with_node_hint() {
	fail "$1"
	printf '  make install-node-stack\n' >&2
	exit 1
}

activate_managed_node_if_needed() {
	node_runtime_probe
	if [[ "${NODE_RUNTIME_EFFECTIVE_OK}" -eq 1 ]]; then
		info "Node runtime: ${NODE_RUNTIME_EFFECTIVE_VERSION} (${NODE_RUNTIME_EFFECTIVE_PATH})"
		return 0
	fi
	if [[ "${NODE_RUNTIME_MANAGED_OK}" -eq 1 ]]; then
		run_dir="$(mktemp -d -t install-agent-skills.XXXXXX)"
		overlay="$(node_runtime_create_overlay "${run_dir}" "${NODE_RUNTIME_MANAGED_PATH}")"
		PATH="$(node_runtime_controlled_path "${overlay}" "${npm_prefix}" "${original_path}")"
		export PATH

		local active_node active_version
		active_node="$(command -v node 2>/dev/null || true)"
		active_version="$(node --version 2>/dev/null || true)"
		if [[ "${active_node}" != "${overlay}/node" ]] || ! node_runtime_version_satisfies "${active_version}" "${NODE_RUNTIME_MIN_MAJOR}"; then
			fail_with_node_hint "Managed Node overlay did not activate cleanly; expected ${overlay}/node, got ${active_node:-missing} ${active_version:-unknown}. Install or repair the Node stack first:"
		fi
		info "Node runtime for external skills: switched from ${NODE_RUNTIME_EFFECTIVE_VERSION:-missing} (${NODE_RUNTIME_EFFECTIVE_ORIGIN}) to ${NODE_RUNTIME_MANAGED_VERSION} (${NODE_RUNTIME_MANAGED_PATH})"
		return 0
	fi

	fail_with_node_hint "Node.js runtime is missing or below required >=${NODE_RUNTIME_MIN_MAJOR}; no compatible managed runtime is available. Install or repair the Node stack first:"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run)
		dry_run=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		printf 'install-agent-skills.sh: unknown option: %s\n' "$1" >&2
		usage >&2
		exit 2
		;;
	esac
done

trap cleanup EXIT INT TERM

if dry; then
	info "DRY_RUN: would install Matt Pocock external skills catalog"
	printf '[DRY_RUN] Would run: '
	print_command
	cleanup_mattpocock_repo_symlinks
	exit 0
fi

activate_managed_node_if_needed

if ! command -v npx >/dev/null 2>&1; then
	fail "npx not found. Install or repair the Node stack first:"
	printf '  make install-node-stack\n' >&2
	exit 1
fi

info "Installing Matt Pocock external skills catalog"
"${INSTALL_CMD[@]}"
cleanup_mattpocock_repo_symlinks
assert_canonical_skills_clean
ok "Matt Pocock skills catalog installed/updated"
