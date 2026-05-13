#!/usr/bin/env bash
# Advisory + opt-in installer to make zsh the default login shell.
#
# Contract:
#   - Read-only by default. Prints the chsh command and validation steps.
#   - APPLY=1: runs `chsh -s "$(command -v zsh)"`. Interactive: may prompt for
#     the user's password. Idempotent.
#   - ZSH_BASHRC_FALLBACK=1: appends an idempotent block to ~/.bashrc that
#     auto-execs `zsh -l` for interactive shells. Useful for WSL where some
#     terminals ignore /etc/passwd's login shell. Always backs up first.
#   - DRY_RUN=1: prints what would be done without making changes.
#   - Never uses sudo. Never modifies anything else.
#
# This target is intentionally NOT part of `make install` because changing the
# login shell or editing ~/.bashrc is a personal, host-specific decision.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

dry() { install_is_truthy "${DRY_RUN:-}"; }
apply_ok() { install_is_truthy "${APPLY:-}"; }
bashrc_fallback_on() { install_is_truthy "${ZSH_BASHRC_FALLBACK:-}"; }

BASHRC="${HOME}/.bashrc"
FALLBACK_MARK_BEGIN="# >>> dotfiles zsh-fallback >>>"

print_header() {
	echo "==> set-default-shell-zsh (opt-in, idempotent, no sudo)"
	if dry; then
		echo "[DRY_RUN] No chsh, no rc edits."
	fi
}

current_login_shell() {
	getent passwd "${USER}" 2>/dev/null | awk -F: '{print $7}' || echo ""
}

print_status() {
	local zsh_bin="${1:-}"
	local login_sh
	login_sh="$(current_login_shell)"
	echo ""
	echo "==> Status"
	printf '    USER:                %s\n' "${USER}"
	printf '    Current login shell: %s\n' "${login_sh:-<unknown>}"
	printf '    SHELL env:           %s\n' "${SHELL:-<unset>}"
	printf '    Current process:     %s\n' "$(ps -p "$$" -o comm= 2>/dev/null || echo '<unknown>')"
	printf '    zsh in PATH:         %s\n' "${zsh_bin:-<missing>}"
	echo ""
}

print_validation_hints() {
	echo "    After reopening the terminal, validate with:"
	echo "        echo \"\$SHELL\""
	echo "        ps -p \$\$ -o comm="
	echo "    Both should report zsh."
}

ensure_chsh_known() {
	local zsh_bin="$1"
	if ! grep -Fxq "${zsh_bin}" /etc/shells 2>/dev/null; then
		install_label WARN "${zsh_bin} is not listed in /etc/shells; chsh may refuse it."
		echo "    Workarounds:"
		echo "      - Add it: echo '${zsh_bin}' | sudo tee -a /etc/shells"
		echo "      - Or use the bashrc fallback (no sudo, see ZSH_BASHRC_FALLBACK=1)."
	fi
}

run_chsh() {
	local zsh_bin="$1"
	local login_sh
	login_sh="$(current_login_shell)"
	if [[ "${login_sh}" == "${zsh_bin}" ]]; then
		install_label OK "Login shell is already ${zsh_bin} — chsh skipped."
		return 0
	fi
	if dry; then
		install_label WARN "Would run: chsh -s ${zsh_bin}  (DRY_RUN=1, not executed)"
		return 0
	fi
	if ! command -v chsh >/dev/null 2>&1; then
		install_label FAIL "chsh not in PATH. Install 'passwd' package or use the bashrc fallback."
		return 1
	fi
	echo "    Running: chsh -s ${zsh_bin}"
	echo "    chsh may prompt for your account password."
	if chsh -s "${zsh_bin}"; then
		install_label OK "Login shell changed to ${zsh_bin}. Reopen the terminal to take effect."
	else
		install_label FAIL "chsh refused. Try the bashrc fallback (ZSH_BASHRC_FALLBACK=1) instead."
		return 1
	fi
}

bashrc_fallback_block() {
	cat <<'EOF'
# >>> dotfiles zsh-fallback >>>
# Auto-launch zsh for interactive bash sessions when zsh is available. Useful
# for WSL terminals that ignore /etc/passwd's login shell. Idempotent.
if [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
	exec zsh -l
fi
# <<< dotfiles zsh-fallback <<<
EOF
}

apply_bashrc_fallback() {
	local block
	block="$(bashrc_fallback_block)"

	if [[ -f "${BASHRC}" ]] && grep -Fq "${FALLBACK_MARK_BEGIN}" "${BASHRC}"; then
		install_label OK "${BASHRC} already contains the zsh-fallback block — no changes."
		return 0
	fi

	if dry; then
		install_label WARN "Would append zsh-fallback block to ${BASHRC} (DRY_RUN=1, not executed)."
		echo "${block}" | sed 's/^/        /'
		return 0
	fi

	if [[ -f "${BASHRC}" ]]; then
		local bk
		bk="${BASHRC}.backup.$(date +%Y%m%d-%H%M%S)"
		cp -p "${BASHRC}" "${bk}"
		install_label OK "Backup created: ${bk}"
	else
		: >"${BASHRC}"
	fi

	{
		printf '\n'
		printf '%s\n' "${block}"
	} >>"${BASHRC}"

	install_label OK "zsh-fallback block appended to ${BASHRC}. Reopen the terminal to take effect."
}

main() {
	print_header

	local zsh_bin=""
	if command -v zsh >/dev/null 2>&1; then
		zsh_bin="$(command -v zsh)"
	fi

	print_status "${zsh_bin}"

	if [[ -z "${zsh_bin}" ]]; then
		install_label FAIL "zsh is not installed. Run 'make install SKIP_EXTERNAL=1' first."
		exit 1
	fi

	ensure_chsh_known "${zsh_bin}"

	echo "==> Recommended (one-time, persistent across terminals):"
	echo "        chsh -s \"\$(command -v zsh)\""
	echo "    Then close and reopen the terminal."
	print_validation_hints

	if bashrc_fallback_on; then
		echo ""
		echo "==> WSL fallback: appending zsh auto-exec block to ~/.bashrc"
		apply_bashrc_fallback
	else
		echo ""
		echo "==> WSL fallback (opt-in, no sudo, no chsh):"
		echo "    Some WSL terminals ignore the login shell. Re-run with:"
		echo "        ZSH_BASHRC_FALLBACK=1 make set-default-shell-zsh"
		echo "    to append an idempotent auto-exec block to ~/.bashrc (with backup)."
	fi

	if apply_ok; then
		echo ""
		echo "==> Applying chsh (APPLY=1)"
		run_chsh "${zsh_bin}"
	else
		echo ""
		install_label WARN "APPLY is not set — chsh was NOT executed (safe default)."
		echo "    To run chsh, re-invoke with: APPLY=1 make set-default-shell-zsh"
	fi

	exit 0
}

main "$@"
