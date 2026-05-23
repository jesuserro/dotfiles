#!/usr/bin/env bats
# MCP secrets hook strict/permissive behavior (rendered script, isolated mock source).

load '../helpers/common'

setup() {
	setup_temp_dir
	DOTFILES_DIR="$(get_dotfiles_dir)"
	TEST_HOME="$TEST_TEMP_DIR/test_home"
	MOCK_SOURCE="$TEST_TEMP_DIR/mock_source"
	mkdir -p "$TEST_HOME/.config/sops/age" "$MOCK_SOURCE/scripts/lib"
	cp "${DOTFILES_DIR}/scripts/lib/install_common.sh" "$MOCK_SOURCE/scripts/lib/"
	export HOME="$TEST_HOME"
	SCRIPT="${DOTFILES_DIR}/.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl"
}

teardown() {
	teardown_temp_dir
}

render_secrets_script() {
	sed -e "s|{{ .chezmoi.sourceDir }}|${MOCK_SOURCE}|g" "$SCRIPT"
}

@test "permissive mode exits 0 when no secrets file in source" {
	run bash -c "$(render_secrets_script)"
	[[ "$status" -eq 0 ]]
}

@test "strict mode fails when encrypted secrets exist but sops missing" {
	printf 'token: ENC[AES256_GCM,data=Zm9v,type:str]\n' >"$MOCK_SOURCE/secrets.sops.yaml"
	PATH="/usr/bin:/bin"
	run env MCP_SECRETS_STRICT=1 PATH="$PATH" bash -c "$(render_secrets_script)"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"sops not in PATH"* ]]
}

@test "strict mode fails on sops decrypt error" {
	printf 'token: ENC[AES256_GCM,data=not-valid,type:str]\n' >"$MOCK_SOURCE/secrets.sops.yaml"
	command -v sops >/dev/null || skip "sops not installed"
	run env MCP_SECRETS_STRICT=1 bash -c "$(render_secrets_script)"
	[[ "$status" -eq 1 ]]
	[[ "$output" == *"decrypt failed"* ]]
}
