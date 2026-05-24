#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

make_release_curl_stub() {
	local dir="$1" api_json="$2" asset_file="${3:-}" checksum_file="${4:-}" log_file="$5"
	cat >"${dir}/curl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"${log_file}"
out=""
url=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -o)
      out="\$2"
      shift 2
      ;;
    http*)
      url="\$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
case "\$url" in
  *api.github.com*)
    cat "${api_json}"
    ;;
  *checksums*|*SHA256SUMS*)
    cp "${checksum_file}" "\$out"
    ;;
  *download*)
    cp "${asset_file}" "\$out"
    ;;
  *)
    exit 1
    ;;
esac
EOF
	chmod +x "${dir}/curl"
}

@test "install-agent-tools skips actionlint downloads when already latest under upgrade" {
	local fake_home="${TEST_TEMP_DIR}/home-actionlint-same"
	local stub_dir="${TEST_TEMP_DIR}/bin-actionlint-same"
	local target_dir="${fake_home}/.local/bin"
	local curl_log="${TEST_TEMP_DIR}/curl-actionlint-same.log"
	mkdir -p "$stub_dir" "$target_dir"
	cat >"${target_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	chmod +x "${target_dir}/osv-scanner"
	cat >"${stub_dir}/curl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"${curl_log}"
url=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    http*)
      url="\$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
case "\$url" in
  *rhysd/actionlint*)
    cat "${TEST_TEMP_DIR}/actionlint-latest.json"
    ;;
  *google/osv-scanner*)
    printf '{"tag_name":"v2.3.8"}\n'
    ;;
  *)
    exit 1
    ;;
esac
EOF
	chmod +x "${target_dir}/actionlint"
	cat >"${TEST_TEMP_DIR}/actionlint-latest.json" <<'EOF'
{"tag_name":"v1.7.12"}
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"OK     actionlint already latest: 1.7.12"* ]]
	[[ "$output" != *"installed at ${target_dir}/actionlint"* ]]
	grep -q 'api.github.com/repos/rhysd/actionlint/releases/latest' "$curl_log"
	run grep -q 'releases/download' "$curl_log"
	[[ "$status" -ne 0 ]]
}

@test "install-agent-tools updates actionlint only after remote precheck and keeps checksum validation" {
	local fake_home="${TEST_TEMP_DIR}/home-actionlint-update"
	local stub_dir="${TEST_TEMP_DIR}/bin-actionlint-update"
	local target_dir="${fake_home}/.local/bin"
	local curl_log="${TEST_TEMP_DIR}/curl-actionlint-update.log"
	local asset_dir="${TEST_TEMP_DIR}/actionlint-asset"
	local asset_tar="${TEST_TEMP_DIR}/actionlint_1.7.12_linux_amd64.tar.gz"
	local checksums="${TEST_TEMP_DIR}/actionlint_1.7.12_checksums.txt"
	mkdir -p "$stub_dir" "$target_dir" "$asset_dir"
	cat >"${target_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.11"
EOF
	chmod +x "${target_dir}/actionlint"
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	chmod +x "${target_dir}/osv-scanner"
	cat >"${asset_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	chmod +x "${asset_dir}/actionlint"
	tar -czf "$asset_tar" -C "$asset_dir" actionlint
	(
		cd "${TEST_TEMP_DIR}" &&
			sha256sum "$(basename "$asset_tar")" >"$(basename "$checksums")"
	)
	cat >"${TEST_TEMP_DIR}/actionlint-update.json" <<'EOF'
{"tag_name":"v1.7.12"}
EOF
	cat >"${stub_dir}/curl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"${curl_log}"
out=""
url=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -o)
      out="\$2"
      shift 2
      ;;
    http*)
      url="\$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
case "\$url" in
  *api.github.com/repos/rhysd/actionlint/releases/latest)
    cat "${TEST_TEMP_DIR}/actionlint-update.json"
    ;;
  *api.github.com/repos/google/osv-scanner/releases/latest)
    printf '{"tag_name":"v2.3.8"}\n'
    ;;
  *actionlint_1.7.12_linux_amd64.tar.gz)
    cp "${asset_tar}" "\$out"
    ;;
  *actionlint_1.7.12_checksums.txt)
    cp "${checksums}" "\$out"
    ;;
  *)
    exit 1
    ;;
esac
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"INFO   actionlint update available: 1.7.11 -> 1.7.12"* ]]
	[[ "$output" == *"OK     actionlint v1.7.12 installed at ${target_dir}/actionlint"* ]]
	run env PATH="${target_dir}:/usr/bin:/bin" actionlint --version
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"1.7.12"* ]]
	grep -q 'actionlint_1.7.12_linux_amd64.tar.gz' "$curl_log"
	grep -q 'actionlint_1.7.12_checksums.txt' "$curl_log"
}

@test "install-agent-tools installs actionlint when missing and precheck succeeds" {
	local fake_home="${TEST_TEMP_DIR}/home-actionlint-missing"
	local stub_dir="${TEST_TEMP_DIR}/bin-actionlint-missing"
	local target_dir="${fake_home}/.local/bin"
	local curl_log="${TEST_TEMP_DIR}/curl-actionlint-missing.log"
	local asset_dir="${TEST_TEMP_DIR}/actionlint-missing-asset"
	local asset_tar="${TEST_TEMP_DIR}/actionlint_1.7.12_linux_amd64.tar.gz"
	local checksums="${TEST_TEMP_DIR}/actionlint_1.7.12_checksums.txt"
	mkdir -p "$stub_dir" "$target_dir" "$asset_dir"
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	chmod +x "${target_dir}/osv-scanner"
	cat >"${asset_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	chmod +x "${asset_dir}/actionlint"
	tar -czf "$asset_tar" -C "$asset_dir" actionlint
	(
		cd "${TEST_TEMP_DIR}" &&
			sha256sum "$(basename "$asset_tar")" >"$(basename "$checksums")"
	)
	cat >"${TEST_TEMP_DIR}/actionlint-missing.json" <<'EOF'
{"tag_name":"v1.7.12"}
EOF
	cat >"${stub_dir}/curl" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"${curl_log}"
out=""
url=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -o)
      out="\$2"
      shift 2
      ;;
    http*)
      url="\$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done
case "\$url" in
  *api.github.com/repos/rhysd/actionlint/releases/latest)
    cat "${TEST_TEMP_DIR}/actionlint-missing.json"
    ;;
  *api.github.com/repos/google/osv-scanner/releases/latest)
    printf '{"tag_name":"v2.3.8"}\n'
    ;;
  *actionlint_1.7.12_linux_amd64.tar.gz)
    cp "${asset_tar}" "\$out"
    ;;
  *actionlint_1.7.12_checksums.txt)
    cp "${checksums}" "\$out"
    ;;
  *)
    exit 1
    ;;
esac
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"INFO   actionlint is not installed; installing latest available version 1.7.12"* ]]
	[[ "$output" == *"OK     actionlint v1.7.12 installed at ${target_dir}/actionlint"* ]]
	run env PATH="${target_dir}:/usr/bin:/bin" actionlint --version
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"1.7.12"* ]]
}

@test "install-agent-tools fails when actionlint is missing and latest release lookup fails" {
	local fake_home="${TEST_TEMP_DIR}/home-actionlint-fail"
	local stub_dir="${TEST_TEMP_DIR}/bin-actionlint-fail"
	mkdir -p "$stub_dir" "${fake_home}/.local/bin"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${fake_home}/.local/bin:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade
	[[ "$status" -ne 0 ]]
	[[ "$output" == *"FAIL   Could not resolve latest actionlint release"* ]]
}

@test "install-agent-tools records actionlint warning in result file when release lookup fails" {
	local fake_home="${TEST_TEMP_DIR}/home-actionlint-warn-result"
	local stub_dir="${TEST_TEMP_DIR}/bin-actionlint-warn-result"
	local target_dir="${fake_home}/.local/bin"
	local result_file="${TEST_TEMP_DIR}/actionlint-warn-results.tsv"
	local curl_log="${TEST_TEMP_DIR}/curl-actionlint-warn.log"
	mkdir -p "$stub_dir" "$target_dir"
	cat >"${target_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	chmod +x "${target_dir}/actionlint" "${target_dir}/osv-scanner"
	cat >"${stub_dir}/curl" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"${curl_log}"
case "\$*" in
  *rhysd/actionlint*) exit 1 ;;
  *google/osv-scanner*) printf '{"tag_name":"v2.3.8"}\n' ;;
  *) exit 1 ;;
esac
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade --result-file "$result_file"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"WARN   actionlint update check failed; keeping installed version 1.7.12"* ]]
	grep -q $'WARN\tactionlint\tupdate check failed; keeping installed version 1.7.12' "$result_file"
	run grep -q 'releases/download' "$curl_log"
	[[ "$status" -ne 0 ]]
	run grep -q $'WARN\tosv-scanner' "$result_file"
	[[ "$status" -ne 0 ]]
}

@test "install-agent-tools records osv-scanner warning in result file when release lookup fails" {
	local fake_home="${TEST_TEMP_DIR}/home-osv-warn-result"
	local stub_dir="${TEST_TEMP_DIR}/bin-osv-warn-result"
	local target_dir="${fake_home}/.local/bin"
	local result_file="${TEST_TEMP_DIR}/osv-warn-results.tsv"
	mkdir -p "$stub_dir" "$target_dir"
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	cat >"${target_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	chmod +x "${target_dir}/osv-scanner" "${target_dir}/actionlint"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *google/osv-scanner*) exit 1 ;;
  *rhysd/actionlint*) printf '{"tag_name":"v1.7.12"}\n' ;;
  *) exit 1 ;;
esac
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade --result-file "$result_file"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"WARN   osv-scanner update check failed; keeping installed version 2.3.8"* ]]
	grep -q $'WARN\tosv-scanner\tupdate check failed; keeping installed version 2.3.8' "$result_file"
	run grep -q $'WARN\tactionlint' "$result_file"
	[[ "$status" -ne 0 ]]
}

@test "install-agent-tools leaves result file empty when external tools are already latest" {
	local fake_home="${TEST_TEMP_DIR}/home-agent-tools-clean-result"
	local stub_dir="${TEST_TEMP_DIR}/bin-agent-tools-clean-result"
	local target_dir="${fake_home}/.local/bin"
	local result_file="${TEST_TEMP_DIR}/agent-tools-clean-results.tsv"
	local curl_log="${TEST_TEMP_DIR}/curl-agent-tools-clean.log"
	mkdir -p "$stub_dir" "$target_dir"
	cat >"${target_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	chmod +x "${target_dir}/actionlint" "${target_dir}/osv-scanner"
	cat >"${stub_dir}/curl" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"${curl_log}"
url=""
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    http*) url="\$1"; shift ;;
    *) shift ;;
  esac
done
case "\$url" in
  *rhysd/actionlint*) printf '{"tag_name":"v1.7.12"}\n' ;;
  *google/osv-scanner*) printf '{"tag_name":"v2.3.8"}\n' ;;
  *) exit 1 ;;
esac
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade --result-file "$result_file"
	[[ "$status" -eq 0 ]]
	[[ -f "$result_file" ]]
	[[ ! -s "$result_file" ]]
	run grep -q 'releases/download' "$curl_log"
	[[ "$status" -ne 0 ]]
}

@test "install-agent-tools warns and preserves osv-scanner when release lookup fails" {
	local fake_home="${TEST_TEMP_DIR}/home-osv-warn"
	local stub_dir="${TEST_TEMP_DIR}/bin-osv-warn"
	local target_dir="${fake_home}/.local/bin"
	mkdir -p "$stub_dir" "$target_dir"
	cat >"${target_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
echo "osv-scanner version: 2.3.8"
EOF
	cat >"${target_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
echo "actionlint 1.7.12"
EOF
	chmod +x "${target_dir}/osv-scanner" "${target_dir}/actionlint"
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
	chmod +x "${stub_dir}/curl"
	run env HOME="$fake_home" PATH="${stub_dir}:${target_dir}:/usr/bin:/bin" bash "${DOTFILES_DIR}/scripts/install-agent-tools.sh" --external-only --upgrade
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"WARN   actionlint update check failed; keeping installed version 1.7.12"* ]]
	[[ "$output" == *"WARN   osv-scanner update check failed; keeping installed version 2.3.8"* ]]
	run env PATH="${target_dir}:/usr/bin:/bin" osv-scanner --version
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"2.3.8"* ]]
}
