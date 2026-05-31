#!/usr/bin/env bats

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	INSTALL_AGENT_SKILLS="${DOTFILES_DIR}/scripts/install-agent-skills.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

write_node_stub() {
	local dir="$1" version="$2"
	mkdir -p "$dir"
	cat >"${dir}/node" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  printf '%s\n' "${version}"
  exit 0
fi
exit 0
EOF
	chmod +x "${dir}/node"
}

link_required_helpers_without_npx() {
	local dir="$1"
	mkdir -p "$dir"
	local cmd
	for cmd in bash basename dirname head ln mkdir mktemp rm rmdir tr; do
		if command -v "$cmd" >/dev/null 2>&1; then
			ln -sf "$(command -v "$cmd")" "${dir}/$cmd"
		fi
	done
}

setup_fake_dotfiles_skills_tree() {
	FAKE_DOTFILES_ROOT="${TEST_TEMP_DIR}/fake-dotfiles"
	FAKE_SKILLS_ROOT="${FAKE_DOTFILES_ROOT}/ai/assets/skills"
	mkdir -p \
		"${FAKE_SKILLS_ROOT}/ops/to-issues" \
		"${FAKE_SKILLS_ROOT}/docs" \
		"${FAKE_SKILLS_ROOT}/gitnexus"
	printf 'local\n' >"${FAKE_SKILLS_ROOT}/ops/to-issues/SKILL.md"
}

write_mock_npx_stub() {
	local stub_dir="$1"
	write_node_stub "$stub_dir" "v24.15.0"
	cat >"${stub_dir}/npx" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "${stub_dir}/npx"
}

create_matt_symlink_at_skills_root() {
	local name="$1"
	ln -sf "../../.agents/skills/${name}" "${FAKE_SKILLS_ROOT}/${name}"
}

@test "install-agent-skills script exists and passes bash syntax check" {
	[[ -f "${INSTALL_AGENT_SKILLS}" ]]
	run bash -n "${INSTALL_AGENT_SKILLS}"
	[[ "${status}" -eq 0 ]]
}

@test "install-agent-skills does not use single-skill selectors" {
	run grep -qE 'skill=handoff|--skill[[:space:]]+handoff' "${INSTALL_AGENT_SKILLS}"
	[[ "${status}" -eq 1 ]]
}

@test "dry-run prints full Matt catalog command without executing npx" {
	local stub_dir="${TEST_TEMP_DIR}/dry-run-bin"
	link_required_helpers_without_npx "$stub_dir"
	cat >"${stub_dir}/npx" <<'EOF'
#!/usr/bin/env bash
echo "npx should not run" >&2
exit 99
EOF
	chmod +x "${stub_dir}/npx"

	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$stub_dir" "$bash_abs" "${INSTALL_AGENT_SKILLS}" --dry-run
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"npx skills add mattpocock/skills -y -g"* ]]
	[[ "${output}" != *"--skill handoff"* ]]
	[[ "${output}" != *"skill=handoff"* ]]
	[[ "${output}" != *"npx should not run"* ]]
}

@test "fails clearly when npx is missing" {
	local stub_dir="${TEST_TEMP_DIR}/missing-npx-bin"
	link_required_helpers_without_npx "$stub_dir"
	write_node_stub "$stub_dir" "v24.15.0"

	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$stub_dir" "$bash_abs" "${INSTALL_AGENT_SKILLS}"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"npx not found. Install or repair the Node stack first:"* ]]
	[[ "${output}" == *"make install-node-stack"* ]]
}

@test "mock npx receives exactly the full Matt catalog command" {
	local stub_dir="${TEST_TEMP_DIR}/mock-npx-bin"
	local trace="${TEST_TEMP_DIR}/npx.trace"
	setup_fake_dotfiles_skills_tree
	link_required_helpers_without_npx "$stub_dir"
	write_node_stub "$stub_dir" "v24.15.0"
	cat >"${stub_dir}/npx" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >"${trace}"
exit 0
EOF
	chmod +x "${stub_dir}/npx"

	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$stub_dir" DOTFILES_ROOT="${FAKE_DOTFILES_ROOT}" "$bash_abs" "${INSTALL_AGENT_SKILLS}"
	[[ "${status}" -eq 0 ]]
	[[ "$(cat "$trace")" == "skills add mattpocock/skills -y -g" ]]
	[[ "${output}" == *"Matt Pocock skills catalog installed/updated"* ]]
}

@test "managed Node overlay lets mocked npx run under compatible Node" {
	local shadow_dir="${TEST_TEMP_DIR}/shadow-bin"
	local npm_prefix="${TEST_TEMP_DIR}/npm-prefix"
	local managed="${TEST_TEMP_DIR}/managed-node"
	local trace="${TEST_TEMP_DIR}/overlay.trace"
	setup_fake_dotfiles_skills_tree
	mkdir -p "$shadow_dir" "${npm_prefix}/bin"
	link_required_helpers_without_npx "$shadow_dir"
	write_node_stub "$shadow_dir" "v20.18.2"
	cat >"$managed" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  printf 'v24.15.0\n'
  exit 0
fi
exit 0
EOF
	chmod +x "$managed"
	cat >"${npm_prefix}/bin/npx" <<EOF
#!/usr/bin/env bash
{
  printf 'args:%s\n' "\$*"
  printf 'node:%s\n' "\$(command -v node)"
  printf 'version:%s\n' "\$(node --version)"
} >"${trace}"
exit 0
EOF
	chmod +x "${npm_prefix}/bin/npx"

	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$shadow_dir" DOTFILES_ROOT="${FAKE_DOTFILES_ROOT}" DOTFILES_MANAGED_NODE_BIN="$managed" NPM_CONFIG_PREFIX="$npm_prefix" "$bash_abs" "${INSTALL_AGENT_SKILLS}"
	[[ "${status}" -eq 0 ]]
	grep -q '^args:skills add mattpocock/skills -y -g$' "$trace"
	grep -q '^node:.*/node-runtime\.[^/]*/node$' "$trace"
	grep -q '^version:v24.15.0$' "$trace"
	[[ "${output}" == *"Node runtime for external skills: switched from v20.18.2"* ]]
}

@test "removes Matt symlinks from ai/assets/skills after mocked install" {
	local stub_dir="${TEST_TEMP_DIR}/cleanup-bin"
	setup_fake_dotfiles_skills_tree
	write_mock_npx_stub "$stub_dir"
	link_required_helpers_without_npx "$stub_dir"
	create_matt_symlink_at_skills_root handoff
	create_matt_symlink_at_skills_root to-issues

	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$stub_dir" DOTFILES_ROOT="${FAKE_DOTFILES_ROOT}" "$bash_abs" "${INSTALL_AGENT_SKILLS}"
	[[ "${status}" -eq 0 ]]
	[[ ! -L "${FAKE_SKILLS_ROOT}/handoff" ]]
	[[ ! -L "${FAKE_SKILLS_ROOT}/to-issues" ]]
	[[ -f "${FAKE_SKILLS_ROOT}/ops/to-issues/SKILL.md" ]]
	[[ -d "${FAKE_SKILLS_ROOT}/ops" ]]
	[[ -d "${FAKE_SKILLS_ROOT}/docs" ]]
	[[ -d "${FAKE_SKILLS_ROOT}/gitnexus" ]]
	[[ "${output}" == *"Removed 2 accidental Matt artifact(s)"* ]]
}

@test "dry-run reports Matt symlink cleanup without removing them" {
	local stub_dir="${TEST_TEMP_DIR}/dry-run-cleanup-bin"
	setup_fake_dotfiles_skills_tree
	link_required_helpers_without_npx "$stub_dir"
	create_matt_symlink_at_skills_root handoff

	local bash_abs
	bash_abs="$(command -v bash)"
	run env PATH="$stub_dir" DOTFILES_ROOT="${FAKE_DOTFILES_ROOT}" "$bash_abs" "${INSTALL_AGENT_SKILLS}" --dry-run
	[[ "${status}" -eq 0 ]]
	[[ -L "${FAKE_SKILLS_ROOT}/handoff" ]]
	[[ "${output}" == *"DRY_RUN: would remove Matt symlink: ${FAKE_SKILLS_ROOT}/handoff"* ]]
	[[ "${output}" != *"Removed Matt symlink from canonical skills tree:"* ]]
}

@test "Make targets expose opt-in external skills without wiring make update" {
	run make -n -C "${DOTFILES_DIR}" install-mattpocock-skills
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"scripts/install-agent-skills.sh"* ]]

	run make -n -C "${DOTFILES_DIR}" update-ai-skills
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"scripts/install-agent-skills.sh"* ]]

	run make -n -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-agent-skills.sh"* ]]
}
