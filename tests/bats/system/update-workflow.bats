#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

make_node_stub() {
	local dir="$1" version="$2"
	mkdir -p "$dir"
	cat >"${dir}/node" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) echo "${version}";; *) exit 0;; esac
EOF
	cat >"${dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.0.0";; install) exit 0;; *) exit 0;; esac
EOF
	cat >"${dir}/gitnexus" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "gitnexus 1.6.5";; *) exit 0;; esac
EOF
	chmod +x "${dir}/node" "${dir}/npm" "${dir}/gitnexus"
}

@test "update scripts pass bash syntax checks" {
	run bash -n "${DOTFILES_DIR}/scripts/update/update.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-projects.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	run bash -n "${DOTFILES_DIR}/scripts/update/update-excalidraw.sh"
	[[ "${status}" -eq 0 ]]
}

@test "Make exposes public update and Excalidraw targets" {
	for target in update update-windows update-wsl update-projects update-check excalidraw-start excalidraw-stop excalidraw-status excalidraw-update; do
		run make -n -C "${DOTFILES_DIR}" "$target"
		[[ "${status}" -eq 0 ]]
	done
}

@test "make update mock run records Windows warning and excludes projects" {
	run env DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Pandoc failed with installer exit code 1603"* ]]
	[[ "${output}" == *"Personal projects are not part of make update"* ]]
	[[ -f "${TEST_TEMP_DIR}/run/windows-results.tsv" ]]
	[[ -f "${TEST_TEMP_DIR}/run/wsl-results.tsv" ]]
}

@test "make update mock records successful Windows results when provided" {
	run env DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=ok DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-ok" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"WinGet: mocked winget success"* ]]
	[[ "${output}" == *"WSL update: mocked wsl --update"* ]]
	[[ "${output}" != *"Pandoc failed"* ]]
}

@test "make update mock surfaces WinGet package failure without aborting WSL" {
	local stub_dir="${TEST_TEMP_DIR}/node20"
	make_node_stub "$stub_dir" "v20.18.2"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=winget-failure DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-winget" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"WinGet: Pandoc failed with installer exit code 1603"* ]]
	[[ "${output}" == *"WSL update: mocked wsl --update"* ]]
	[[ "${output}" == *"Node v20.18.2 is below required >=22"* ]]
	[[ "${output}" == *"GitNexus: skipped because Node runtime is incompatible"* ]]
	[[ "${output}" == *"Completed with incidents"* ]]
}

@test "make update mock surfaces wsl --update failure and never uses shutdown" {
	run env DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=wsl-failure DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-wsl-fail" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"WSL update: wsl --update failed with exit 1"* ]]
	[[ "${output}" == *"Completed with incidents"* ]]
	run grep -Eq 'Run-Logged.*wsl --shutdown|^[[:space:]]*wsl --shutdown' "${DOTFILES_DIR}/scripts/update"/*.sh "${DOTFILES_DIR}/scripts/update"/*.ps1
	[[ "${status}" -ne 0 ]]
}

@test "make update mock does not wait indefinitely when Windows result is missing" {
	run env DOTFILES_FORCE_WSL=1 DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=missing DOTFILES_UPDATE_WINDOWS_TIMEOUT=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-missing" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"No structured Windows result was produced before timeout (1s)"* ]]
	[[ "${output}" == *"Completed with incidents"* ]]
}

@test "make update mock consolidates multiple Windows incidents" {
	run env DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=multi-failure DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-multi" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"WinGet: Pandoc failed with installer exit code 1603"* ]]
	[[ "${output}" == *"WSL update: wsl --update failed with exit 1"* ]]
	[[ "${output}" == *"Completed with incidents"* ]]
}

@test "update-check warns on Node 20 and prints install action" {
	local stub_dir="${TEST_TEMP_DIR}/node20-check"
	make_node_stub "$stub_dir" "v20.18.2"
	run env PATH="${stub_dir}:/usr/bin:/bin" "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node v20.18.2 is below required >=22 for GitNexus"* ]]
	[[ "${output}" == *"Ejecuta: make install-node-stack"* ]]
}

@test "update-check accepts Node 22 and Node 24" {
	local stub_dir="${TEST_TEMP_DIR}/node22-check"
	make_node_stub "$stub_dir" "v22.12.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node v22.12.0 satisfies >=22"* ]]

	local stub_dir24="${TEST_TEMP_DIR}/node24-check"
	make_node_stub "$stub_dir24" "v24.11.1"
	run env PATH="${stub_dir24}:/usr/bin:/bin" "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node v24.11.1 satisfies >=22"* ]]
}

@test "update-wsl does not declare GitNexus success under Node 20" {
	local stub_dir="${TEST_TEMP_DIR}/node20-wsl"
	make_node_stub "$stub_dir" "v20.18.2"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-node20" "${DOTFILES_DIR}/scripts/update/update-wsl.sh" --section tools
	[[ "${status}" -eq 0 ]]
	grep -q 'Node v20.18.2 is below required >=22' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
	grep -q 'GitNexus.*skipped because Node runtime is incompatible' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
	! grep -q 'GitNexus.*usable' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
}

@test "update PowerShell script invokes wsl --update and never wsl --shutdown" {
	grep -q 'wsl --update' "${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	! grep -Eq '^.*Run-Logged.*wsl --shutdown|^[[:space:]]*wsl --shutdown' "${DOTFILES_DIR}/scripts/update/update-windows.ps1"
}

@test "ups command is absent from aliases and Make targets" {
	run grep -Eq '(^|[[:space:]])ups\\(\\)' "${DOTFILES_DIR}/aliases"
	[[ "${status}" -ne 0 ]]
	run grep -Eq '^ups:' "${DOTFILES_DIR}/Makefile" "${DOTFILES_DIR}"/*.mk
	[[ "${status}" -ne 0 ]]
}
