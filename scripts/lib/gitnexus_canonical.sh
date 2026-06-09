#!/usr/bin/env bash
# GitNexus canonical agent-first path helpers.
# Installs real binary under the user npm prefix; exposes ~/.local/bin/gitnexus as symlink.

gitnexus_npm_prefix() {
	local configured="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-}}" npm_prefix
	if [[ -n "$configured" ]]; then
		printf '%s\n' "$configured"
		return 0
	fi
	npm_prefix="$(npm config get prefix 2>/dev/null | head -n 1 | tr -d '\r' || true)"
	case "$npm_prefix" in
	"" | /usr | /usr/ | /usr/local | /usr/local/)
		printf '%s\n' "$HOME/.npm-global"
		;;
	*)
		if [[ -d "$npm_prefix" && ! -w "$npm_prefix" ]]; then
			printf '%s\n' "$HOME/.npm-global"
		else
			printf '%s\n' "$npm_prefix"
		fi
		;;
	esac
}

gitnexus_npm_bin() {
	local npm_prefix
	npm_prefix="$(gitnexus_npm_prefix)"
	printf '%s\n' "${npm_prefix}/bin/gitnexus"
}

gitnexus_canonical_bin() {
	printf '%s\n' "${HOME}/.local/bin/gitnexus"
}

gitnexus_resolve_realpath() {
	local path="$1"
	if command -v readlink >/dev/null 2>&1; then
		readlink -f "$path" 2>/dev/null || printf '%s\n' "$path"
	else
		printf '%s\n' "$path"
	fi
}

gitnexus_ensure_canonical_symlink() {
	local npm_bin canonical_bin npm_real canonical_real
	npm_bin="$(gitnexus_npm_bin)"
	canonical_bin="$(gitnexus_canonical_bin)"

	if [[ ! -x "$npm_bin" ]]; then
		echo "ERROR: GitNexus npm install not found or not executable: ${npm_bin}" >&2
		echo "       Run: ${DOTFILES_DIR:-$HOME/dotfiles}/scripts/install-gitnexus.sh" >&2
		echo "       Or:  make update-wsl --section tools" >&2
		return 1
	fi

	mkdir -p "${HOME}/.local/bin"
	ln -sfn "$npm_bin" "$canonical_bin"

	if [[ ! -L "$canonical_bin" && ! -x "$canonical_bin" ]]; then
		echo "ERROR: Failed to create canonical GitNexus symlink at ${canonical_bin}" >&2
		return 1
	fi

	npm_real="$(gitnexus_resolve_realpath "$npm_bin")"
	canonical_real="$(gitnexus_resolve_realpath "$canonical_bin")"
	if [[ -z "$npm_real" || -z "$canonical_real" || "$npm_real" != "$canonical_real" ]]; then
		echo "ERROR: Canonical GitNexus symlink does not resolve to npm-global binary." >&2
		echo "       npm-global: ${npm_bin} -> ${npm_real:-unknown}" >&2
		echo "       canonical:  ${canonical_bin} -> ${canonical_real:-unknown}" >&2
		return 1
	fi

	printf 'Canonical agent GitNexus: %s -> %s\n' "$canonical_bin" "$npm_bin"
	return 0
}
