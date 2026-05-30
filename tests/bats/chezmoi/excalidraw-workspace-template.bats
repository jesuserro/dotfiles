#!/usr/bin/env bats
# Chezmoi template fallback for ai.excalidraw_workspace_host (existing machines).

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	if ! command -v chezmoi >/dev/null 2>&1; then
		skip "chezmoi not in PATH"
	fi
	TEST_TEMP_DIR="$(mktemp -d)"
	export TEST_TEMP_DIR
}

teardown() {
	[[ -n "${TEST_TEMP_DIR:-}" ]] && rm -rf "${TEST_TEMP_DIR}"
}

render_template() {
	local config_file="$1"
	local template_rel="$2"
	chezmoi --source="${DOTFILES_DIR}" -c "${config_file}" execute-template -f "${DOTFILES_DIR}/${template_rel}"
}

write_chezmoi_config() {
	local config_file="$1"
	local obsidian_path="$2"
	local excalidraw_path="${3:-}"
	cat >"${config_file}" <<EOF
[source]
    path = "${DOTFILES_DIR}"

[data.ai]
    obsidian_vault_path = "${obsidian_path}"
EOF
	if [[ -n "${excalidraw_path}" ]]; then
		cat >>"${config_file}" <<EOF
    excalidraw_workspace_host = "${excalidraw_path}"
EOF
	fi
}

assert_excalidraw_mount() {
	local output="$1"
	local expected_host="$2"
	[[ "${output}" == *"\"${expected_host}:/workspace/excalidraw\""* ]] ||
		[[ "${output}" == *"\"${expected_host}:/workspace/excalidraw\","* ]] ||
		[[ "${output}" == *"\"-v\", \"${expected_host}:/workspace/excalidraw\""* ]] ||
		[[ "${output}" == *"${expected_host}:/workspace/excalidraw"* ]]
}

@test "excalidraw MCP templates use explicit excalidraw_workspace_host when set" {
	local cfg="${TEST_TEMP_DIR}/chezmoi-explicit.toml"
	write_chezmoi_config "${cfg}" "/tmp/vault" "/custom/excalidraw"

	for tmpl in dot_cursor/mcp.json.tmpl dot_codex/config.toml.tmpl dot_config/opencode/opencode.json.tmpl; do
		run render_template "${cfg}" "${tmpl}"
		[[ "${status}" -eq 0 ]]
		assert_excalidraw_mount "${output}" "/custom/excalidraw"
	done
}

@test "excalidraw MCP templates fall back to obsidian_vault_path/excalidraw when key missing" {
	local cfg="${TEST_TEMP_DIR}/chezmoi-fallback.toml"
	write_chezmoi_config "${cfg}" "/tmp/vault"

	for tmpl in dot_cursor/mcp.json.tmpl dot_codex/config.toml.tmpl dot_config/opencode/opencode.json.tmpl; do
		run render_template "${cfg}" "${tmpl}"
		[[ "${status}" -eq 0 ]]
		assert_excalidraw_mount "${output}" "/tmp/vault/excalidraw"
	done
}
