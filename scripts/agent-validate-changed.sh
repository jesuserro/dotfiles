#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SECURITY_ONLINE="${SECURITY_ONLINE:-0}"
TMP_DIR="$(mktemp -d -t agent-validate-changed.XXXXXX)"

cleanup() {
	rm -rf "${TMP_DIR}"
}
trap cleanup EXIT INT TERM

log() {
	printf '==> %s\n' "$*"
}

warn() {
	printf 'WARN: %s\n' "$*" >&2
}

require_cmd() {
	local cmd="$1"
	local install_hint="$2"

	if ! command -v "${cmd}" >/dev/null 2>&1; then
		printf 'Missing validation dependency: %s\n' "${cmd}" >&2
		printf 'Run: %s\n' "${install_hint}" >&2
		return 1
	fi
}

run_yamllint() {
	if command -v yamllint >/dev/null 2>&1; then
		yamllint -s "$@"
	elif command -v uvx >/dev/null 2>&1; then
		warn "yamllint is not installed; using temporary uvx fallback"
		uvx --from yamllint yamllint -s "$@"
	else
		require_cmd yamllint "make deps-install"
	fi
}

ensure_actionlint() {
	if command -v actionlint >/dev/null 2>&1; then
		return 0
	fi

	warn "actionlint missing; using temporary install-agent-tools fallback"
	local temp_home="${TMP_DIR}/agent-tools-home"
	mkdir -p "${temp_home}"
	HOME="${temp_home}" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only >/dev/null
	export PATH="${temp_home}/.local/bin:${PATH}"
}

ensure_osv_scanner() {
	if command -v osv-scanner >/dev/null 2>&1; then
		return 0
	fi

	warn "osv-scanner missing; using temporary install-agent-tools fallback"
	local temp_home="${TMP_DIR}/osv-tools-home"
	mkdir -p "${temp_home}"
	HOME="${temp_home}" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only >/dev/null
	export PATH="${temp_home}/.local/bin:${PATH}"
}

has_osv_scan_inputs() {
	find "${DOTFILES_DIR}" \
		\( -name 'package-lock.json' -o -name 'pnpm-lock.yaml' -o -name 'yarn.lock' \
		-o -name 'requirements*.txt' -o -name 'pyproject.toml' -o -name 'uv.lock' \
		-o -name 'go.mod' -o -name 'Cargo.lock' -o -name 'composer.lock' \) \
		-type f \
		! -path '*/.git/*' ! -path '*/.venv/*' ! -path '*/node_modules/*' \
		! -path '*/vendor/*' ! -path '*/__pycache__/*' \
		-print -quit | grep -q .
}

install_temp_gitleaks() {
	local repo="gitleaks/gitleaks"
	local api_url="https://api.github.com/repos/${repo}/releases/latest"
	local metadata="${TMP_DIR}/gitleaks-release.json"

	warn "gitleaks is not installed; using temporary official GitHub release fallback"
	curl -fsSL "${api_url}" -o "${metadata}"

	local version
	version="$(
		python3 - "${metadata}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    print(json.load(fh)["tag_name"].lstrip("v"))
PY
	)"

	local asset="gitleaks_${version}_linux_x64.tar.gz"
	local checksums="gitleaks_${version}_checksums.txt"
	local asset_url
	local checksums_url
	asset_url="$(
		python3 - "${metadata}" "${asset}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    release = json.load(fh)
for asset in release["assets"]:
    if asset["name"] == sys.argv[2]:
        print(asset["browser_download_url"])
        break
else:
    raise SystemExit(f"asset not found: {sys.argv[2]}")
PY
	)"
	checksums_url="$(
		python3 - "${metadata}" "${checksums}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    release = json.load(fh)
for asset in release["assets"]:
    if asset["name"] == sys.argv[2]:
        print(asset["browser_download_url"])
        break
else:
    raise SystemExit(f"asset not found: {sys.argv[2]}")
PY
	)"

	curl -fsSL "${asset_url}" -o "${TMP_DIR}/${asset}"
	curl -fsSL "${checksums_url}" -o "${TMP_DIR}/${checksums}"
	grep -E "[[:space:]]${asset}$" "${TMP_DIR}/${checksums}" >"${TMP_DIR}/gitleaks.sha256"
	(
		cd "${TMP_DIR}"
		sha256sum -c gitleaks.sha256 >/dev/null
		tar -xzf "${asset}" gitleaks
	)
	chmod +x "${TMP_DIR}/gitleaks"
	export PATH="${TMP_DIR}:${PATH}"
}

ensure_gitleaks() {
	if command -v gitleaks >/dev/null 2>&1; then
		return 0
	fi
	install_temp_gitleaks
}

run_local_security_scan() {
	ensure_gitleaks

	log "gitleaks working-tree scan"
	gitleaks detect --source "${DOTFILES_DIR}" --no-git --redact --no-banner
}

is_osv_infrastructure_failure() {
	local output_file="$1"

	grep -Eiq \
		'service unavailable|connection refused|timed out|network is unreachable|failed to connect|dial tcp|no such host|temporary failure in name resolution|api.*unavailable|could not reach|error fetching' \
		"${output_file}"
}

run_osv_online_scan() {
	if ! has_osv_scan_inputs; then
		log "osv-scanner skipped: no supported manifests or lockfiles found"
		return 0
	fi

	ensure_osv_scanner

	if ! command -v osv-scanner >/dev/null 2>&1; then
		printf 'Missing security dependency: osv-scanner\n' >&2
		printf 'Run: make install-agent-tools\n' >&2
		return 1
	fi

	log "osv-scanner repository scan (SECURITY_ONLINE=1)"
	local osv_output="${TMP_DIR}/osv-output.txt"
	local osv_status=0

	osv-scanner scan source -r "${DOTFILES_DIR}" >"${osv_output}" 2>&1 || osv_status=$?
	if [[ ${osv_status} -eq 0 ]]; then
		return 0
	fi
	if is_osv_infrastructure_failure "${osv_output}"; then
		printf 'External dependency failure: osv-scanner service unavailable\n' >&2
		cat "${osv_output}" >&2
		return "${osv_status}"
	fi

	cat "${osv_output}" >&2
	return "${osv_status}"
}

main() {
	local changed_file_list="${TMP_DIR}/changed-files"
	local shellcheck_files="${TMP_DIR}/shellcheck-files"
	local zsh_syntax_files="${TMP_DIR}/zsh-syntax-files"
	local shfmt_files="${TMP_DIR}/shfmt-files"
	local yaml_files="${TMP_DIR}/yaml-files"
	local workflow_files="${TMP_DIR}/workflow-files"

	{
		git -C "${DOTFILES_DIR}" diff --name-only --diff-filter=ACMR HEAD --
		git -C "${DOTFILES_DIR}" ls-files --others --exclude-standard
	} | sort -u >"${changed_file_list}"

	if [[ ! -s "${changed_file_list}" ]]; then
		log "No files changed since HEAD; running security checks only"
	else
		log "Changed files"
		sed 's/^/  - /' "${changed_file_list}"
	fi

	: >"${shellcheck_files}"
	: >"${zsh_syntax_files}"
	: >"${shfmt_files}"
	: >"${yaml_files}"
	: >"${workflow_files}"

	while IFS= read -r file; do
		[[ -n "${file}" && -f "${DOTFILES_DIR}/${file}" ]] || continue
		case "${file}" in
		termux/install_plugins.sh)
			printf '%s\n' "${DOTFILES_DIR}/${file}" >>"${zsh_syntax_files}"
			continue
			;;
		esac
		case "${file}" in
		*.tmpl) ;;
		*.sh | *.bash | *.bats | bin/mcp-*-launcher | bin/playwright-docker | bin/dotfiles-update | bin/dotfiles-apply | bin/tmux-dotfiles | local/bin/ai-prompt | local/bin/prompt-*)
			printf '%s\n' "${DOTFILES_DIR}/${file}" >>"${shellcheck_files}"
			;;
		esac
		case "${file}" in
		*.tmpl | *.bats) ;;
		*.sh | *.bash | bin/mcp-*-launcher | bin/playwright-docker | bin/dotfiles-update | bin/dotfiles-apply | bin/tmux-dotfiles | local/bin/ai-prompt | local/bin/prompt-*)
			printf '%s\n' "${DOTFILES_DIR}/${file}" >>"${shfmt_files}"
			;;
		esac
		case "${file}" in
		*.yaml | *.yml | .yamllint)
			printf '%s\n' "${DOTFILES_DIR}/${file}" >>"${yaml_files}"
			;;
		esac
		case "${file}" in
		.github/workflows/*.yaml | .github/workflows/*.yml)
			printf '%s\n' "${DOTFILES_DIR}/${file}" >>"${workflow_files}"
			;;
		esac
	done <"${changed_file_list}"

	if [[ -s "${shellcheck_files}" ]]; then
		require_cmd shellcheck "make install SKIP_EXTERNAL=1"
		log "shellcheck changed shell files"
		xargs shellcheck -x -S warning <"${shellcheck_files}"
	else
		log "shellcheck skipped: no changed shell files"
	fi

	if [[ -s "${zsh_syntax_files}" ]]; then
		require_cmd zsh "make install SKIP_EXTERNAL=1"
		log "zsh syntax changed scripts"
		xargs zsh -n <"${zsh_syntax_files}"
	else
		log "zsh syntax skipped: no changed zsh scripts"
	fi

	if [[ -s "${shfmt_files}" ]]; then
		require_cmd shfmt "make install SKIP_EXTERNAL=1"
		log "shfmt changed shell scripts"
		local shfmt_diff
		shfmt_diff="$(xargs shfmt -d <"${shfmt_files}")"
		if [[ -n "${shfmt_diff}" ]]; then
			printf '%s\n' "${shfmt_diff}"
			printf 'Changed shell scripts are not shfmt-formatted\n' >&2
			return 1
		fi
	else
		log "shfmt skipped: no changed shell scripts"
	fi

	if [[ -s "${yaml_files}" ]]; then
		log "yamllint changed YAML files"
		while IFS= read -r file; do
			run_yamllint "${file}"
		done <"${yaml_files}"
	else
		log "yamllint skipped: no changed YAML files"
	fi

	if [[ -s "${workflow_files}" ]]; then
		ensure_actionlint
		log "actionlint GitHub workflows"
		actionlint -shellcheck= "${DOTFILES_DIR}"/.github/workflows/*.yml
	else
		log "actionlint skipped: no changed GitHub workflows"
	fi

	if grep -Eq '(^|/)(Makefile|[^/]+\.mk)$|^tests/Makefile\.tests$|^install\.mk$' "${changed_file_list}"; then
		log "make database parse check"
		make -C "${DOTFILES_DIR}" -pn >/dev/null
	fi

	if grep -Eq '^(system/packages/|scripts/lib/system_deps\.py|scripts/install-agent-tools\.sh|scripts/install-external\.sh|install\.mk|tests/Makefile\.tests|tests/bats/system/system-deps\.bats)' "${changed_file_list}"; then
		log "dependency-layer bats"
		bats "${DOTFILES_DIR}/tests/bats/system/system-deps.bats"
	fi

	if grep -Eq '^(ai/runtime/mcp/|ai/assets/mcps/|bin/mcp-|tests/bats/mcp/|tests/bats/chezmoi/ai-runtime-uv\.bats|tests/bats/system/mcp-render-drift\.bats)' "${changed_file_list}"; then
		log "MCP governance and runtime bats"
		make -C "${DOTFILES_DIR}" ai-mcp-governance
		bats "${DOTFILES_DIR}/tests/bats/mcp" \
			"${DOTFILES_DIR}/tests/bats/chezmoi/ai-runtime-uv.bats" \
			"${DOTFILES_DIR}/tests/bats/system/mcp-render-drift.bats"
	fi

	if grep -Eq '^docs/' "${changed_file_list}"; then
		log "documentation bats"
		make -C "${DOTFILES_DIR}" bats-docs
	fi

	if grep -Eq '^ai/assets/handoffs/' "${changed_file_list}"; then
		log "handoff template contract bats"
		bats "${DOTFILES_DIR}/tests/bats/docs/documentation-consistency.bats"
	fi

	if grep -Eq '^ai/assets/skills/' "${changed_file_list}"; then
		log "skills structure and bats"
		bash "${DOTFILES_DIR}/scripts/validate-skills-structure.sh"
		bats "${DOTFILES_DIR}/tests/bats/skills"
	fi

	if grep -Eq '^ai/assets/commands/' "${changed_file_list}"; then
		log "commands structure and bats"
		make -C "${DOTFILES_DIR}" validate-commands
		bats "${DOTFILES_DIR}/tests/bats/commands"
	fi

	if grep -Eq '^(\.chezmoiscripts/|dot_)' "${changed_file_list}"; then
		log "chezmoi template bats"
		make -C "${DOTFILES_DIR}" test-chezmoi
	fi

	if grep -Eq '^(scripts/treegen\.sh|scripts/hooks/|\.githooks/)' "${changed_file_list}"; then
		log "git hooks and treegen bats"
		bats "${DOTFILES_DIR}/tests/bats/git-hooks/hooks.bats"
	fi

	if grep -Eq '^zsh/' "${changed_file_list}"; then
		log "zsh stack bats"
		make -C "${DOTFILES_DIR}" bats-zsh
	fi

	if grep -Eq '^scripts/update/' "${changed_file_list}"; then
		log "update workflow bats"
		bats "${DOTFILES_DIR}/tests/bats/system/update-workflow.bats" \
			"${DOTFILES_DIR}/tests/bats/system/update-node-runtime.bats" \
			"${DOTFILES_DIR}/tests/bats/system/update-governance.bats"
	fi

	if grep -Eq '^(bin/playwright-docker|dot_local/bin/symlink_playwright-docker\.tmpl|tests/bats/system/playwright-docker\.bats)' "${changed_file_list}"; then
		log "playwright-docker bats"
		bats "${DOTFILES_DIR}/tests/bats/system/playwright-docker.bats"
	fi

	if grep -Eq '^(bin/dotfiles-update|dot_local/bin/symlink_dotfiles-update\.tmpl|tests/bats/system/dotfiles-update\.bats)' "${changed_file_list}"; then
		log "dotfiles-update bats"
		bats "${DOTFILES_DIR}/tests/bats/system/dotfiles-update.bats"
	fi

	if grep -Eq '^(bin/dotfiles-apply|dot_local/bin/symlink_dotfiles-apply\.tmpl|tests/bats/system/dotfiles-apply\.bats)' "${changed_file_list}"; then
		log "dotfiles-apply bats"
		bats "${DOTFILES_DIR}/tests/bats/system/dotfiles-apply.bats"
	fi

	if grep -Eq '^(docs/SCRIPT_CONVENTIONS\.md|tests/bats/system/dry-run-guard\.bats)' "${changed_file_list}"; then
		log "dry-run convention bats"
		bats "${DOTFILES_DIR}/tests/bats/system/dry-run-guard.bats"
	fi

	if grep -Eq '^(tests/bats/agent/|docs/AGENT_WORKFLOW\.md|docs/TESTING\.md|docs/VALIDATION_MATRIX\.md)' "${changed_file_list}"; then
		log "agent regression index bats"
		bats "${DOTFILES_DIR}/tests/bats/agent/regression.bats"
	fi

	run_local_security_scan

	if [[ "${SECURITY_ONLINE}" == "1" ]]; then
		run_osv_online_scan
	else
		log "osv-scanner online scan skipped (set SECURITY_ONLINE=1 to enable strict dependency scan)"
	fi

	log "Changed-file agent validation completed"
}

main "$@"
