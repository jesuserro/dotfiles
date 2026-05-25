#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	setup_temp_dir
	FAKE_BIN="${TEST_TEMP_DIR}/bin"
	FAKE_HOME="${TEST_TEMP_DIR}/home"
	mkdir -p "$FAKE_BIN" "$FAKE_HOME"
	for cmd in bash python3 mktemp rm dirname pwd mkdir readlink chmod ln grep; do
		ln -s "$(command -v "$cmd")" "${FAKE_BIN}/${cmd}"
	done
}

teardown() {
	teardown_temp_dir
}

write_docker_config() {
	local dir="$1" body="$2"
	mkdir -p "$dir"
	printf '%s\n' "$body" >"${dir}/config.json"
}

run_credential_check() {
	env HOME="$FAKE_HOME" PATH="${FAKE_BIN}" DOTFILES_FORCE_WSL="${DOTFILES_FORCE_WSL:-1}" DOCKER_CONFIG="${DOCKER_CONFIG:-${FAKE_HOME}/.docker}" bash -c "
set -euo pipefail
source '${DOTFILES_DIR}/scripts/update/lib/environment.sh'
source '${DOTFILES_DIR}/scripts/update/lib/docker_desktop_credentials.sh'
if check_docker_credentials_for_images \"\$@\"; then
  printf 'OK:%s\n' \"\$DOCKER_CREDENTIALS_LAST_MESSAGE\"
else
  rc=\$?
  printf 'FAIL:%s\n' \"\$DOCKER_CREDENTIALS_LAST_MESSAGE\"
  exit \"\$rc\"
fi
" bash "$@"
}

@test "non WSL or missing Docker config does not fail or repair" {
	DOCKER_CONFIG="${TEST_TEMP_DIR}/missing-config" run run_credential_check "ghcr.io/yctimlin/mcp_excalidraw:latest"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Docker config not found"* ]]
}

@test "credsStore desktop.exe validates exact docker-credential-desktop.exe" {
	write_docker_config "${FAKE_HOME}/.docker" '{"credsStore":"desktop.exe"}'
	cat >"${FAKE_BIN}/docker-credential-desktop.exe" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "${FAKE_BIN}/docker-credential-desktop.exe"
	run run_credential_check "ghcr.io/yctimlin/mcp_excalidraw:latest"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"helpers available"* ]]
}

@test "credsStore desktop.exe fails clearly when exact helper is absent" {
	write_docker_config "${FAKE_HOME}/.docker" '{"credsStore":"desktop.exe"}'
	run run_credential_check "ghcr.io/yctimlin/mcp_excalidraw:latest"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"docker-credential-desktop.exe"* ]]
	[[ "$output" == *"make install-docker-desktop-helper"* ]]
}

@test "credsStore desktop requires docker-credential-desktop and not only exe helper" {
	write_docker_config "${FAKE_HOME}/.docker" '{"credsStore":"desktop"}'
	cat >"${FAKE_BIN}/docker-credential-desktop.exe" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
	chmod +x "${FAKE_BIN}/docker-credential-desktop.exe"
	run run_credential_check "ghcr.io/yctimlin/mcp_excalidraw:latest"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"docker-credential-desktop ("* ]]
	[[ "$output" != *"docker-credential-desktop.exe ("* ]]
}

@test "credHelpers only apply to image registry being pulled" {
	write_docker_config "${FAKE_HOME}/.docker" '{"credHelpers":{"registry.example.com":"desktop.exe"}}'
	run run_credential_check "ghcr.io/yctimlin/mcp_excalidraw:latest"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"no credential helper requirement"* ]]

	run run_credential_check "registry.example.com/team/image:latest"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"registry.example.com"* ]]
	[[ "$output" == *"docker-credential-desktop.exe"* ]]
}

@test "custom DOCKER_CONFIG is respected" {
	local custom="${TEST_TEMP_DIR}/custom-docker"
	write_docker_config "$custom" '{"credsStore":"desktop.exe"}'
	DOCKER_CONFIG="$custom" run run_credential_check "ghcr.io/yctimlin/mcp_excalidraw:latest"
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"docker-credential-desktop.exe"* ]]
}

@test "repair creates symlink from global Docker Desktop source and keeps config untouched" {
	local config="${FAKE_HOME}/.docker"
	local global_root="${TEST_TEMP_DIR}/Program Files"
	local source="${global_root}/Docker/Docker/resources/bin/docker-credential-desktop.exe"
	write_docker_config "$config" '{"credsStore":"desktop.exe"}'
	local before
	before="$(<"${config}/config.json")"
	mkdir -p "$(dirname "$source")"
	printf '#!/usr/bin/env bash\nexit 0\n' >"$source"
	chmod +x "$source"

	run env HOME="$FAKE_HOME" PATH="$FAKE_BIN" DOTFILES_FORCE_WSL=1 DOCKER_DESKTOP_HELPER_PROGRAM_FILES_ROOT="$global_root" bash "${DOTFILES_DIR}/scripts/install-docker-desktop-helper.sh"
	[[ "$status" -eq 0 ]]
	[[ -L "${FAKE_HOME}/.local/bin/docker-credential-desktop.exe" ]]
	[[ "$(readlink "${FAKE_HOME}/.local/bin/docker-credential-desktop.exe")" == "$source" ]]
	[[ "$(<"${config}/config.json")" == "$before" ]]

	run env HOME="$FAKE_HOME" PATH="$FAKE_BIN" DOTFILES_FORCE_WSL=1 DOCKER_DESKTOP_HELPER_PROGRAM_FILES_ROOT="$global_root" bash "${DOTFILES_DIR}/scripts/install-docker-desktop-helper.sh"
	[[ "$status" -eq 0 ]]
	[[ "$(<"${config}/config.json")" == "$before" ]]
}

@test "repair creates exact desktop helper name from per-user Docker Desktop source" {
	local user_root="${TEST_TEMP_DIR}/LocalAppData"
	local source="${user_root}/Docker/resources/bin/docker-credential-desktop.exe"
	write_docker_config "${FAKE_HOME}/.docker" '{"credsStore":"desktop"}'
	mkdir -p "$(dirname "$source")"
	printf '#!/usr/bin/env bash\nexit 0\n' >"$source"
	chmod +x "$source"

	run env HOME="$FAKE_HOME" PATH="$FAKE_BIN" DOTFILES_FORCE_WSL=1 DOCKER_DESKTOP_HELPER_PROGRAM_FILES_ROOT="${TEST_TEMP_DIR}/missing-program-files" DOCKER_DESKTOP_HELPER_LOCALAPPDATA_ROOT="$user_root" bash "${DOTFILES_DIR}/scripts/install-docker-desktop-helper.sh"
	[[ "$status" -eq 0 ]]
	[[ -L "${FAKE_HOME}/.local/bin/docker-credential-desktop" ]]
	[[ "$(readlink "${FAKE_HOME}/.local/bin/docker-credential-desktop")" == "$source" ]]
}
