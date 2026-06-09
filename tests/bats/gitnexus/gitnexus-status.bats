#!/usr/bin/env bats
# gitnexus-status: read-only operational status script and policy wiring.

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/gitnexus-status.sh"
	POLICY="${DOTFILES_DIR}/docs/GITNEXUS_OPERATIONAL_POLICY.md"
	INSTALL_MK="${DOTFILES_DIR}/install.mk"
	SKILLS_DIR="${DOTFILES_DIR}/ai/assets/skills/gitnexus"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

init_git_repo() {
	local repo="$1"
	mkdir -p "$repo"
	git -C "$repo" init -q
	git -C "$repo" config user.email "test@example.com"
	git -C "$repo" config user.name "Test User"
	echo "fixture" >"$repo/README.md"
	git -C "$repo" add README.md
	git -C "$repo" commit -q -m "init"
}

write_fake_gitnexus() {
	local path="$1" version="$2"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
	echo "$version"
	exit 0
fi
exit 0
EOF
	chmod +x "$path"
}

run_gitnexus_status() {
	local repo="$1"
	shift
	run env DOTFILES_DIR="${DOTFILES_DIR}" "$@" bash -c "cd '${repo}' && bash '${SCRIPT}'"
}

bats_require_minimum_version 1.5.0

@test "gitnexus-status script exists and is executable" {
	[[ -f "${SCRIPT}" ]]
	[[ -x "${SCRIPT}" ]]
}

@test "gitnexus-status script does not invoke mutating gitnexus commands" {
	run grep -E '(^|[^#].*)(gitnexus analyze|gitnexus wiki|gitnexus clean|gitnexus refresh|gitnexus index|npx gitnexus|rm .*\.gitnexus/lbug)' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
}

@test "gitnexus-status declares canonical agent GitNexus path constant" {
	grep -q 'GITNEXUS_CANONICAL_BIN=' "${SCRIPT}"
	grep -q '\$HOME/.local/bin/gitnexus' "${SCRIPT}"
}

@test "gitnexus-status reports OK when canonical symlinks to npm-global with same version" {
	local repo="${TEST_TEMP_DIR}/symlink-aligned"
	local fake_home="${TEST_TEMP_DIR}/home-symlink-aligned"
	local npm_global="${fake_home}/.npm-global/bin/gitnexus"
	local canonical="${fake_home}/.local/bin/gitnexus"
	init_git_repo "$repo"
	mkdir -p "$(dirname "$npm_global")" "$(dirname "$canonical")"
	write_fake_gitnexus "$npm_global" "1.6.6"
	ln -sfn "$npm_global" "$canonical"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.local/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD='true'

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"PATH GitNexus matches canonical agent path."* ]]
	[[ "${output}" != *"GitNexus CLI/MCP version mismatch"* ]]
	[[ "${output}" == *"agent-safe for read-only impact/context."* ]]
}

@test "gitnexus-status reports OK when PATH matches canonical GitNexus" {
	local repo="${TEST_TEMP_DIR}/path-aligned"
	local fake_home="${TEST_TEMP_DIR}/home-aligned"
	local canonical="${fake_home}/.local/bin/gitnexus"
	init_git_repo "$repo"
	write_fake_gitnexus "$canonical" "1.6.6"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.local/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD='true'

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"PATH GitNexus matches canonical agent path."* ]]
	[[ "${output}" == *"agent-safe for read-only impact/context."* ]]
}

@test "gitnexus-status warns when PATH differs from canonical GitNexus" {
	local repo="${TEST_TEMP_DIR}/path-mismatch"
	local fake_home="${TEST_TEMP_DIR}/home-mismatch"
	local canonical="${fake_home}/.local/bin/gitnexus"
	local npm_global="${fake_home}/.npm-global/bin/gitnexus"
	init_git_repo "$repo"
	write_fake_gitnexus "$canonical" "1.6.1"
	write_fake_gitnexus "$npm_global" "1.6.6"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.npm-global/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD='true'

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"PATH GitNexus differs from canonical agent path."* ]]
	[[ "${output}" == *".npm-global/bin/gitnexus shadows canonical agent GitNexus."* ]]
}

@test "gitnexus-status warns on GitNexus version mismatch across known binaries" {
	local repo="${TEST_TEMP_DIR}/version-mismatch"
	local fake_home="${TEST_TEMP_DIR}/home-version"
	local canonical="${fake_home}/.local/bin/gitnexus"
	local npm_global="${fake_home}/.npm-global/bin/gitnexus"
	init_git_repo "$repo"
	write_fake_gitnexus "$canonical" "1.6.1"
	write_fake_gitnexus "$npm_global" "1.6.6"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.npm-global/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD='true'

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"GitNexus CLI/MCP version mismatch may cause storage version mismatch."* ]]
}

@test "gitnexus-status reports OK when live MCP paths match canonical GitNexus" {
	local repo="${TEST_TEMP_DIR}/mcp-aligned"
	local fake_home="${TEST_TEMP_DIR}/home-mcp-aligned"
	local canonical="${fake_home}/.local/bin/gitnexus"
	local ps_fixture="${TEST_TEMP_DIR}/mcp-aligned.ps"
	init_git_repo "$repo"
	write_fake_gitnexus "$canonical" "1.6.6"
	printf 'user 123 node %s mcp\n' "$canonical" >"$ps_fixture"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.local/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD="cat '${ps_fixture}'"

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"live MCP GitNexus paths match canonical agent path."* ]]
}

@test "gitnexus-status warns when live MCP paths differ from canonical GitNexus" {
	local repo="${TEST_TEMP_DIR}/mcp-mismatch"
	local fake_home="${TEST_TEMP_DIR}/home-mcp-mismatch"
	local canonical="${fake_home}/.local/bin/gitnexus"
	local other="${fake_home}/.npm-global/bin/gitnexus"
	local ps_fixture="${TEST_TEMP_DIR}/mcp-mismatch.ps"
	init_git_repo "$repo"
	write_fake_gitnexus "$canonical" "1.6.6"
	write_fake_gitnexus "$other" "1.6.6"
	printf 'user 123 node %s mcp\n' "$other" >"$ps_fixture"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.local/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD="cat '${ps_fixture}'"

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"live MCP GitNexus paths differ from canonical agent path."* ]]
}

@test "gitnexus-status reports INFO when no live MCP processes are detected" {
	local repo="${TEST_TEMP_DIR}/no-mcp"
	local fake_home="${TEST_TEMP_DIR}/home-no-mcp"
	local canonical="${fake_home}/.local/bin/gitnexus"
	init_git_repo "$repo"
	write_fake_gitnexus "$canonical" "1.6.6"

	run_gitnexus_status "$repo" \
		HOME="$fake_home" \
		PATH="${fake_home}/.local/bin:/usr/bin:/bin" \
		GITNEXUS_CANONICAL_BIN="$canonical" \
		GITNEXUS_STATUS_PS_CMD='true'

	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"No live GitNexus MCP processes detected."* ]]
	[[ "${output}" == *"MCP path alignment cannot be verified until an MCP is running."* ]]
}

@test "gitnexus-status reports NO_INDEX in fixture repo without .gitnexus" {
	local repo="${TEST_TEMP_DIR}/no-index"
	init_git_repo "$repo"

	run env DOTFILES_DIR="${DOTFILES_DIR}" bash -c "cd '${repo}' && bash '${SCRIPT}'"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"NO_INDEX"* ]]
}

@test "gitnexus-status recommends the canonical human refresh command" {
	local repo="${TEST_TEMP_DIR}/canonical-refresh"
	local broken_hint="gnx-analyze-here --"" --skip-agents-md"
	init_git_repo "$repo"

	run env DOTFILES_DIR="${DOTFILES_DIR}" bash -c "cd '${repo}' && bash '${SCRIPT}'"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"gnx-analyze-here --skip-agents-md"* ]]
	[[ "${output}" != *"${broken_hint}"* ]]
}

@test "gitnexus-status reports STALE when lastCommit differs from HEAD" {
	local repo="${TEST_TEMP_DIR}/stale"
	init_git_repo "$repo"
	mkdir -p "$repo/.gitnexus"
	cat >"$repo/.gitnexus/meta.json" <<'EOF'
{
  "lastCommit": "0000000000000000000000000000000000000000",
  "indexedAt": "2026-01-01T00:00:00.000Z",
  "stats": { "files": 1, "nodes": 2, "edges": 3 }
}
EOF

	run env DOTFILES_DIR="${DOTFILES_DIR}" bash -c "cd '${repo}' && bash '${SCRIPT}'"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"STALE"* ]]
}

@test "gitnexus-status warns about lock file without deleting lbug" {
	local repo="${TEST_TEMP_DIR}/lock"
	init_git_repo "$repo"
	mkdir -p "$repo/.gitnexus"
	echo "lock" >"$repo/.gitnexus/lbug"

	run env DOTFILES_DIR="${DOTFILES_DIR}" bash -c "cd '${repo}' && bash '${SCRIPT}'"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Lock file present"* ]]
	[[ "${output}" == *"Do not delete .gitnexus/lbug"* ]]
	[[ -f "$repo/.gitnexus/lbug" ]]
}

@test "install.mk exposes make gitnexus-status" {
	grep -q '^gitnexus-status:' "${INSTALL_MK}"
	grep -q 'scripts/gitnexus-status.sh' "${INSTALL_MK}"
}

@test "operational policy prohibits npx gitnexus as default agent path" {
	[[ -f "${POLICY}" ]]
	grep -q 'npx gitnexus' "${POLICY}"
	grep -q 'prohibidas salvo petición explícita' "${POLICY}"
}

@test "gitnexus skills no longer recommend npx gitnexus analyze as default" {
	local skill
	for skill in \
		"${SKILLS_DIR}/gitnexus-exploring/SKILL.md" \
		"${SKILLS_DIR}/gitnexus-debugging/SKILL.md" \
		"${SKILLS_DIR}/gitnexus-impact-analysis/SKILL.md" \
		"${SKILLS_DIR}/gitnexus-refactoring/SKILL.md" \
		"${SKILLS_DIR}/gitnexus-cli/SKILL.md"; do
		[[ -f "$skill" ]]
		run grep -F 'npx gitnexus analyze' "$skill"
		[[ "${status}" -eq 1 ]]
	done
	grep -q 'make gitnexus-status' "${SKILLS_DIR}/gitnexus-cli/SKILL.md"
}
