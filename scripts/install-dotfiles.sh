#!/usr/bin/env bash
# Prepare chezmoi apply plan; real apply only with DOTFILES_APPLY=1 (never with DRY_RUN).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REMOTE_DOTFILES="https://github.com/jesuserro/dotfiles"
CANON_HOME="${HOME}/dotfiles"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

apply_ok() {
	install_is_truthy "${DOTFILES_APPLY:-}"
}

resolve_local_source() {
	local repo_root="${DOTFILES_ROOT}"
	local home_dot=""
	if [[ -d "${CANON_HOME}/.git" ]]; then
		home_dot="$(cd "${CANON_HOME}" && pwd)"
	fi
	local rr=""
	if [[ -d "${repo_root}/.git" ]]; then
		rr="$(cd "${repo_root}" && pwd)"
	fi
	if [[ -n "${home_dot}" && -n "${rr}" && "${home_dot}" == "${rr}" ]]; then
		echo "${home_dot}"
		return 0
	fi
	if [[ -n "${home_dot}" ]]; then
		echo "${home_dot}"
		return 0
	fi
	if [[ -n "${rr}" ]]; then
		echo "${rr}"
		return 0
	fi
	echo ""
}

echo "==> Dotfiles / chezmoi bootstrap"

chezmoi_bin=""
if command -v chezmoi >/dev/null 2>&1; then
	chezmoi_bin="$(command -v chezmoi)"
	install_label OK "chezmoi: ${chezmoi_bin}"
else
	install_label MISSING "chezmoi not in PATH — run 'make install-chezmoi' (preferred, idempotent, no sudo). Fallback: 'sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \"\$HOME/.local/bin\"' or see docs/INSTALL.md"
fi

local_src="$(resolve_local_source)"
if [[ -n "${local_src}" ]]; then
	install_label OK "Local dotfiles repo resolved: ${local_src}"
else
	install_label WARN "No local git checkout detected at ${CANON_HOME} or ${DOTFILES_ROOT}"
fi

if [[ -f "${HOME}/.config/sops/age/keys.txt" ]]; then
	install_label OK "SOPS age key file present (~/.config/sops/age/keys.txt)"
else
	install_label WARN "SOPS age keys not configured — secrets phase pending (this script does not run age-keygen)"
fi

echo ""
echo "Planned chezmoi usage:"
if [[ -n "${local_src}" ]]; then
	echo "  • Local source: chezmoi apply --source=\"${local_src}\""
else
	echo "  • Clone then apply, for example:"
	echo "      git clone ${REMOTE_DOTFILES}.git ${CANON_HOME}"
	echo "      chezmoi apply --source=\"${CANON_HOME}\""
	echo "  • Or one-shot from upstream (see docs/CHEZMOI.md):"
	echo "      chezmoi init --apply ${REMOTE_DOTFILES}"
fi

if ! apply_ok; then
	echo ""
	install_label WARN "DOTFILES_APPLY is not set — chezmoi will NOT apply (safe default). Use DOTFILES_APPLY=1 to apply."
	exit 0
fi

if dry; then
	echo ""
	echo "[DRY_RUN] Planned apply commands (not executed):"
	if [[ -n "${chezmoi_bin}" ]]; then
		if [[ -n "${local_src}" ]]; then
			install_run_or_echo chezmoi apply --source="${local_src}"
		else
			install_run_or_echo chezmoi init --apply "${REMOTE_DOTFILES}"
		fi
	else
		echo "  (skipped: chezmoi not installed)"
	fi
	exit 0
fi

if [[ -z "${chezmoi_bin}" ]]; then
	install_label FAIL "DOTFILES_APPLY=1 but chezmoi is missing — run 'make install-chezmoi' first (fallback: 'sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \"\$HOME/.local/bin\"')"
	exit 1
fi

if [[ -n "${local_src}" ]]; then
	echo ""
	echo "Applying dotfiles from local source (DOTFILES_APPLY=1)..."
	chezmoi apply --source="${local_src}"
	install_label OK "chezmoi apply completed for source ${local_src}"
	exit 0
fi

echo ""
echo "No local source; running chezmoi init --apply (DOTFILES_APPLY=1)..."
chezmoi init --apply "${REMOTE_DOTFILES}"
install_label OK "chezmoi init --apply completed for ${REMOTE_DOTFILES}"
