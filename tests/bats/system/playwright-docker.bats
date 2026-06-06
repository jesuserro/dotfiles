#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	WRAPPER="${DOTFILES_DIR}/bin/playwright-docker"
	setup_temp_dir
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	PROJECT_DIR="${TEST_TEMP_DIR}/project"
	FAKE_HOME="${TEST_TEMP_DIR}/home"
	DOCKER_LOG="${TEST_TEMP_DIR}/docker.args"
	export DOCKER_LOG
	mkdir -p "$FAKE_BIN" "$PROJECT_DIR" "$FAKE_HOME"
	for cmd in bash dirname id mkdir; do
		ln -sf "$(command -v "$cmd")" "${FAKE_BIN}/${cmd}"
	done
	cat >"${FAKE_BIN}/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$DOCKER_LOG"
EOF
	chmod +x "${FAKE_BIN}/docker"
}

teardown() {
	teardown_temp_dir
}

run_wrapper() {
	cd "$PROJECT_DIR" || exit 1
	env HOME="$FAKE_HOME" PATH="${FAKE_BIN}:/usr/bin:/bin" "$WRAPPER" "$@"
}

assert_arg() {
	local expected="$1"
	grep -Fxq -- "$expected" "$DOCKER_LOG"
}

assert_no_arg() {
	local unexpected="$1"
	run grep -Fxq -- "$unexpected" "$DOCKER_LOG"
	[[ "$status" -ne 0 ]]
}

@test "playwright-docker runs default image with scoped project and downloads mounts" {
	run run_wrapper npx playwright --version
	[[ "$status" -eq 0 ]]
	assert_arg "run"
	assert_arg "--rm"
	assert_arg "--init"
	assert_arg "--ipc=host"
	assert_arg "--user"
	assert_arg "$(id -u):$(id -g)"
	assert_arg "-e"
	assert_arg "HOME=/tmp/playwright-home"
	assert_arg "PLAYWRIGHT_DOWNLOADS_PATH=/workspace/downloads"
	assert_arg "-v"
	assert_arg "${PROJECT_DIR}:/workspace/project"
	assert_arg "${PROJECT_DIR}/downloads:/workspace/downloads"
	assert_arg "-w"
	assert_arg "/workspace/project"
	assert_arg "mcr.microsoft.com/playwright:v1.60.0-noble"
	assert_arg "npx"
	assert_arg "playwright"
	assert_arg "--version"
	[[ -d "${PROJECT_DIR}/downloads" ]]
}

@test "playwright-docker respects image override" {
	run env PLAYWRIGHT_DOCKER_IMAGE="example.test/playwright-python:custom" bash -c "cd '$PROJECT_DIR' && HOME='$FAKE_HOME' PATH='$FAKE_BIN:/usr/bin:/bin' '$WRAPPER' python scripts/download_pdfs.py"
	[[ "$status" -eq 0 ]]
	assert_arg "example.test/playwright-python:custom"
	assert_arg "python"
	assert_arg "scripts/download_pdfs.py"
}

@test "playwright-docker respects downloads override" {
	local downloads="${TEST_TEMP_DIR}/pdf-output"
	run env PLAYWRIGHT_DOCKER_DOWNLOADS="$downloads" bash -c "cd '$PROJECT_DIR' && HOME='$FAKE_HOME' PATH='$FAKE_BIN:/usr/bin:/bin' '$WRAPPER' node scripts/download-pdfs.js"
	[[ "$status" -eq 0 ]]
	assert_arg "${downloads}:/workspace/downloads"
	[[ -d "$downloads" ]]
}

@test "playwright-docker passes extra docker args without publishing ports by default" {
	run env PLAYWRIGHT_DOCKER_EXTRA_ARGS="--add-host=hostmachine:host-gateway --network none" bash -c "cd '$PROJECT_DIR' && HOME='$FAKE_HOME' PATH='$FAKE_BIN:/usr/bin:/bin' '$WRAPPER' node script.js"
	[[ "$status" -eq 0 ]]
	assert_arg "--add-host=hostmachine:host-gateway"
	assert_arg "--network"
	assert_arg "none"
	assert_no_arg "-p"
	assert_no_arg "--publish"
	run grep -Eq -- '^--publish=|^-p[0-9:]' "$DOCKER_LOG"
	[[ "$status" -ne 0 ]]
}

@test "playwright-docker does not mount HOME by default" {
	run run_wrapper node script.js
	[[ "$status" -eq 0 ]]
	assert_file_not_contains "$DOCKER_LOG" "${FAKE_HOME}:"
	assert_file_not_contains "$DOCKER_LOG" "$HOME:"
}

@test "playwright-docker exits 2 and shows help without a command" {
	run env HOME="$FAKE_HOME" PATH="${FAKE_BIN}:/usr/bin:/bin" "$WRAPPER"
	[[ "$status" -eq 2 ]]
	[[ "$output" == *"Usage: playwright-docker <command> [args...]"* ]]
	[[ "$output" == *"playwright-docker node scripts/download-pdfs.js"* ]]
	[[ ! -f "$DOCKER_LOG" ]]
}

@test "playwright-docker help exits zero" {
	run env HOME="$FAKE_HOME" PATH="${FAKE_BIN}:/usr/bin:/bin" "$WRAPPER" --help
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"PLAYWRIGHT_DOCKER_IMAGE"* ]]
	[[ ! -f "$DOCKER_LOG" ]]
}

@test "chezmoi manages playwright-docker as a direct local bin symlink" {
	local tmpl="${DOTFILES_DIR}/dot_local/bin/symlink_playwright-docker.tmpl"
	[[ -f "$tmpl" ]]
	[[ "$(cat "$tmpl")" == '{{ .chezmoi.homeDir }}/dotfiles/bin/playwright-docker' ]]
	[[ ! -f "${DOTFILES_DIR}/.chezmoiscripts/run_after_16_link_playwright_docker.sh.tmpl" ]]
}

@test "chezmoi managed list includes scoped playwright-docker target" {
	skip_if_command_missing "chezmoi"

	run chezmoi --source="$DOTFILES_DIR" managed
	[[ "$status" -eq 0 ]]
	[[ "$output" == *$'.local/bin/playwright-docker'* ]]
}
