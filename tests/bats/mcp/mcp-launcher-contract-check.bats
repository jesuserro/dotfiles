#!/usr/bin/env bats
# mcp-launcher-contract-check: read-only repo contract + agent template paths.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/mcp-launcher-contract-check.sh"
	INSTALL_MK="${DOTFILES_DIR}/install.mk"
	BIN="${DOTFILES_DIR}/bin"
	TMPL_DIR="${DOTFILES_DIR}/dot_local/share/chezmoi/bin"
}

bats_require_minimum_version 1.5.0

@test "mcp-launcher-contract-check script exists" {
	[[ -f "${SCRIPT}" ]]
}

@test "mcp-launcher-contract-check script does not execute chezmoi apply" {
	run grep -E '^\s*chezmoi(\s|$).*apply' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
}

@test "install.mk exposes make mcp-launcher-contract-check" {
	grep -q '^mcp-launcher-contract-check:' "${INSTALL_MK}"
	grep -q 'scripts/mcp-launcher-contract-check.sh' "${INSTALL_MK}"
}

@test "mcp-launcher-contract-check passes on real repo" {
	run env DOTFILES_DIR="${DOTFILES_DIR}" bash "${SCRIPT}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Contract OK"* ]]
	[[ "${output}" == *"filesystem: dual design OK"* ]] ||
		[[ "${output}" == *"dual design usually differs"* ]]
}

@test "script fails when git bin and template differ" {
	setup_temp_dir
	local fixture="${TEST_TEMP_DIR}/fixture"
	mkdir -p "${fixture}/bin" "${fixture}/dot_local/share/chezmoi/bin"
	mkdir -p "${fixture}/dot_cursor" "${fixture}/dot_codex" "${fixture}/dot_config/opencode"

	for name in filesystem git gitnexus postgres; do
		cp "${BIN}/mcp-${name}-launcher" "${fixture}/bin/"
		cp "${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl" \
			"${fixture}/dot_local/share/chezmoi/bin/"
	done
	cp "${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl" "${fixture}/dot_cursor/"
	cp "${DOTFILES_DIR}/dot_codex/private_config.toml.tmpl" "${fixture}/dot_codex/"
	cp "${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl" "${fixture}/dot_config/opencode/"

	printf '\n# drift\n' >>"${fixture}/bin/mcp-git-launcher"

	run env DOTFILES_DIR="${fixture}" bash "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"mcp-git-launcher: bin/ and template differ"* ]]
}

@test "script does not fail when only filesystem bin and template differ" {
	setup_temp_dir
	local fixture="${TEST_TEMP_DIR}/fixture-fs"
	mkdir -p "${fixture}/bin" "${fixture}/dot_local/share/chezmoi/bin"
	mkdir -p "${fixture}/dot_cursor" "${fixture}/dot_codex" "${fixture}/dot_config/opencode"

	for name in filesystem git gitnexus postgres; do
		cp "${BIN}/mcp-${name}-launcher" "${fixture}/bin/"
		cp "${TMPL_DIR}/executable_mcp-${name}-launcher.tmpl" \
			"${fixture}/dot_local/share/chezmoi/bin/"
	done
	cp "${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl" "${fixture}/dot_cursor/"
	cp "${DOTFILES_DIR}/dot_codex/private_config.toml.tmpl" "${fixture}/dot_codex/"
	cp "${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl" "${fixture}/dot_config/opencode/"

	printf '\n# intentional dual-design delta\n' >>"${fixture}/bin/mcp-filesystem-launcher"

	run env DOTFILES_DIR="${fixture}" bash "${SCRIPT}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"filesystem: dual design OK"* ]]
}

@test "productive agent templates do not reference dotfiles/bin/mcp-" {
	for f in \
		"${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl" \
		"${DOTFILES_DIR}/dot_codex/private_config.toml.tmpl" \
		"${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl"; do
		[[ -f "$f" ]]
		run grep -q 'dotfiles/bin/mcp-' "$f"
		[[ "${status}" -eq 1 ]]
		run grep -q '/home/jesus/dotfiles/bin/mcp-' "$f"
		[[ "${status}" -eq 1 ]]
	done
}

@test "productive agent templates reference chezmoi materialized launchers" {
	for f in \
		"${DOTFILES_DIR}/dot_cursor/mcp.json.tmpl" \
		"${DOTFILES_DIR}/dot_codex/private_config.toml.tmpl" \
		"${DOTFILES_DIR}/dot_config/opencode/opencode.json.tmpl"; do
		[[ -f "$f" ]]
		grep -q '.local/share/chezmoi/bin/mcp-git-launcher' "$f"
		grep -q '.local/share/chezmoi/bin/mcp-gitnexus-launcher' "$f"
		grep -q '.local/share/chezmoi/bin/mcp-filesystem-launcher' "$f"
		grep -q '.local/share/chezmoi/bin/mcp-postgres-launcher' "$f"
	done
}

@test "script documents HOME drift as WARN not hard failure" {
	grep -q 'HOME launcher drift detected' "${SCRIPT}"
	grep -q 'never fails this check' "${SCRIPT}" || grep -q 'does not affect exit status' "${SCRIPT}"
}
