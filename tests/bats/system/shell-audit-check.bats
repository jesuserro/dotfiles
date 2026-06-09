#!/usr/bin/env bats
# shell-audit-check: focused shell audit contract.

load '../helpers/common'

bats_require_minimum_version 1.5.0

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	SCRIPT="${DOTFILES_DIR}/scripts/shell-audit-check.sh"
	TESTING_DOC="${DOTFILES_DIR}/docs/TESTING.md"
	CONVENTIONS_DOC="${DOTFILES_DIR}/docs/SCRIPT_CONVENTIONS.md"
	FAKE_REPO="${TEST_TEMP_DIR}/repo"
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	TOOL_LOG="${TEST_TEMP_DIR}/tool.log"
	mkdir -p "${FAKE_REPO}" "${FAKE_BIN}"
	: >"${TOOL_LOG}"
}

teardown() {
	teardown_temp_dir
}

write_tool_stubs() {
	cat >"${FAKE_BIN}/shellcheck" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
	printf 'shellcheck:%s\n' "${arg}" >>"${TOOL_LOG}"
done
EOF
	cat >"${FAKE_BIN}/shfmt" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
	printf 'shfmt:%s\n' "${arg}" >>"${TOOL_LOG}"
done
EOF
	cat >"${FAKE_BIN}/zsh" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
	printf 'zsh:%s\n' "${arg}" >>"${TOOL_LOG}"
done
EOF
	chmod +x "${FAKE_BIN}/shellcheck" "${FAKE_BIN}/shfmt" "${FAKE_BIN}/zsh"
}

write_fixture_repo() {
	mkdir -p \
		"${FAKE_REPO}/bin" \
		"${FAKE_REPO}/scripts/lib" \
		"${FAKE_REPO}/scripts/__pycache__" \
		"${FAKE_REPO}/tests/bats/system" \
		"${FAKE_REPO}/zsh" \
		"${FAKE_REPO}/.chezmoiscripts" \
		"${FAKE_REPO}/dot_local/bin" \
		"${FAKE_REPO}/.githooks" \
		"${FAKE_REPO}/tmux" \
		"${FAKE_REPO}/termux"

	cat >"${FAKE_REPO}/bin/in-scope" <<'EOF'
#!/usr/bin/env bash
echo in-scope
EOF
	printf 'not shell\n' >"${FAKE_REPO}/bin/not-shell"
	cat >"${FAKE_REPO}/scripts/main.sh" <<'EOF'
#!/usr/bin/env bash
echo main
EOF
	cat >"${FAKE_REPO}/scripts/lib/lib.sh" <<'EOF'
#!/usr/bin/env bash
echo lib
EOF
	printf '%s\n' '#!/usr/bin/env bats' '@test "fixture" { true; }' >"${FAKE_REPO}/tests/bats/system/audit.bats"
	printf 'echo zsh\n' >"${FAKE_REPO}/zsh/module.zsh"

	printf '# doc\n' >"${FAKE_REPO}/scripts/readme.md"
	printf 'print("py")\n' >"${FAKE_REPO}/scripts/tool.py"
	printf 'Write-Host ps1\n' >"${FAKE_REPO}/scripts/update.ps1"
	printf 'pyc\n' >"${FAKE_REPO}/scripts/__pycache__/tool.pyc"
	printf '#!/usr/bin/env bash\necho template {{ .chezmoi.homeDir }}\n' >"${FAKE_REPO}/.chezmoiscripts/run.sh.tmpl"
	printf '{{ .chezmoi.homeDir }}/bin/tool\n' >"${FAKE_REPO}/dot_local/bin/symlink_tool.tmpl"
	printf '#!/usr/bin/env bash\necho example\n' >"${FAKE_REPO}/scripts/test.sh.example"
	printf '#!/usr/bin/env bash\necho hook\n' >"${FAKE_REPO}/.githooks/pre-commit"
	printf '#!/usr/bin/env bash\necho tmux\n' >"${FAKE_REPO}/tmux/home.sh"
	printf '#!/usr/bin/env bash\necho termux\n' >"${FAKE_REPO}/termux/install.sh"

	git -C "${FAKE_REPO}" init -q
	git -C "${FAKE_REPO}" config user.email "test@example.com"
	git -C "${FAKE_REPO}" config user.name "Test User"
	git -C "${FAKE_REPO}" add .
}

run_shell_audit() {
	run env \
		DOTFILES_DIR="${FAKE_REPO}" \
		TOOL_LOG="${TOOL_LOG}" \
		PATH="${FAKE_BIN}:/usr/bin:/bin" \
		bash "${SCRIPT}"
}

@test "shell-audit-check script exists and is executable" {
	[[ -f "${SCRIPT}" ]]
	[[ -x "${SCRIPT}" ]]
}

@test "shell-audit-check script passes bash syntax check" {
	run bash -n "${SCRIPT}"
	[[ "${status}" -eq 0 ]]
}

@test "Makefile defines shell-audit-check target and help mentions it" {
	run make -pn -C "${DOTFILES_DIR}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"shell-audit-check:"* ]]

	run make -C "${DOTFILES_DIR}" help
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"make shell-audit-check"* ]]
}

@test "shell-audit-check uses git ls-files and not find for scope discovery" {
	grep -q 'git .*ls-files' "${SCRIPT}"
	grep -q 'shellcheck -x -S warning' "${SCRIPT}"
	run grep -q 'find ' "${SCRIPT}"
	[[ "${status}" -eq 1 ]]
}

@test "shell-audit-check routes only intended files to shellcheck shfmt and zsh" {
	write_tool_stubs
	write_fixture_repo

	run_shell_audit
	[[ "${status}" -eq 0 ]]

	grep -q "shellcheck:${FAKE_REPO}/bin/in-scope" "${TOOL_LOG}"
	grep -q "shellcheck:${FAKE_REPO}/scripts/main.sh" "${TOOL_LOG}"
	grep -q "shellcheck:${FAKE_REPO}/scripts/lib/lib.sh" "${TOOL_LOG}"
	grep -q "shellcheck:${FAKE_REPO}/tests/bats/system/audit.bats" "${TOOL_LOG}"

	grep -q "shfmt:${FAKE_REPO}/bin/in-scope" "${TOOL_LOG}"
	grep -q "shfmt:${FAKE_REPO}/scripts/main.sh" "${TOOL_LOG}"
	grep -q "shfmt:${FAKE_REPO}/scripts/lib/lib.sh" "${TOOL_LOG}"

	grep -q "zsh:${FAKE_REPO}/zsh/module.zsh" "${TOOL_LOG}"
}

@test "shell-audit-check keeps noisy historical files out of tools" {
	write_tool_stubs
	write_fixture_repo

	run_shell_audit
	[[ "${status}" -eq 0 ]]

	local excluded
	for excluded in \
		'bin/not-shell' \
		'scripts/readme.md' \
		'scripts/tool.py' \
		'scripts/update.ps1' \
		'scripts/__pycache__/tool.pyc' \
		'.chezmoiscripts/run.sh.tmpl' \
		'dot_local/bin/symlink_tool.tmpl' \
		'scripts/test.sh.example' \
		'.githooks/pre-commit' \
		'tmux/home.sh' \
		'termux/install.sh'; do
		run grep -F "${FAKE_REPO}/${excluded}" "${TOOL_LOG}"
		[[ "${status}" -eq 1 ]] || {
			echo "unexpected audited file: ${excluded}" >&2
			return 1
		}
	done

	run grep -F "shfmt:${FAKE_REPO}/tests/bats/system/audit.bats" "${TOOL_LOG}"
	[[ "${status}" -eq 1 ]]
}

@test "shell-audit-check is read-only for fixture files" {
	write_tool_stubs
	write_fixture_repo
	git -C "${FAKE_REPO}" commit -q -m "fixture"

	run_shell_audit
	[[ "${status}" -eq 0 ]]
	[[ -z "$(git -C "${FAKE_REPO}" status --short)" ]]
}

@test "docs recommend shell-audit-check for agent shell audits" {
	grep -q 'make shell-audit-check' "${TESTING_DOC}"
	grep -q 'make shell-audit-check' "${CONVENTIONS_DOC}"
	grep -qi 'Chezmoi templates' "${TESTING_DOC}"
	grep -qi 'zsh -n' "${TESTING_DOC}"
}
