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

bats_require_minimum_version 1.5.0

@test "gitnexus-status script exists and is executable" {
	[[ -f "${SCRIPT}" ]]
	[[ -x "${SCRIPT}" ]]
}

@test "gitnexus-status script does not invoke mutating gitnexus commands" {
	run grep -E '(^|[^#].*)(gitnexus analyze|gitnexus wiki|gitnexus clean|npx gitnexus|rm .*\.gitnexus/lbug)' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
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
