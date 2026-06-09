#!/usr/bin/env bats

load '../helpers/common'

setup() {
	DOTFILES_DIR="$(get_dotfiles_dir)"
	INSTALL_GITNEXUS="${DOTFILES_DIR}/scripts/install-gitnexus.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

write_fake_gitnexus_package() {
	local package_dir="$1"
	local log_file="$2"
	local script
	mkdir -p "${package_dir}/scripts"
	cat >"${package_dir}/package.json" <<'PKG'
{
  "name": "gitnexus",
  "version": "1.6.6",
  "scripts": {
    "postinstall": "node scripts/materialize-vendor-grammars.cjs && node scripts/build-tree-sitter-dart.cjs && node scripts/build-tree-sitter-proto.cjs && node scripts/build-tree-sitter-swift.cjs"
  }
}
PKG
	for script in \
		materialize-vendor-grammars.cjs \
		build-tree-sitter-dart.cjs \
		build-tree-sitter-proto.cjs \
		build-tree-sitter-swift.cjs; do
		cat >"${package_dir}/scripts/${script}" <<EOF
#!/usr/bin/env node
const fs = require('fs');
fs.appendFileSync('${log_file}', '${script}\\n');
EOF
	done
}

@test "install-gitnexus runs GitNexus grammar postinstall scripts" {
	local fake_home="${TEST_TEMP_DIR}/home"
	local stub_dir="${TEST_TEMP_DIR}/bin"
	local npm_prefix="${fake_home}/.npm-global"
	local args_log="${TEST_TEMP_DIR}/gitnexus-install-args.log"
	local postinstall_log="${TEST_TEMP_DIR}/gitnexus-postinstall.log"
	local real_node
	real_node="$(command -v node)"
	mkdir -p "$stub_dir" "$fake_home"

	cat >"${stub_dir}/node" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "--version" ]]; then
  echo "v24.15.0"
  exit 0
fi
exec "${real_node}" "\$@"
EOF
cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
case "\$1" in
  root)
    echo "${npm_prefix}/lib/node_modules"
    exit 0
    ;;
  --version)
    echo "11.16.0"
    exit 0
    ;;
  install)
    printf '%s\n' "\$*" >"${args_log}"
    mkdir -p "${npm_prefix}/lib/node_modules/gitnexus/scripts"
    exit 0
    ;;
esac
exit 0
EOF
	write_fake_gitnexus_package "${npm_prefix}/lib/node_modules/gitnexus" "$postinstall_log"
	cat >"${stub_dir}/gitnexus" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "gitnexus 1.6.6";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus"

	run env -u NPM_CONFIG_PREFIX -u DOTFILES_NPM_PREFIX \
		HOME="$fake_home" \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "$INSTALL_GITNEXUS"
	[[ "$status" -eq 0 ]]
	grep -q -- "install -g --prefix=${npm_prefix} gitnexus@latest" "$args_log"
	grep -q '^materialize-vendor-grammars.cjs$' "$postinstall_log"
	grep -q '^build-tree-sitter-dart.cjs$' "$postinstall_log"
	grep -q '^build-tree-sitter-proto.cjs$' "$postinstall_log"
	grep -q '^build-tree-sitter-swift.cjs$' "$postinstall_log"
}

@test "install-gitnexus preserves DOTFILES_NPM_PREFIX and version" {
	local fake_home="${TEST_TEMP_DIR}/home-override"
	local stub_dir="${TEST_TEMP_DIR}/bin-override"
	local npm_prefix="${TEST_TEMP_DIR}/custom-npm"
	local args_log="${TEST_TEMP_DIR}/gitnexus-install-args-override.log"
	local postinstall_log="${TEST_TEMP_DIR}/gitnexus-postinstall-override.log"
	local real_node
	real_node="$(command -v node)"
	mkdir -p "$stub_dir" "$fake_home"

	cat >"${stub_dir}/node" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "--version" ]]; then
  echo "v24.15.0"
  exit 0
fi
exec "${real_node}" "\$@"
EOF
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
case "\$1" in
  root)
    echo "${npm_prefix}/lib/node_modules"
    exit 0
    ;;
  --version)
    echo "11.16.0"
    exit 0
    ;;
  install)
    printf '%s\n' "\$*" >"${args_log}"
    exit 0
    ;;
esac
exit 0
EOF
	write_fake_gitnexus_package "${npm_prefix}/lib/node_modules/gitnexus" "$postinstall_log"
	cat >"${stub_dir}/gitnexus" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "gitnexus 1.6.5";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus"

	run env -u NPM_CONFIG_PREFIX \
		HOME="$fake_home" \
		DOTFILES_NPM_PREFIX="$npm_prefix" \
		GITNEXUS_VERSION=1.6.6 \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "$INSTALL_GITNEXUS"

	[[ "$status" -eq 0 ]]
	grep -q -- "install -g --prefix=${npm_prefix} gitnexus@1.6.6" "$args_log"
	grep -q '^build-tree-sitter-dart.cjs$' "$postinstall_log"
}

@test "install-gitnexus fails clearly when npm ignore-scripts is enabled" {
	local fake_home="${TEST_TEMP_DIR}/home-ignore"
	local stub_dir="${TEST_TEMP_DIR}/bin-ignore"
	mkdir -p "$stub_dir" "$fake_home"

	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v24.15.0";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version) echo "11.16.0"; exit 0 ;;
  config) echo "true"; exit 0 ;;
  install) echo "install should not run" >&2; exit 91 ;;
esac
exit 0
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm"

	run env -u NPM_CONFIG_PREFIX -u DOTFILES_NPM_PREFIX \
		HOME="$fake_home" \
		NPM_CONFIG_IGNORE_SCRIPTS=true \
		PATH="${stub_dir}:/usr/bin:/bin" \
		bash "$INSTALL_GITNEXUS"

	[[ "$status" -eq 1 ]]
	[[ "$output" == *"ignore-scripts"* ]]
	[[ "$output" == *"GitNexus necesita ejecutar postinstall"* ]]
	[[ "$output" != *"install should not run"* ]]
}
