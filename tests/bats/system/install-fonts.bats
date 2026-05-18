#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_FONTS="${DOTFILES_DIR}/scripts/install-fonts.sh"
	INSTALL_VERIFY="${DOTFILES_DIR}/scripts/install-verify.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

make_stub_bin() {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	ln -s "$(command -v dirname)" "${stub_dir}/dirname"
	printf '%s\n' "${stub_dir}"
}

write_version_stub() {
	local stub_dir="$1"
	local cmd="$2"
	local version="$3"
	cat >"${stub_dir}/${cmd}" <<EOF
#!/usr/bin/env bash
case "\${1:-}" in
	--version) echo "${version}" ;;
	*) echo "${cmd} stub" ;;
esac
EOF
	chmod +x "${stub_dir}/${cmd}"
}

write_fontconfig_stubs() {
	local stub_dir="$1"
	local mode="$2"

	case "${mode}" in
	available)
		cat >"${stub_dir}/fc-match" <<'EOF'
#!/usr/bin/env bash
echo "MesloLGS NF Regular.ttf: MesloLGS NF:style=Regular"
EOF
		cat >"${stub_dir}/fc-list" <<'EOF'
#!/usr/bin/env bash
echo "/tmp/MesloLGS NF Regular.ttf: MesloLGS NF:style=Regular"
EOF
		;;
	missing)
		cat >"${stub_dir}/fc-match" <<'EOF'
#!/usr/bin/env bash
echo "DejaVuSans.ttf: DejaVu Sans:style=Book"
EOF
		cat >"${stub_dir}/fc-list" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
		;;
	after-cache)
		cat >"${stub_dir}/fc-match" <<'EOF'
#!/usr/bin/env bash
if [[ -f "${TEST_TEMP_DIR}/cache_ran" ]]; then
	echo "MesloLGS NF Regular.ttf: MesloLGS NF:style=Regular"
else
	echo "DejaVuSans.ttf: DejaVu Sans:style=Book"
fi
EOF
		cat >"${stub_dir}/fc-list" <<'EOF'
#!/usr/bin/env bash
if [[ -f "${TEST_TEMP_DIR}/cache_ran" ]]; then
	echo "${XDG_DATA_HOME}/fonts/MesloLGS/MesloLGS NF Regular.ttf: MesloLGS NF:style=Regular"
fi
EOF
		;;
	esac

	cat >"${stub_dir}/fc-cache" <<'EOF'
#!/usr/bin/env bash
echo "fc-cache $*" >>"${TEST_TEMP_DIR}/calls.log"
touch "${TEST_TEMP_DIR}/cache_ran"
EOF
	chmod +x "${stub_dir}/fc-match" "${stub_dir}/fc-list" "${stub_dir}/fc-cache"
}

@test "install-fonts DRY_RUN does not call curl or fc-cache" {
	local stub_dir
	stub_dir="$(make_stub_bin)"
	write_fontconfig_stubs "${stub_dir}" "missing"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl should not run" >>"${TEST_TEMP_DIR}/calls.log"
exit 99
EOF
	chmod +x "${stub_dir}/curl"

	run env DRY_RUN=1 XDG_DATA_HOME="${TEST_TEMP_DIR}/data" PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_FONTS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"Plan:"* ]]
	[[ ! -e "${TEST_TEMP_DIR}/data" ]]
	[[ ! -e "${TEST_TEMP_DIR}/calls.log" ]]
}

@test "install-fonts skips downloads when MesloLGS NF is already available" {
	local stub_dir
	stub_dir="$(make_stub_bin)"
	write_fontconfig_stubs "${stub_dir}" "available"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl should not run" >>"${TEST_TEMP_DIR}/calls.log"
exit 99
EOF
	chmod +x "${stub_dir}/curl"

	run env XDG_DATA_HOME="${TEST_TEMP_DIR}/data" PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_FONTS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MesloLGS NF available"* ]]
	[[ "${output}" == *"No download needed"* ]]
	[[ ! -e "${TEST_TEMP_DIR}/calls.log" ]]
}

@test "install-fonts downloads only missing font files with curl stub" {
	local stub_dir font_dir
	stub_dir="$(make_stub_bin)"
	font_dir="${TEST_TEMP_DIR}/data/fonts/MesloLGS"
	mkdir -p "${font_dir}"
	printf 'existing font\n' >"${font_dir}/MesloLGS NF Regular.ttf"
	write_fontconfig_stubs "${stub_dir}" "after-cache"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
out=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		-o) out="$2"; shift 2 ;;
		*) shift ;;
	esac
done
if [[ -z "${out}" ]]; then
	exit 2
fi
echo "downloaded font" >"${out}"
echo "curl ${out}" >>"${TEST_TEMP_DIR}/calls.log"
EOF
	chmod +x "${stub_dir}/curl"

	run env XDG_DATA_HOME="${TEST_TEMP_DIR}/data" PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_FONTS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MesloLGS NF Bold.ttf"* ]]
	[[ "${output}" == *"MesloLGS NF Italic.ttf"* ]]
	[[ "${output}" == *"MesloLGS NF Bold Italic.ttf"* ]]
	[[ "${output}" == *"MesloLGS NF Regular.ttf already present"* ]]
	[[ -s "${font_dir}/MesloLGS NF Regular.ttf" ]]
	[[ -s "${font_dir}/MesloLGS NF Bold.ttf" ]]
	[[ -s "${font_dir}/MesloLGS NF Italic.ttf" ]]
	[[ -s "${font_dir}/MesloLGS NF Bold Italic.ttf" ]]
	run find "${font_dir}" -name '*.tmp.*' -print
	[[ "${status}" -eq 0 ]]
	[[ -z "${output}" ]]
	run grep -c '^curl ' "${TEST_TEMP_DIR}/calls.log"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" -eq 3 ]]
	run grep -F "fc-cache -fv ${font_dir}" "${TEST_TEMP_DIR}/calls.log"
	[[ "${status}" -eq 0 ]]
}

@test "install-fonts fails clearly when curl fails" {
	local stub_dir
	stub_dir="$(make_stub_bin)"
	write_fontconfig_stubs "${stub_dir}" "missing"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
exit 22
EOF
	chmod +x "${stub_dir}/curl"

	run env XDG_DATA_HOME="${TEST_TEMP_DIR}/data" PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_FONTS}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Failed to download"* ]]
}

@test "install-fonts target exists and is outside install aggregator" {
	run grep -E "^install-fonts:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-fonts"* ]]
}

@test "install-verify emits WARN when MesloLGS NF is absent" {
	local stub_dir
	stub_dir="$(make_stub_bin)"
	for cmd in zsh git age rg; do
		write_version_stub "${stub_dir}" "${cmd}" "${cmd} 1.0"
	done
	write_fontconfig_stubs "${stub_dir}" "missing"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_VERIFY}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"WARN"* ]]
	[[ "${output}" == *"MesloLGS NF not available"* ]]
	[[ "${output}" == *"make install-fonts"* ]]
}

@test "install-verify emits PASS when MesloLGS NF is available" {
	local stub_dir
	stub_dir="$(make_stub_bin)"
	for cmd in zsh git age rg; do
		write_version_stub "${stub_dir}" "${cmd}" "${cmd} 1.0"
	done
	write_fontconfig_stubs "${stub_dir}" "available"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_VERIFY}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"PASS"* ]]
	[[ "${output}" == *"MesloLGS NF available"* ]]
}

@test "common APT inventory declares fontconfig" {
	run grep -A4 "package: fontconfig" "${DOTFILES_DIR}/system/packages/common.yaml"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"command: fc-match"* ]]
	[[ "${output}" == *"fc-cache"* ]]
}
