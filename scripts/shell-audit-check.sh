#!/usr/bin/env bash
# Focused shell audit for agents: repo-tracked shell surfaces only.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

log() {
	printf '==> %s\n' "$*"
}

info() {
	printf 'INFO: %s\n' "$*"
}

require_cmd() {
	local cmd="$1"
	local install_hint="$2"

	if ! command -v "${cmd}" >/dev/null 2>&1; then
		printf 'Missing shell audit dependency: %s\n' "${cmd}" >&2
		printf 'Run: %s\n' "${install_hint}" >&2
		return 1
	fi
}

is_shell_shebang() {
	local file="$1"
	local first_line

	first_line="$(head -n 1 "${file}" 2>/dev/null || true)"
	case "${first_line}" in
	'#!/bin/sh' | '#!/bin/bash' | '#!/usr/bin/env sh' | '#!/usr/bin/env bash')
		return 0
		;;
	*)
		return 1
		;;
	esac
}

append_shell_files() {
	local file abs
	local -n shellcheck_ref="$1"
	local -n shfmt_ref="$2"
	local -n zsh_ref="$3"

	while IFS= read -r file; do
		[[ -n "${file}" ]] || continue
		abs="${DOTFILES_DIR}/${file}"
		[[ -f "${abs}" ]] || continue

		case "${file}" in
		*.tmpl | *.md | *.py | *.ps1 | *.pyc | *.example | */__pycache__/*)
			continue
			;;
		.chezmoiscripts/* | dot_local/bin/* | .githooks/* | tmux/* | termux/*)
			continue
			;;
		esac

		case "${file}" in
		tests/bats/*.bats)
			shellcheck_ref+=("${abs}")
			continue
			;;
		zsh/*.zsh)
			zsh_ref+=("${abs}")
			continue
			;;
		scripts/*.sh)
			shellcheck_ref+=("${abs}")
			shfmt_ref+=("${abs}")
			continue
			;;
		bin/*)
			if is_shell_shebang "${abs}"; then
				shellcheck_ref+=("${abs}")
				shfmt_ref+=("${abs}")
			fi
			continue
			;;
		esac
	done < <(git -C "${DOTFILES_DIR}" ls-files)
}

run_shellcheck() {
	local -a files=("$@")

	log "ShellCheck: bin/, scripts/, scripts/lib/, tests/bats/"
	info "Excluding Markdown, Python, PowerShell, caches, examples and Chezmoi templates"
	if [[ "${#files[@]}" -eq 0 ]]; then
		info "shellcheck skipped: no files in scope"
		return 0
	fi
	shellcheck -x -S warning "${files[@]}"
}

run_shfmt() {
	local -a files=("$@")
	local diff

	log "shfmt: bin/ and scripts/**/*.sh only"
	info "Bats, zsh and templates are excluded from shfmt in this audit"
	if [[ "${#files[@]}" -eq 0 ]]; then
		info "shfmt skipped: no files in scope"
		return 0
	fi
	diff="$(shfmt -d "${files[@]}")"
	if [[ -n "${diff}" ]]; then
		printf '%s\n' "${diff}"
		printf 'Shell audit failed: shfmt reported differences\n' >&2
		return 1
	fi
}

run_zsh_syntax() {
	local -a files=("$@")

	log "zsh syntax: zsh/*.zsh"
	info "zsh is validated with zsh -n, not ShellCheck"
	if [[ "${#files[@]}" -eq 0 ]]; then
		info "zsh syntax skipped: no files in scope"
		return 0
	fi
	zsh -n "${files[@]}"
}

main() {
	local -a shellcheck_files=()
	local -a shfmt_files=()
	local -a zsh_files=()

	require_cmd git "make install SKIP_EXTERNAL=1"
	require_cmd shellcheck "make install SKIP_EXTERNAL=1"
	require_cmd shfmt "make install SKIP_EXTERNAL=1"
	require_cmd zsh "make install SKIP_EXTERNAL=1"

	log "Focused shell audit (read-only)"
	info "Scope: bin/, scripts/, scripts/lib/, tests/bats/ for ShellCheck; zsh/*.zsh for zsh -n"
	info "Out of scope: .chezmoiscripts, dot_local/bin, .githooks, tmux, termux, raw templates"

	append_shell_files shellcheck_files shfmt_files zsh_files
	run_shellcheck "${shellcheck_files[@]}"
	run_shfmt "${shfmt_files[@]}"
	run_zsh_syntax "${zsh_files[@]}"

	log "Shell audit completed"
}

main "$@"
