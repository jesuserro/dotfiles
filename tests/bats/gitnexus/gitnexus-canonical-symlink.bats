#!/usr/bin/env bats

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	HELPER="${DOTFILES_DIR}/scripts/lib/gitnexus_canonical.sh"
	INSTALL_GITNEXUS="${DOTFILES_DIR}/scripts/install-gitnexus.sh"
	UPDATE_WSL="${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

source_helper() {
	# shellcheck source=/dev/null
	source "${HELPER}"
}

write_fake_gitnexus() {
	local path="$1" version="${2:-1.6.6}"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
	echo "gitnexus ${version}"
	exit 0
fi
exit 0
EOF
	chmod +x "$path"
}

write_stale_local_tree() {
	local fake_home="$1"
	mkdir -p "${fake_home}/.local/lib/node_modules/gitnexus/dist/cli"
	echo "stale" >"${fake_home}/.local/lib/node_modules/gitnexus/package.json"
}

bats_require_minimum_version 1.5.0

@test "gitnexus_canonical helper exists" {
	[[ -f "${HELPER}" ]]
}

@test "gitnexus_canonical helper does not invoke mutating gitnexus commands" {
	run grep -E '(^|[^#].*)(gitnexus analyze|gitnexus wiki|gitnexus clean|gitnexus refresh|gitnexus index|npx gitnexus|rm -rf)' "${HELPER}"
	[[ "${status}" -eq 1 ]]
}

@test "gitnexus_ensure_canonical_symlink creates symlink to npm-global" {
	local fake_home="${TEST_TEMP_DIR}/home-create"
	local npm_prefix="${fake_home}/.npm-global"
	local npm_bin="${npm_prefix}/bin/gitnexus"
	local canonical="${fake_home}/.local/bin/gitnexus"
	write_fake_gitnexus "$npm_bin" "1.6.6"

	run bash -c "
		source '${HELPER}'
		export HOME='${fake_home}'
		export NPM_CONFIG_PREFIX='${npm_prefix}'
		gitnexus_ensure_canonical_symlink
	"

	[[ "${status}" -eq 0 ]]
	[[ -L "$canonical" ]]
	[[ "$(readlink -f "$canonical")" == "$(readlink -f "$npm_bin")" ]]
	[[ "${output}" == *"Canonical agent GitNexus: ${canonical} -> ${npm_bin}"* ]]
}

@test "gitnexus_ensure_canonical_symlink is idempotent" {
	local fake_home="${TEST_TEMP_DIR}/home-idempotent"
	local npm_prefix="${fake_home}/.npm-global"
	local npm_bin="${npm_prefix}/bin/gitnexus"
	write_fake_gitnexus "$npm_bin" "1.6.6"

	run bash -c "
		source '${HELPER}'
		export HOME='${fake_home}'
		export NPM_CONFIG_PREFIX='${npm_prefix}'
		gitnexus_ensure_canonical_symlink
		gitnexus_ensure_canonical_symlink
	"

	[[ "${status}" -eq 0 ]]
	[[ -L "${fake_home}/.local/bin/gitnexus" ]]
}

@test "gitnexus_ensure_canonical_symlink fails clearly when npm-global GitNexus is missing" {
	local fake_home="${TEST_TEMP_DIR}/home-missing"

	run bash -c "
		source '${HELPER}'
		export HOME='${fake_home}'
		export NPM_CONFIG_PREFIX='${fake_home}/.npm-global'
		gitnexus_ensure_canonical_symlink
	"

	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"GitNexus npm install not found"* ]]
	[[ ! -e "${fake_home}/.local/bin/gitnexus" ]]
}

@test "gitnexus_ensure_canonical_symlink does not delete stale local node_modules tree" {
	local fake_home="${TEST_TEMP_DIR}/home-no-prune"
	local npm_prefix="${fake_home}/.npm-global"
	local npm_bin="${npm_prefix}/bin/gitnexus"
	write_fake_gitnexus "$npm_bin" "1.6.6"
	write_stale_local_tree "$fake_home"

	run bash -c "
		source '${HELPER}'
		export HOME='${fake_home}'
		export NPM_CONFIG_PREFIX='${npm_prefix}'
		gitnexus_ensure_canonical_symlink
	"

	[[ "${status}" -eq 0 ]]
	[[ -f "${fake_home}/.local/lib/node_modules/gitnexus/package.json" ]]
}

@test "install-gitnexus.sh sources canonical helper after npm install" {
	grep -q 'gitnexus_canonical.sh' "${INSTALL_GITNEXUS}"
	grep -q 'gitnexus_ensure_canonical_symlink' "${INSTALL_GITNEXUS}"
}

@test "update-wsl.sh sources canonical helper after GitNexus update" {
	grep -q 'gitnexus_canonical.sh' "${UPDATE_WSL}"
	grep -q 'gitnexus_ensure_canonical_symlink' "${UPDATE_WSL}"
}

@test "zsh path policy gives ~/.local/bin precedence over npm-global" {
	local path_file="${DOTFILES_DIR}/zsh/10-path.zsh"
	local npm_line local_line
	npm_line="$(grep -n 'path_prepend "\$NPM_CONFIG_PREFIX/bin"' "$path_file" | cut -d: -f1)"
	local_line="$(grep -n 'path_prepend "\$HOME/.local/bin"' "$path_file" | cut -d: -f1)"
	[[ -n "$npm_line" && -n "$local_line" ]]
	[[ "$local_line" -gt "$npm_line" ]]
	grep -q 'Agent-first local commands should win over npm-global shims' "$path_file"
	run grep -q 'path_append "\$HOME/.local/bin"' "$path_file"
	[[ "${status}" -eq 1 ]]
}

@test "gitnexus_runtime prefers ~/.local/bin/gitnexus before command -v" {
	local runtime="${DOTFILES_DIR}/scripts/lib/gitnexus_runtime.sh"
	local canonical_line cmd_line
	canonical_line="$(grep -n 'canonical_bin="${HOME}/.local/bin/gitnexus"' "$runtime" | head -n1 | cut -d: -f1)"
	cmd_line="$(grep -n 'command -v gitnexus' "$runtime" | head -n1 | cut -d: -f1)"
	[[ -n "$canonical_line" && -n "$cmd_line" ]]
	[[ "$canonical_line" -lt "$cmd_line" ]]
}

@test "mcp-gitnexus-launcher still prioritizes ~/.local/bin/gitnexus" {
	local launcher="${DOTFILES_DIR}/bin/mcp-gitnexus-launcher"
	grep -q '\$HOME/.local/bin/gitnexus' "$launcher"
	run grep -E '(^|[^#].*)\bnpx\b.*gitnexus|exec.*npx' "$launcher"
	[[ "${status}" -eq 1 ]]
}
