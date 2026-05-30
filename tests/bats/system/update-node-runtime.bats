#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	NODE_RUNTIME_LIB="${DOTFILES_DIR}/scripts/update/lib/node_runtime.sh"
	UPDATE_WSL="${DOTFILES_DIR}/scripts/update/update-wsl.sh"
	UPDATE_CHECK="${DOTFILES_DIR}/scripts/update/update-check.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

link_core_utils() {
	local dir="$1"
	local cmd
	mkdir -p "$dir"
	for cmd in bash basename cat chmod date dirname env find grep head ln mkdir mktemp pwd readlink rm sed sleep sort tail tee tr uname; do
		if command -v "$cmd" >/dev/null 2>&1; then
			ln -sf "$(command -v "$cmd")" "${dir}/${cmd}"
		fi
	done
}

write_fake_node() {
	local path="$1" version="$2" label="$3"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  echo "${version}"
  exit 0
fi
if [[ -n "\${NODE_RUNTIME_TRACE:-}" ]]; then
  echo "${label}:\${1:-}" >> "\${NODE_RUNTIME_TRACE}"
fi
case "\$(basename "\${1:-}")" in
  npm) [[ "\${2:-}" == "--version" ]] && echo "11.12.1"; exit 0 ;;
  npx) [[ "\${2:-}" == "--version" ]] && echo "11.12.1"; exit 0 ;;
  corepack) [[ "\${2:-}" == "--version" ]] && echo "0.35.0"; exit 0 ;;
  pnpm) [[ "\${2:-}" == "--version" ]] && echo "11.3.0"; exit 0 ;;
  fake-cli) echo "${label}"; exit 0 ;;
esac
exit 0
EOF
	chmod +x "$path"
}

write_node_tool_shims() {
	local dir="$1"
	local name
	mkdir -p "$dir"
	for name in npm npx corepack pnpm fake-cli; do
		cat >"${dir}/${name}" <<'EOF'
#!/usr/bin/env node
// fake node-managed CLI; interpreted by the fake node in tests.
EOF
		chmod +x "${dir}/${name}"
	done
}

run_runtime_probe() {
	local path_value="$1"
	shift
	env PATH="$path_value" "$@" bash -c "source '${NODE_RUNTIME_LIB}'; node_runtime_probe; printf 'effective=%s|%s|%s|%s\nmanaged=%s|%s|%s|%s\n' \"\$NODE_RUNTIME_EFFECTIVE_PATH\" \"\$NODE_RUNTIME_EFFECTIVE_VERSION\" \"\$NODE_RUNTIME_EFFECTIVE_OK\" \"\$NODE_RUNTIME_EFFECTIVE_ORIGIN\" \"\$NODE_RUNTIME_MANAGED_PATH\" \"\$NODE_RUNTIME_MANAGED_VERSION\" \"\$NODE_RUNTIME_MANAGED_OK\" \"\$NODE_RUNTIME_MANAGED_ERROR\""
}

@test "effective compatible Node does not require overlay or recovery message" {
	local bin="${TEST_TEMP_DIR}/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	link_core_utils "$bin"
	write_fake_node "${bin}/node" "v24.15.0" "effective"
	write_fake_node "$managed" "v24.15.0" "managed"

	run run_runtime_probe "$bin" DOTFILES_MANAGED_NODE_BIN="$managed"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"effective=${bin}/node|v24.15.0|1|unknown-shadowing"* ]]
	[[ "$output" == *"managed=${managed}|v24.15.0|1|"* ]]

	run env PATH="$bin" DOTFILES_MANAGED_NODE_BIN="$managed" bash -c "source '${NODE_RUNTIME_LIB}'; if node_runtime_need_overlay; then exit 9; fi"
	[[ "$status" -eq 0 ]]
}

@test "incompatible generic Node without compatible managed candidate fails clearly" {
	local bin="${TEST_TEMP_DIR}/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	link_core_utils "$bin"
	write_fake_node "${bin}/node" "v20.18.2" "effective"
	write_fake_node "$managed" "v20.18.2" "managed"

	run run_runtime_probe "$bin" DOTFILES_MANAGED_NODE_BIN="$managed"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"effective=${bin}/node|v20.18.2|0|unknown-shadowing"* ]]
	[[ "$output" == *"managed=${managed}|v20.18.2|0|managed candidate v20.18.2 is below required >=22"* ]]
}

@test "incompatible cursor-server Node recovers because managed candidate is compatible" {
	local cursor_bin="${TEST_TEMP_DIR}/home/.cursor-server/bin/hash"
	local managed="${TEST_TEMP_DIR}/managed/node"
	link_core_utils "$cursor_bin"
	write_fake_node "${cursor_bin}/node" "v20.18.2" "cursor"
	write_fake_node "$managed" "v24.15.0" "managed"

	run run_runtime_probe "$cursor_bin" DOTFILES_MANAGED_NODE_BIN="$managed"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"effective=${cursor_bin}/node|v20.18.2|0|cursor-server"* ]]
	[[ "$output" == *"managed=${managed}|v24.15.0|1|"* ]]
}

@test "incompatible unknown shadowing also recovers with compatible managed candidate" {
	local shadow_bin="${TEST_TEMP_DIR}/random-agent/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	link_core_utils "$shadow_bin"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v24.15.0" "managed"

	run run_runtime_probe "$shadow_bin" DOTFILES_MANAGED_NODE_BIN="$managed"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"unknown-shadowing"* ]]
	[[ "$output" == *"managed=${managed}|v24.15.0|1|"* ]]
}

@test "DOTFILES_MANAGED_NODE_BIN has precedence and invalid override does not fall back" {
	local bin="${TEST_TEMP_DIR}/bin"
	local explicit="${TEST_TEMP_DIR}/explicit/node"
	link_core_utils "$bin"
	write_fake_node "${bin}/node" "v20.18.2" "effective"
	write_fake_node "$explicit" "v24.15.0" "explicit"

	run run_runtime_probe "$bin" DOTFILES_MANAGED_NODE_BIN="$explicit"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"managed=${explicit}|v24.15.0|1|"* ]]

	run run_runtime_probe "$bin" DOTFILES_MANAGED_NODE_BIN="${TEST_TEMP_DIR}/missing-node"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"managed=${TEST_TEMP_DIR}/missing-node||0|managed candidate does not exist"* ]]
}

@test "DOTFILES_NODE_MIN_MAJOR is respected" {
	local bin="${TEST_TEMP_DIR}/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	link_core_utils "$bin"
	write_fake_node "${bin}/node" "v24.15.0" "effective"
	write_fake_node "$managed" "v24.15.0" "managed"

	run run_runtime_probe "$bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_NODE_MIN_MAJOR=25
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"effective=${bin}/node|v24.15.0|0|unknown-shadowing"* ]]
	[[ "$output" == *"managed=${managed}|v24.15.0|0|managed candidate v24.15.0 is below required >=25"* ]]
}

@test "overlay symlink pins node and user-space npm corepack pnpm run under managed Node" {
	local original_bin="${TEST_TEMP_DIR}/shadow/bin"
	local prefix="${TEST_TEMP_DIR}/npm-prefix"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local trace="${TEST_TEMP_DIR}/node-trace.log"
	link_core_utils "$original_bin"
	write_fake_node "${original_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v24.15.0" "managed"
	write_node_tool_shims "${prefix}/bin"

	run env PATH="$original_bin" DOTFILES_MANAGED_NODE_BIN="$managed" NODE_RUNTIME_TRACE="$trace" bash -c "source '${NODE_RUNTIME_LIB}'; overlay=\$(node_runtime_create_overlay '${TEST_TEMP_DIR}/run' '${managed}'); test \"\$(readlink \"\$overlay/node\")\" = '${managed}'; export PATH=\"\$(node_runtime_controlled_path \"\$overlay\" '${prefix}' \"\$PATH\")\"; test \"\$(command -v node)\" = \"\$overlay/node\"; test \"\$(node --version)\" = 'v24.15.0'; npm --version; corepack --version; pnpm --version; fake-cli"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"11.12.1"* ]]
	[[ "$output" == *"0.35.0"* ]]
	[[ "$output" == *"11.3.0"* ]]
	[[ "$output" == *"managed"* ]]
	grep -q 'managed:.*/npm' "$trace"
	grep -q 'managed:.*/corepack' "$trace"
	grep -q 'managed:.*/pnpm' "$trace"
	grep -q 'managed:.*/fake-cli' "$trace"
}

@test "controlled block can restore caller PATH and does not touch persistent config" {
	local original_bin="${TEST_TEMP_DIR}/shadow/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local fake_home="${TEST_TEMP_DIR}/home"
	link_core_utils "$original_bin"
	write_fake_node "${original_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v24.15.0" "managed"
	mkdir -p "$fake_home/.cursor"
	printf 'zshrc-original\n' >"${fake_home}/.zshrc"
	printf 'profile-original\n' >"${fake_home}/.profile"
	printf '{}\n' >"${fake_home}/.cursor/mcp.json"

	run env HOME="$fake_home" PATH="$original_bin" DOTFILES_MANAGED_NODE_BIN="$managed" bash -c "source '${NODE_RUNTIME_LIB}'; before=\"\$PATH\"; overlay=\$(node_runtime_create_overlay '${TEST_TEMP_DIR}/run' '${managed}'); PATH=\"\$(node_runtime_controlled_path \"\$overlay\" '${fake_home}/.npm-global' \"\$PATH\")\"; node --version >/dev/null; PATH=\"\$before\"; test \"\$PATH\" = \"\$before\""
	[[ "$status" -eq 0 ]]
	[[ "$(<"${fake_home}/.zshrc")" == "zshrc-original" ]]
	[[ "$(<"${fake_home}/.profile")" == "profile-original" ]]
	[[ "$(<"${fake_home}/.cursor/mcp.json")" == "{}" ]]
}

@test "update tools recovers once with managed runtime and no Node incident" {
	local shadow_bin="${TEST_TEMP_DIR}/home/.cursor-server/bin/hash"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local run_dir="${TEST_TEMP_DIR}/run-update-tools"
	link_core_utils "$shadow_bin"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "cursor"
	write_fake_node "$managed" "v24.15.0" "managed"

	run env HOME="${TEST_TEMP_DIR}/home" PATH="$shadow_bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_RUN_DIR="$run_dir" bash "$UPDATE_WSL" --section tools
	[[ "$status" -eq 0 ]]
	[[ "$(grep -c $'INFO\tWSL\tNode runtime for managed tools\t' "${run_dir}/wsl-results.tsv")" -eq 1 ]]
	assert_file_not_contains "${run_dir}/wsl-results.tsv" $'FAIL\tWSL\tNode\t'
	grep -q $'Node.js managed tools\tv24.15.0\tv24.15.0\tunchanged' "${run_dir}/tool-snapshot.tsv"
	assert_find_no_results "node runtime overlay cleanup after managed tools recovery" "$run_dir" -maxdepth 1 -type d -name 'node-runtime.*'
}

@test "overlay is cleaned when managed tools block fails after activation" {
	local shadow_bin="${TEST_TEMP_DIR}/shadow/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local run_dir="${TEST_TEMP_DIR}/run-overlay-fail"
	link_core_utils "$shadow_bin"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v24.15.0" "managed"
	mkdir -p "${TEST_TEMP_DIR}/home/.npm-global/bin"
	cat >"${TEST_TEMP_DIR}/home/.npm-global/bin/npm" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
	chmod +x "${TEST_TEMP_DIR}/home/.npm-global/bin/npm"

	run env HOME="${TEST_TEMP_DIR}/home" PATH="$shadow_bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_UPDATE_RUN_DIR="$run_dir" bash "$UPDATE_WSL" --section tools
	[[ "$status" -eq 0 ]]
	grep -q $'INFO\tWSL\tNode runtime for managed tools\t' "${run_dir}/wsl-results.tsv"
	grep -q $'FAIL\tWSL\t' "${run_dir}/wsl-results.tsv"
	assert_find_no_results "node runtime overlay cleanup after managed tools failure" "$run_dir" -maxdepth 1 -type d -name 'node-runtime.*'
}

@test "update tools with no compatible runtime records one Node diagnostic and skips npm family" {
	local shadow_bin="${TEST_TEMP_DIR}/agent/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local run_dir="${TEST_TEMP_DIR}/run-no-node"
	link_core_utils "$shadow_bin"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v20.18.2" "managed"

	run env HOME="${TEST_TEMP_DIR}/home" PATH="$shadow_bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_UPDATE_RUN_DIR="$run_dir" bash "$UPDATE_WSL" --section tools
	[[ "$status" -eq 0 ]]
	[[ "$(grep -c $'FAIL\tWSL\tNode\t' "${run_dir}/wsl-results.tsv")" -eq 1 ]]
	assert_file_not_matches "${run_dir}/wsl-results.tsv" $'\tWSL\t(npm|Corepack|pnpm)'
}

@test "pnpm major 11 flow runs under overlay with clean semver snapshot and separate method" {
	local shadow_bin="${TEST_TEMP_DIR}/shadow/bin"
	local prefix="${TEST_TEMP_DIR}/npm-prefix"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local run_dir="${TEST_TEMP_DIR}/run-pnpm-overlay"
	local script="${TEST_TEMP_DIR}/pnpm-overlay.sh"
	link_core_utils "$shadow_bin"
	write_fake_node "${shadow_bin}/node" "v20.18.2" "shadow"
	write_fake_node "$managed" "v24.15.0" "managed"
	mkdir -p "${prefix}/bin"
	cat >"${prefix}/bin/pnpm" <<'EOF'
#!/usr/bin/env node
// existing broken/old shim; fake node returns pnpm 11 in this test.
EOF
	chmod +x "${prefix}/bin/pnpm"
	cat >"${prefix}/bin/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prefix=""
for arg in "$@"; do
  case "$arg" in --prefix=*) prefix="${arg#--prefix=}";; esac
done
case "${1:-}" in
  --version) echo "11.12.1"; exit 0 ;;
  config) echo "${prefix:-/usr/local}"; exit 0 ;;
  install)
    mkdir -p "${prefix}/bin"
    cat >"${prefix}/bin/corepack" <<'COREPACK'
#!/usr/bin/env bash
set -euo pipefail
dir="$(dirname "$0")"
prev=""
for arg in "$@"; do
  if [[ "$prev" == "--install-directory" ]]; then dir="$arg"; fi
  prev="$arg"
done
mkdir -p "$dir"
cat >"${dir}/pnpm" <<'PNPM'
#!/usr/bin/env node
// fake pnpm 11
PNPM
chmod +x "${dir}/pnpm"
exit 0
COREPACK
    chmod +x "${prefix}/bin/corepack"
    exit 0
    ;;
esac
exit 0
EOF
	chmod +x "${prefix}/bin/npm"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
DOTFILES_UPDATE_RUN_DIR="${run_dir}"
TOOL_SNAPSHOT_FILE="${run_dir}/tool-snapshot.tsv"
source "${UPDATE_WSL}"
overlay="\$(node_runtime_create_overlay "${run_dir}" "${managed}")"
export PATH="\$(node_runtime_controlled_path "\$overlay" "${prefix}" "${shadow_bin}")"
export DOTFILES_NPM_PREFIX="${prefix}"
update_pnpm_major_11
EOF
	chmod +x "$script"

	run env PATH="$shadow_bin" bash "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'pnpm\t11.3.0\t11.3.0\tunchanged' "${run_dir}/tool-snapshot.tsv"
	grep -q $'INFO\tWSL\tpnpm method\tcorepack' "${run_dir}/wsl-results.tsv"
}

@test "npm prefix probing runs under managed overlay, not contaminated Node" {
	local shadow_bin="${TEST_TEMP_DIR}/shadow-prefix/bin"
	local prefix="${TEST_TEMP_DIR}/npm-prefix-probe"
	local managed="${TEST_TEMP_DIR}/managed-prefix/node"
	local run_dir="${TEST_TEMP_DIR}/run-prefix-probe"
	local trace="${TEST_TEMP_DIR}/prefix-trace.log"
	link_core_utils "$shadow_bin"
	mkdir -p "$(dirname "$managed")" "${prefix}/bin"
	cat >"${shadow_bin}/node" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  echo "v20.18.2"
  exit 0
fi
echo "shadow-node-ran:${1:-}" >> "${NODE_RUNTIME_TRACE}"
exit 88
EOF
	chmod +x "${shadow_bin}/node"
	cat >"$managed" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  echo "v24.15.0"
  exit 0
fi
echo "managed-node-ran:\${1:-}" >> "\${NODE_RUNTIME_TRACE}"
if [[ "\$(basename "\${1:-}")" == "npm" && "\${2:-}" == "config" && "\${3:-}" == "get" && "\${4:-}" == "prefix" ]]; then
  echo "${prefix}"
  exit 0
fi
exit 0
EOF
	chmod +x "$managed"
	cat >"${prefix}/bin/npm" <<'EOF'
#!/usr/bin/env node
// fake npm; handled by fake managed node.
EOF
	chmod +x "${prefix}/bin/npm"

	run env PATH="$shadow_bin" NODE_RUNTIME_TRACE="$trace" DOTFILES_MANAGED_NODE_BIN="$managed" bash -c "set -euo pipefail; set -- --section none; DOTFILES_UPDATE_RUN_DIR='${run_dir}'; source '${UPDATE_WSL}'; overlay=\$(node_runtime_create_overlay '${run_dir}' '${managed}'); export PATH=\"\$(node_runtime_controlled_path \"\$overlay\" '${prefix}' '${shadow_bin}')\"; unset NPM_CONFIG_PREFIX DOTFILES_NPM_PREFIX; test \"\$(user_npm_prefix)\" = '${prefix}'; node_runtime_cleanup_overlay \"\$overlay\""
	[[ "$status" -eq 0 ]]
	grep -q 'managed-node-ran:.*/npm' "$trace"
	assert_file_not_contains "$trace" 'shadow-node-ran'
	assert_find_no_results "node runtime overlay cleanup after npm prefix probing" "$run_dir" -maxdepth 1 -type d -name 'node-runtime.*'
}

@test "update-check reports compatible, recoverable, and unrecoverable Node states without overlay" {
	local bin="${TEST_TEMP_DIR}/bin"
	local managed="${TEST_TEMP_DIR}/managed/node"
	local run_dir="${TEST_TEMP_DIR}/check-run"
	link_core_utils "$bin"
	ln -sf "$(command -v python3)" "${bin}/python3"
	write_fake_node "${bin}/node" "v24.15.0" "effective"
	write_fake_node "$managed" "v24.15.0" "managed"

	run env HOME="${TEST_TEMP_DIR}/home" PATH="$bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_UPDATE_ROOT="$run_dir" bash "$UPDATE_CHECK"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"OK     Node.js effective runtime: v24.15.0 (${bin}/node)"* ]]
	assert_find_output_not_matches "update-check must not create node-runtime overlay symlink" 'node-runtime' "$TEST_TEMP_DIR" -type l -name node

	write_fake_node "${bin}/node" "v20.18.2" "effective"
	run env HOME="${TEST_TEMP_DIR}/home" PATH="$bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_UPDATE_ROOT="$run_dir" bash "$UPDATE_CHECK"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"WARN   Node.js effective runtime is below required >=22: v20.18.2 (${bin}/node, unknown-shadowing)"* ]]
	[[ "$output" == *"INFO   Managed compatible runtime available for update tools: v24.15.0 (${managed})"* ]]

	write_fake_node "$managed" "v20.18.2" "managed"
	run env HOME="${TEST_TEMP_DIR}/home" PATH="$bin" DOTFILES_MANAGED_NODE_BIN="$managed" DOTFILES_UPDATE_ROOT="$run_dir" bash "$UPDATE_CHECK"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"FAIL   Node.js effective runtime is below required >=22 and no compatible managed runtime is available"* ]]
	assert_find_no_results "update-check must not create node-runtime overlay paths" "$TEST_TEMP_DIR" -path '*node-runtime*'
}
