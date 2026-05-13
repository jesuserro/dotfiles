#!/usr/bin/env bash
# Idempotent install of the user-level zsh stack: Oh My Zsh + Powerlevel10k + custom plugins.
#
# Contract:
#   - Installs only runtime: Oh My Zsh, Powerlevel10k and the custom OMZ plugins.
#   - Never edits ~/.zshrc, ~/.p10k.zsh, ~/.aliases or any rc file directly:
#     those symlinks are created by Chezmoi via `make install-dotfiles DOTFILES_APPLY=1`.
#   - Only clones repos under $HOME if the target directory does not already exist.
#   - DRY_RUN=1: prints what would be cloned without touching disk or network.
#   - Re-runnable: existing checkouts are left untouched (no auto git pull).
#   - RCM/rcup is NOT part of the active flow; this script does not call rcup.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

ZSH_DIR="${ZSH:-${HOME}/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-${ZSH_DIR}/custom}"
P10K_DIR="${ZSH_CUSTOM_DIR}/themes/powerlevel10k"

OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"

# plugin_name|repo_url
PLUGINS=(
	"autoupdate|https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git"
	"zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
	"zsh-completions|https://github.com/zsh-users/zsh-completions.git"
	"zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search.git"
	"zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

ensure_clone() {
	local label="$1"
	local repo="$2"
	local dest="$3"
	local depth_arg="${4:---depth=1}"

	if [[ -d "${dest}/.git" ]]; then
		install_label OK "${label} already present at ${dest}"
		return 0
	fi
	if [[ -e "${dest}" ]]; then
		install_label WARN "${label} path exists but is not a git repo: ${dest} (skipped, no destructive action)"
		return 0
	fi

	if install_is_truthy "${DRY_RUN:-}"; then
		install_label WARN "${label} missing — would run: git clone ${depth_arg} ${repo} ${dest}"
		return 0
	fi

	if ! command -v git >/dev/null 2>&1; then
		install_label FAIL "${label} missing and git is not in PATH (install git first via make install-apt)"
		return 1
	fi

	mkdir -p "$(dirname "${dest}")"
	git clone ${depth_arg} "${repo}" "${dest}"
	install_label OK "${label} cloned into ${dest}"
}

echo "==> Zsh stack (idempotent install of Oh My Zsh + Powerlevel10k + custom plugins)"
echo "    ZSH=${ZSH_DIR}"
echo "    ZSH_CUSTOM=${ZSH_CUSTOM_DIR}"
if install_is_truthy "${DRY_RUN:-}"; then
	echo "[DRY_RUN] No clones, no writes."
fi

if ! command -v zsh >/dev/null 2>&1; then
	install_label WARN "zsh not in PATH — install it first (make install-apt). Continuing with Oh My Zsh layout anyway."
fi

echo ""
echo "==> Oh My Zsh"
ensure_clone "Oh My Zsh" "${OMZ_REPO}" "${ZSH_DIR}"

echo ""
echo "==> Powerlevel10k theme"
ensure_clone "Powerlevel10k" "${P10K_REPO}" "${P10K_DIR}" "--depth=1"

echo ""
echo "==> Oh My Zsh custom plugins (cloned only if missing)"
fail=0
for entry in "${PLUGINS[@]}"; do
	name="${entry%%|*}"
	repo="${entry##*|}"
	dest="${ZSH_CUSTOM_DIR}/plugins/${name}"
	if ! ensure_clone "plugin: ${name}" "${repo}" "${dest}"; then
		fail=$((fail + 1))
	fi
done

echo ""
echo "==> Notes"
install_label OK "Re-running this script is safe: existing checkouts are left as-is."
install_label OK "RC files (~/.zshrc, ~/.p10k.zsh, ~/.aliases) are managed by Chezmoi via 'make install-dotfiles DOTFILES_APPLY=1'."
install_label OK "If those files contain custom content, use 'ZSH_RC_APPLY=1 make install-dotfiles DOTFILES_APPLY=1' to allow backup + replacement."
if [[ ! -L "${HOME}/.zshrc" || ! -L "${HOME}/.p10k.zsh" || ! -L "${HOME}/.aliases" ]]; then
	install_label WARN "RC symlinks are not yet in place — finish the bootstrap with: make install-dotfiles DOTFILES_APPLY=1"
fi

if [[ ${fail} -gt 0 ]]; then
	exit 1
fi
exit 0
