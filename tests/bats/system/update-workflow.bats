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

make_passthrough_node_stub() {
	local dir="$1" version="$2"
	local real_node
	real_node="$(command -v node)"
	cat >"${dir}/node" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "--version" ]]; then
  echo "${version}"
  exit 0
fi
exec "${real_node}" "\$@"
EOF
	chmod +x "${dir}/node"
}

write_global_npm_package() {
	local prefix="$1" package_name="$2" version="$3"
	local package_dir="${prefix}/lib/node_modules/${package_name}"
	mkdir -p "$package_dir"
	cat >"${package_dir}/package.json" <<EOF
{"name":"${package_name}","version":"${version}"}
EOF
}

write_pnpm_update_runner() {
	local script="$1" fake_home="$2" stub_dir="$3"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
	PATH="${stub_dir}"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-pnpm"
if [[ -z "\${PNPM_TEST_KEEP_PREFIX_ENV:-}" ]]; then
  unset NPM_CONFIG_PREFIX DOTFILES_NPM_PREFIX
fi
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_pnpm_major_11
tool_snapshot_print "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
EOF
	chmod +x "$script"
}

write_pnpm_fake_npm() {
	local stub_dir="$1"
	for cmd in bash mkdir cat chmod dirname date tee tr head sed grep rm mktemp awk; do
		ln -sf "$(command -v "$cmd")" "${stub_dir}/${cmd}"
	done
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prefix=""
for arg in "$@"; do
  case "$arg" in --prefix=*) prefix="${arg#--prefix=}";; esac
done
if [[ -z "$prefix" ]]; then
  prev=""
  for arg in "$@"; do
    if [[ "$prev" == "--prefix" ]]; then prefix="$arg"; break; fi
    prev="$arg"
  done
fi
case "${1:-}" in
  --version) echo "11.0.0"; exit 0 ;;
  config)
    if [[ "${2:-}" == "get" && "${3:-}" == "prefix" ]]; then
      echo "${PNPM_TEST_NPM_PREFIX_REPLY:-/usr/local}"
      exit 0
    fi
    ;;
  install)
    if [[ "$*" == *"corepack@latest"* ]]; then
      mkdir -p "${prefix}/bin"
      cat >"${prefix}/bin/corepack" <<'COREPACK'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "${PNPM_TEST_COREPACK_LOG}"
dir="$(dirname "$0")"
prev=""
for arg in "$@"; do
  if [[ "$prev" == "--install-directory" ]]; then dir="$arg"; fi
  prev="$arg"
done
mkdir -p "$dir"
if [[ "$*" == *"enable pnpm"* ]]; then
  printf '%s\n' "$dir" >"${PNPM_TEST_COREPACK_DIR_FILE}"
fi
if [[ "$*" == *"prepare pnpm@latest-11 --activate"* && -n "${PNPM_TEST_COREPACK_VERSION:-}" ]]; then
  dir="$(cat "${PNPM_TEST_COREPACK_DIR_FILE}" 2>/dev/null || dirname "$0")"
  cat >"${dir}/pnpm" <<PNPM
#!/usr/bin/env bash
case "\$1" in --version) echo "${PNPM_TEST_COREPACK_VERSION}";; *) exit 0;; esac
PNPM
  chmod +x "${dir}/pnpm"
fi
if [[ "$*" == *"prepare pnpm@latest-11 --activate"* && -n "${PNPM_TEST_COREPACK_BROKEN_SHIM:-}" ]]; then
  dir="$(cat "${PNPM_TEST_COREPACK_DIR_FILE}" 2>/dev/null || dirname "$0")"
  cat >"${dir}/pnpm" <<'PNPM'
#!/usr/bin/env bash
exit 42
PNPM
  chmod +x "${dir}/pnpm"
fi
exit "${PNPM_TEST_COREPACK_EXIT:-0}"
COREPACK
      chmod +x "${prefix}/bin/corepack"
      echo "installed corepack"
      exit "${PNPM_TEST_NPM_COREPACK_EXIT:-0}"
    fi
    if [[ "$*" == *"pnpm@^11"* ]]; then
      mkdir -p "${prefix}/bin"
      echo "$*" >> "${PNPM_TEST_FALLBACK_LOG}"
      if [[ -n "${PNPM_TEST_FALLBACK_VERSION:-}" ]]; then
        cat >"${prefix}/bin/pnpm" <<PNPM
#!/usr/bin/env bash
case "\$1" in --version) echo "${PNPM_TEST_FALLBACK_VERSION}";; *) exit 0;; esac
PNPM
        chmod +x "${prefix}/bin/pnpm"
      fi
      echo "installed pnpm fallback"
      exit "${PNPM_TEST_FALLBACK_EXIT:-0}"
    fi
    ;;
esac
exit 0
EOF
	chmod +x "${stub_dir}/npm"
}

write_update_check_fake_bin() {
	local stub_dir="$1" docker_mode="${2:-ok}"
	for cmd in bash python3 mktemp rm dirname pwd mkdir grep tee date tr chmod head sed make; do
		ln -sf "$(command -v "$cmd")" "${stub_dir}/${cmd}"
	done
	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v24.11.1";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/docker" <<EOF
#!/usr/bin/env bash
case "\$1" in
  version)
    [[ "${docker_mode}" == "down" ]] && exit 1
    exit 0
    ;;
  ps|port|inspect) exit 0 ;;
  pull|run) echo "unexpected mutation: docker \$*" >&2; exit 77 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/docker"
}

@test "run_step preserves real exit codes and logs stderr for missing commands" {
	local script="${TEST_TEMP_DIR}/run-step-check.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
result_init "${TEST_TEMP_DIR}/results.tsv"
run_step "Test" "Success" "${TEST_TEMP_DIR}/success.log" bash -c 'echo ok'
run_step "Test" "Exit 42" "${TEST_TEMP_DIR}/exit42.log" bash -c 'echo bad >&2; exit 42'
run_step "Test" "Missing command" "${TEST_TEMP_DIR}/missing.log" definitely-not-a-command
EOF
	chmod +x "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'OK\tTest\tSuccess\tcompleted' "${TEST_TEMP_DIR}/results.tsv"
	grep -q $'FAIL\tTest\tExit 42\texit 42' "${TEST_TEMP_DIR}/results.tsv"
	grep -q $'FAIL\tTest\tMissing command\texit 127' "${TEST_TEMP_DIR}/results.tsv"
	grep -q 'definitely-not-a-command' "${TEST_TEMP_DIR}/missing.log"
	[[ "$output" != *"failed with exit 0"* ]]
}

@test "run_step streams long command output before completion" {
	local script="${TEST_TEMP_DIR}/run-step-stream.sh"
	local stdout_file="${TEST_TEMP_DIR}/stdout.txt"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
result_init "${TEST_TEMP_DIR}/stream-results.tsv"
run_step "Test" "Slow step" "${TEST_TEMP_DIR}/slow.log" bash -c 'echo first-line; sleep 2; echo second-line; exit 7'
EOF
	chmod +x "$script"
	"$script" >"$stdout_file" 2>&1 &
	local pid=$!
	local saw_first=0
	for _ in 1 2 3 4 5 6 7 8 9 10; do
		if [[ -f "${TEST_TEMP_DIR}/slow.log" ]] && grep -q 'first-line' "${TEST_TEMP_DIR}/slow.log"; then
			saw_first=1
			break
		fi
		sleep 0.3
	done
	wait "$pid"
	[[ "$saw_first" -eq 1 ]]
	grep -q 'first-line' "$stdout_file"
	grep -q 'second-line' "$stdout_file"
	grep -q $'FAIL\tTest\tSlow step\texit 7' "${TEST_TEMP_DIR}/stream-results.tsv"
}

@test "run_npm_step reports npm warnings without failing usable tools" {
	local script="${TEST_TEMP_DIR}/npm-step-check.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
result_init "${TEST_TEMP_DIR}/npm-results.tsv"
run_npm_step "WSL" "npm clean" "${TEST_TEMP_DIR}/npm-clean.log" bash -c 'echo "changed 1 package"; echo "2 packages are looking for funding"'
run_npm_step "WSL" "npm warn tool" "${TEST_TEMP_DIR}/npm-warn.log" bash -c 'echo "npm warn deprecated boolean@3.2.0: Package no longer supported" >&2; echo changed'
run_npm_step "WSL" "npm carriage warn" "${TEST_TEMP_DIR}/npm-cr.log" bash -c 'printf "progress\rnpm WARN deprecated old-package: still visible\r\n" >&2'
run_npm_step "WSL" "npm fail tool" "${TEST_TEMP_DIR}/npm-fail.log" bash -c 'echo "npm warn before fail" >&2; exit 42'
EOF
	chmod +x "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'OK\tWSL\tnpm clean\tcompleted' "${TEST_TEMP_DIR}/npm-results.tsv"
	grep -q $'OK\tWSL\tnpm warn tool\tcompleted' "${TEST_TEMP_DIR}/npm-results.tsv"
	grep -q $'INFO\tWSL\tnpm warn tool npm warnings\tcompleted with npm warnings' "${TEST_TEMP_DIR}/npm-results.tsv"
	grep -q $'OK\tWSL\tnpm carriage warn\tcompleted' "${TEST_TEMP_DIR}/npm-results.tsv"
	grep -q $'INFO\tWSL\tnpm carriage warn npm warnings\tcompleted with npm warnings' "${TEST_TEMP_DIR}/npm-results.tsv"
	grep -q $'FAIL\tWSL\tnpm fail tool\texit 42' "${TEST_TEMP_DIR}/npm-results.tsv"
	run bash -c "source '${DOTFILES_DIR}/scripts/update/lib/results.sh'; result_has_incidents '${TEST_TEMP_DIR}/npm-results.tsv'"
	[[ "$status" -eq 0 ]]
	grep -q 'npm warn deprecated boolean@3.2.0: Package no longer supported' "${TEST_TEMP_DIR}/npm-warn.log"
	grep -q 'npm WARN deprecated old-package: still visible' "${TEST_TEMP_DIR}/npm-cr.log"
}

@test "npm warnings with exit 0 do not count as incidents by themselves" {
	local script="${TEST_TEMP_DIR}/npm-warning-only.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
result_init "${TEST_TEMP_DIR}/npm-warning-only.tsv"
run_npm_step "WSL" "GitNexus CLI" "${TEST_TEMP_DIR}/gitnexus.log" bash -c 'echo "npm warn deprecated boolean@3.2.0: Package no longer supported" >&2; exit 0'
if result_has_incidents "${TEST_TEMP_DIR}/npm-warning-only.tsv"; then
	exit 12
fi
EOF
	chmod +x "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'OK\tWSL\tGitNexus CLI\tcompleted' "${TEST_TEMP_DIR}/npm-warning-only.tsv"
	grep -q $'INFO\tWSL\tGitNexus CLI npm warnings\tcompleted with npm warnings' "${TEST_TEMP_DIR}/npm-warning-only.tsv"
}

@test "status formatting emits real ANSI and icons without literal escapes" {
	local script="${TEST_TEMP_DIR}/status-format.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
ok "color check"
skip "skip check"
warn "warn check"
EOF
	chmod +x "$script"
	run env -u NO_COLOR DOTFILES_UPDATE_FORCE_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *$'\033[0;32mOK'* ]]
	[[ "$output" == *$'\033[0m'* ]]
	[[ "$output" == *"✔"* ]]
	[[ "$output" == *"⏭"* ]]
	[[ "$output" == *"⚠"* ]]
	[[ "$output" != *"\\033"* ]]
	[[ "$output" != *"\\\\033"* ]]
}

@test "status formatting honors NO_COLOR and plain mode" {
	local script="${TEST_TEMP_DIR}/status-plain.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
ok "color check"
skip "skip check"
EOF
	chmod +x "$script"
	run env DOTFILES_UPDATE_FORCE_COLOR=1 NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *$'\033['* ]]
	[[ "$output" != *"\\033"* ]]
	[[ "$output" == *"OK    color check"* ]]
	[[ "$output" == *"SKIP  skip check"* ]]
	run env -u NO_COLOR DOTFILES_UPDATE_FORCE_COLOR=1 DOTFILES_UPDATE_PLAIN=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *$'\033['* ]]
	[[ "$output" == *"OK    color check"* ]]
}

@test "section headers render with ANSI and Unicode separators when color is forced" {
	local script="${TEST_TEMP_DIR}/section-format.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
section "APT"
section "Update summary"
EOF
	chmod +x "$script"
	run env -u NO_COLOR DOTFILES_UPDATE_FORCE_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *$'\033[0;36m'* ]]
	[[ "$output" == *"━━━"* ]]
	[[ "$output" == *"APT"* ]]
	[[ "$output" == *"Update summary"* ]]
	[[ "$output" != *"\\033"* ]]
	[[ "$output" != *"> APT"* ]]
	[[ "$output" != *"> Update summary"* ]]
}

@test "section headers honor plain mode with ASCII separators" {
	local script="${TEST_TEMP_DIR}/section-plain.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
source "${DOTFILES_DIR}/scripts/update/lib/logging.sh"
section "APT"
section "Update summary"
EOF
	chmod +x "$script"
	run env DOTFILES_UPDATE_FORCE_COLOR=1 NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *$'\033['* ]]
	[[ "$output" != *"\\033"* ]]
	[[ "$output" == *"=== APT ="* ]]
	[[ "$output" == *"=== Update summary ="* ]]
	[[ "$output" != *"━━━"* ]]
	[[ "$output" != *"> APT"* ]]

	run env -u NO_COLOR DOTFILES_UPDATE_FORCE_COLOR=1 DOTFILES_UPDATE_PLAIN=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *$'\033['* ]]
	[[ "$output" == *"=== APT ="* ]]
	[[ "$output" == *"=== Update summary ="* ]]
}

@test "result_has_incidents ignores SKIP and counts WARN" {
	local script="${TEST_TEMP_DIR}/incidents-check.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_init "${TEST_TEMP_DIR}/incidents.tsv"
result_skip "WSL" "Excalidraw Docker" "Docker Desktop is not running"
result_info "WSL" "Excalidraw Docker" "Run make excalidraw-update later"
if result_has_incidents "${TEST_TEMP_DIR}/incidents.tsv"; then
	exit 10
fi
result_warn "Windows" "WinGet" "Pandoc failed with installer exit code 1603"
if ! result_has_incidents "${TEST_TEMP_DIR}/incidents.tsv"; then
	exit 11
fi
EOF
	chmod +x "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
}

@test "persisted results stay semantic and render clean summary later" {
	local script="${TEST_TEMP_DIR}/persisted-clean.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_init "${TEST_TEMP_DIR}/clean-results.tsv"
result_ok "WSL" "APT update" "completed in 6s"
result_info "WSL" "uv version" "0.11.16 (unchanged)"
result_skip "WSL" "Excalidraw Docker" "Docker Desktop is not running"
result_warn "Windows" "WinGet package Pandoc [JohnMacFarlane.Pandoc]" "upgrade failed with code 1603"
result_fail "WSL" "Broken step" "exit 42"
result_print_group "WSL" "${TEST_TEMP_DIR}/clean-results.tsv" "WSL"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	local stored
	stored="$(<"${TEST_TEMP_DIR}/clean-results.tsv")"
	[[ "$stored" != *$'\033['* ]]
	[[ "$stored" != *"\\033"* ]]
	[[ "$stored" != *"✔"* ]]
	[[ "$stored" != *"⏭"* ]]
	[[ "$stored" != *"OK    "* ]]
	[[ "$output" == *"OK    APT update: completed in 6s"* ]]
	[[ "$output" == *"INFO  uv version: 0.11.16 (unchanged)"* ]]
	[[ "$output" == *"SKIP  Excalidraw Docker: Docker Desktop is not running"* ]]
}

@test "summary renders Windows and WSL fixtures without escaped ANSI or duplicated version labels" {
	local windows="${TEST_TEMP_DIR}/windows.tsv"
	local wsl="${TEST_TEMP_DIR}/wsl.tsv"
	cat >"$windows" <<'EOF'
WARN	Windows	WinGet package Pandoc [JohnMacFarlane.Pandoc]	upgrade failed with code 1603
OK	Windows	WSL update	completed in 2s
EOF
	cat >"$wsl" <<'EOF'
OK	WSL	APT update	completed in 6s
SKIP	WSL	Excalidraw Docker	Docker Desktop is not running; Excalidraw images were not updated
INFO	WSL	GitNexus CLI version	1.6.5 (unchanged)
INFO	WSL	pnpm version	11.2.2 (unchanged)
INFO	WSL	uv version	0.11.16 (unchanged)
EOF
	local script="${TEST_TEMP_DIR}/summary-fixture.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_print_group "Windows" "$windows" "Windows"
result_print_group "WSL" "$wsl" "WSL"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *"\\033"* ]]
	[[ "$output" != *"version: version:"* ]]
	[[ "$output" == *"WARN  WinGet package Pandoc [JohnMacFarlane.Pandoc]: upgrade failed with code 1603"* ]]
	[[ "$output" == *"SKIP  Excalidraw Docker: Docker Desktop is not running; Excalidraw images were not updated"* ]]
	[[ "$output" == *"INFO  GitNexus CLI version: 1.6.5 (unchanged)"* ]]
	[[ "$output" == *"INFO  pnpm version: 11.2.2 (unchanged)"* ]]
	[[ "$output" == *"INFO  uv version: 0.11.16 (unchanged)"* ]]
}

@test "concise summary suppresses routine OK steps and shows tool snapshot" {
	local windows="${TEST_TEMP_DIR}/windows-ok.tsv"
	local wsl="${TEST_TEMP_DIR}/wsl-ok.tsv"
	local snapshot="${TEST_TEMP_DIR}/tool-snapshot.tsv"
	cat >"$windows" <<'EOF'
OK	Windows	WinGet sources	completed in 1s
OK	Windows	WSL update	completed in 2s
EOF
	cat >"$wsl" <<'EOF'
OK	WSL	APT update	completed in 2s
OK	WSL	APT upgrade	completed in 0s
OK	WSL	Oh My Zsh plugin z	completed in 1s
INFO	WSL	Services	no managed local service restart required
EOF
	cat >"$snapshot" <<'EOF'
Node.js	v24.15.0	v24.15.0	unchanged
Codex CLI	0.80.0	0.81.0	updated
uv	0.11.16	0.11.16	unchanged
EOF
	local script="${TEST_TEMP_DIR}/concise-summary.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_print_concise_summary "$windows" "$wsl" "$snapshot" "${TEST_TEMP_DIR}/logs"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Tool snapshot"* ]]
	[[ "$output" == *"Node.js"* ]]
	[[ "$output" == *"Codex CLI"* ]]
	[[ "$output" == *"0.80.0"* ]]
	[[ "$output" == *"0.81.0"* ]]
	[[ "$output" == *"updated"* ]]
	[[ "$output" == *"Completed successfully"* ]]
	[[ "$output" == *"Logs: ${TEST_TEMP_DIR}/logs"* ]]
	[[ "$output" != *"APT update"* ]]
	[[ "$output" != *"APT upgrade"* ]]
	[[ "$output" != *"Oh My Zsh plugin z"* ]]
	[[ "$output" != *"Services"* ]]
	[[ "$output" != *"Incidents"* ]]
	[[ "$output" != *"Skipped"* ]]
}

@test "tool snapshot renders updated and installed rows safely" {
	local snapshot="${TEST_TEMP_DIR}/tool-snapshot.tsv"
	local script="${TEST_TEMP_DIR}/snapshot-render.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
tool_snapshot_init "$snapshot"
tool_snapshot_add "Codex CLI" "0.80.0" "0.81.0"
tool_snapshot_add "uv" "0.11.16" "0.11.16"
tool_snapshot_add "actionlint" "" "1.7.12"
tool_snapshot_print "$snapshot"
EOF
	chmod +x "$script"
	run env -u NO_COLOR DOTFILES_UPDATE_FORCE_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Tool"* ]]
	[[ "$output" == *"Codex CLI"* ]]
	[[ "$output" == *"0.80.0"* ]]
	[[ "$output" == *"0.81.0"* ]]
	[[ "$output" == *"updated"* ]]
	[[ "$output" == *"actionlint"* ]]
	[[ "$output" == *"1.7.12"* ]]
	[[ "$output" == *"installed"* ]]
	[[ "$output" == *$'\033[0;32m  Codex CLI'* || "$output" == *$'\033[0;32mCodex CLI'* ]]
	[[ "$output" != *"\\033"* ]]
	local stored
	stored="$(<"$snapshot")"
	[[ "$stored" == *$'Codex CLI\t0.80.0\t0.81.0\tupdated'* ]]
	[[ "$stored" == *$'actionlint\t\t1.7.12\tinstalled'* ]]
	[[ "$stored" != *$'\033['* ]]
	[[ "$stored" != *"\\033"* ]]
	[[ "$stored" != *"✔"* ]]

	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *$'\033['* ]]
	[[ "$output" != *"\\033"* ]]
	[[ "$output" == *"updated"* ]]
	[[ "$output" == *"installed"* ]]
}

@test "version normalization keeps osv-scanner and existing tools clean" {
	local script="${TEST_TEMP_DIR}/normalize-versions.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/normalize-run"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
snapshot="${TEST_TEMP_DIR}/normalize-snapshot.tsv"
tool_snapshot_init "\$snapshot"
tool_snapshot_add "osv-scanner" "\$(normalize_component_version "osv-scanner" "osv-scanner version: 2.3.8")" "\$(normalize_component_version "osv-scanner" "osv-scanner version: 2.3.8")"
tool_snapshot_add "Codex CLI" "\$(normalize_component_version "Codex CLI" "codex 0.133.0")" "\$(normalize_component_version "Codex CLI" "codex 0.133.0")"
tool_snapshot_add "ast-grep CLI" "\$(normalize_component_version "ast-grep CLI" "ast-grep 0.42.3")" "\$(normalize_component_version "ast-grep CLI" "ast-grep 0.42.3")"
tool_snapshot_add "uv" "\$(normalize_component_version "uv" "uv 0.11.16 (x86_64-unknown-linux-gnu)")" "\$(normalize_component_version "uv" "uv 0.11.16 (x86_64-unknown-linux-gnu)")"
tool_snapshot_print "\$snapshot"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"osv-scanner            2.3.8          2.3.8          unchanged"* ]]
	[[ "$output" == *"Codex CLI              0.133.0        0.133.0        unchanged"* ]]
	[[ "$output" == *"ast-grep CLI           0.42.3         0.42.3         unchanged"* ]]
	[[ "$output" == *"uv                     0.11.16        0.11.16        unchanged"* ]]
	[[ "$output" != *"ersion:"* ]]
	grep -q $'osv-scanner\t2.3.8\t2.3.8\tunchanged' "${TEST_TEMP_DIR}/normalize-snapshot.tsv"
}

@test "pnpm missing converges through user-space Corepack with clean snapshot" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-corepack"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-corepack-bin"
	local script="${TEST_TEMP_DIR}/pnpm-corepack.sh"
	mkdir -p "$fake_home" "$stub_dir"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_VERSION="11.4.0" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q 'prepare pnpm@latest-11 --activate' "${TEST_TEMP_DIR}/corepack.log"
	grep -q -- "--install-directory ${fake_home}/.npm-global/bin" "${TEST_TEMP_DIR}/corepack.log"
	grep -q $'pnpm\t\t11.4.0\tinstalled' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
	grep -q $'INFO\tWSL\tpnpm method\tcorepack' "${TEST_TEMP_DIR}/run-pnpm/wsl-results.tsv"
	[[ ! -s "${TEST_TEMP_DIR}/fallback.log" ]]
}

@test "pnpm existing but broken is not considered valid" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-broken"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-broken-bin"
	local script="${TEST_TEMP_DIR}/pnpm-broken.sh"
	mkdir -p "$fake_home" "$stub_dir"
	cat >"${stub_dir}/pnpm" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
	chmod +x "${stub_dir}/pnpm"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_VERSION="11.4.1" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-broken.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-broken-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-broken.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'pnpm\t\t11.4.1\tinstalled' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
	grep -q $'INFO\tWSL\tpnpm method\tcorepack' "${TEST_TEMP_DIR}/run-pnpm/wsl-results.tsv"
}

@test "pnpm major 10 is converged to major 11" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-major10"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-major10-bin"
	local script="${TEST_TEMP_DIR}/pnpm-major10.sh"
	mkdir -p "$fake_home" "$stub_dir"
	cat >"${stub_dir}/pnpm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "10.9.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/pnpm"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_VERSION="11.4.2" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-major10.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-major10-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-major10.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'pnpm\t10.9.0\t11.4.2\tupdated' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
	grep -q 'prepare pnpm@latest-11 --activate' "${TEST_TEMP_DIR}/corepack-major10.log"
}

@test "pnpm major 11 still runs update policy through user-space Corepack" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-major11"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-major11-bin"
	local script="${TEST_TEMP_DIR}/pnpm-major11.sh"
	mkdir -p "$fake_home" "$stub_dir"
	cat >"${stub_dir}/pnpm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.2.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/pnpm"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_VERSION="11.5.0" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-major11.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-major11-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-major11.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'pnpm\t11.2.0\t11.5.0\tupdated' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
	grep -q 'prepare pnpm@latest-11 --activate' "${TEST_TEMP_DIR}/corepack-major11.log"
}

@test "pnpm uses updated user-space Corepack instead of system Corepack" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-user-corepack"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-user-corepack-bin"
	local script="${TEST_TEMP_DIR}/pnpm-user-corepack.sh"
	mkdir -p "$fake_home" "$stub_dir"
	cat >"${stub_dir}/corepack" <<'EOF'
#!/usr/bin/env bash
echo "system corepack should not run" >&2
exit 93
EOF
	chmod +x "${stub_dir}/corepack"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_VERSION="11.6.0" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-user.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-user-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-user.log" "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" != *"system corepack should not run"* ]]
	grep -q $'pnpm\t\t11.6.0\tinstalled' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
}

@test "pnpm respects NPM_CONFIG_PREFIX before DOTFILES_NPM_PREFIX" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-prefix-precedence"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-prefix-precedence-bin"
	local script="${TEST_TEMP_DIR}/pnpm-prefix-precedence.sh"
	local npm_prefix="${TEST_TEMP_DIR}/npm-prefix"
	local dotfiles_prefix="${TEST_TEMP_DIR}/dotfiles-prefix"
	mkdir -p "$fake_home" "$stub_dir" "$npm_prefix" "$dotfiles_prefix"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_KEEP_PREFIX_ENV=1 NPM_CONFIG_PREFIX="$npm_prefix" DOTFILES_NPM_PREFIX="$dotfiles_prefix" PNPM_TEST_COREPACK_VERSION="11.6.1" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-prefix-precedence.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-prefix-precedence-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-prefix-precedence.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q -- "--install-directory ${npm_prefix}/bin" "${TEST_TEMP_DIR}/corepack-prefix-precedence.log"
	[[ -x "${npm_prefix}/bin/corepack" ]]
	[[ ! -e "${dotfiles_prefix}/bin/corepack" ]]
}

@test "pnpm respects DOTFILES_NPM_PREFIX when NPM_CONFIG_PREFIX is absent" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-dotfiles-prefix"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-dotfiles-prefix-bin"
	local script="${TEST_TEMP_DIR}/pnpm-dotfiles-prefix.sh"
	local dotfiles_prefix="${TEST_TEMP_DIR}/dotfiles-prefix-only"
	mkdir -p "$fake_home" "$stub_dir" "$dotfiles_prefix"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env -u NPM_CONFIG_PREFIX PNPM_TEST_KEEP_PREFIX_ENV=1 DOTFILES_NPM_PREFIX="$dotfiles_prefix" PNPM_TEST_COREPACK_VERSION="11.6.2" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-dotfiles-prefix.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-dotfiles-prefix-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-dotfiles-prefix.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q -- "--install-directory ${dotfiles_prefix}/bin" "${TEST_TEMP_DIR}/corepack-dotfiles-prefix.log"
}

@test "pnpm uses npm config user-space prefix when it is explicit and writable" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-npm-config-prefix"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-npm-config-prefix-bin"
	local script="${TEST_TEMP_DIR}/pnpm-npm-config-prefix.sh"
	local npm_config_prefix="${TEST_TEMP_DIR}/npm-config-prefix"
	mkdir -p "$fake_home" "$stub_dir" "$npm_config_prefix"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_NPM_PREFIX_REPLY="$npm_config_prefix" PNPM_TEST_COREPACK_VERSION="11.6.3" PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-npm-config-prefix.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-npm-config-prefix-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-npm-config-prefix.log" "$script"
	[[ "$status" -eq 0 ]]
	grep -q -- "--install-directory ${npm_config_prefix}/bin" "${TEST_TEMP_DIR}/corepack-npm-config-prefix.log"
}

@test "pnpm falls back to npm major 11 when Corepack validation fails" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-fallback"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-fallback-bin"
	local script="${TEST_TEMP_DIR}/pnpm-fallback.sh"
	mkdir -p "$fake_home" "$stub_dir"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-fallback.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-fallback-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-fallback.log" PNPM_TEST_FALLBACK_VERSION="11.7.0" "$script"
	[[ "$status" -eq 0 ]]
	grep -q 'pnpm@^11' "${TEST_TEMP_DIR}/fallback-fallback.log"
	grep -q $'pnpm\t\t11.7.0\tinstalled' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
	grep -q $'WARN\tWSL\tpnpm Corepack\tCorepack did not produce a functional pnpm 11; falling back to npm global' "${TEST_TEMP_DIR}/run-pnpm/wsl-results.tsv"
	grep -q $'WARN\tWSL\tpnpm method\tnpm-global fallback after Corepack validation failed' "${TEST_TEMP_DIR}/run-pnpm/wsl-results.tsv"
}

@test "pnpm records failure when Corepack and npm fallback both fail" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-fail"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-fail-bin"
	local script="${TEST_TEMP_DIR}/pnpm-fail.sh"
	mkdir -p "$fake_home" "$stub_dir"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-fail.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-fail-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-fail.log" PNPM_TEST_FALLBACK_EXIT=42 "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'FAIL\tWSL\tpnpm fallback\texit 42' "${TEST_TEMP_DIR}/run-pnpm/wsl-results.tsv"
	grep -q $'FAIL\tWSL\tpnpm\tfallback npm install did not produce a functional pnpm 11' "${TEST_TEMP_DIR}/run-pnpm/wsl-results.tsv"
}

@test "pnpm removes broken shim created by Corepack flow before fallback" {
	local fake_home="${TEST_TEMP_DIR}/home-pnpm-cleanup"
	local stub_dir="${TEST_TEMP_DIR}/pnpm-cleanup-bin"
	local script="${TEST_TEMP_DIR}/pnpm-cleanup.sh"
	mkdir -p "$fake_home" "$stub_dir"
	write_pnpm_fake_npm "$stub_dir"
	write_pnpm_update_runner "$script" "$fake_home" "$stub_dir"
	run env PNPM_TEST_COREPACK_BROKEN_SHIM=1 PNPM_TEST_COREPACK_LOG="${TEST_TEMP_DIR}/corepack-cleanup.log" PNPM_TEST_COREPACK_DIR_FILE="${TEST_TEMP_DIR}/corepack-cleanup-dir" PNPM_TEST_FALLBACK_LOG="${TEST_TEMP_DIR}/fallback-cleanup.log" PNPM_TEST_FALLBACK_VERSION="11.8.0" "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'pnpm\t\t11.8.0\tinstalled' "${TEST_TEMP_DIR}/run-pnpm/tool-snapshot.tsv"
	"${fake_home}/.npm-global/bin/pnpm" --version | grep -q '^11.8.0$'
}

@test "concise summary deduplicates Pandoc incident and keeps log reference" {
	local windows="${TEST_TEMP_DIR}/windows-pandoc.tsv"
	local wsl="${TEST_TEMP_DIR}/wsl-pandoc.tsv"
	local snapshot="${TEST_TEMP_DIR}/snapshot-pandoc.tsv"
	cat >"$windows" <<EOF
WARN	Windows	WinGet packages	exit -1978335188 in 5s; log: ${TEST_TEMP_DIR}/logs/windows-winget-upgrade.log
WARN	Windows	WinGet package details	could not parse package-level results; see log: ${TEST_TEMP_DIR}/logs/windows-winget-upgrade.log
WARN	Windows	WinGet package Pandoc [JohnMacFarlane.Pandoc]	upgrade failed with code 1603
OK	Windows	WSL update	completed in 2s
EOF
	cat >"$wsl" <<'EOF'
OK	WSL	APT update	completed in 2s
EOF
	cat >"$snapshot" <<'EOF'
uv	0.11.16	0.11.16	unchanged
EOF
	local script="${TEST_TEMP_DIR}/pandoc-summary.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_print_concise_summary "$windows" "$wsl" "$snapshot" "${TEST_TEMP_DIR}/logs"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Incidents"* ]]
	[[ "$output" == *"WARN  Windows / WinGet / Pandoc: upgrade failed with code 1603"* ]]
	[[ "$output" == *"log: ${TEST_TEMP_DIR}/logs/windows-winget-upgrade.log"* ]]
	[[ "$output" != *"WinGet packages: exit -1978335188"* ]]
	[[ "$output" != *"could not parse package-level results"* ]]
	[[ "$output" == *"Completed with 1 incident: Windows / WinGet / Pandoc."* ]]
}

@test "concise summary shows Docker skip once without incident" {
	local windows="${TEST_TEMP_DIR}/windows-docker.tsv"
	local wsl="${TEST_TEMP_DIR}/wsl-docker.tsv"
	local snapshot="${TEST_TEMP_DIR}/snapshot-docker.tsv"
	: >"$windows"
	cat >"$wsl" <<'EOF'
SKIP	WSL	Excalidraw Docker	Docker Desktop is not running; Excalidraw images were not updated
INFO	WSL	Excalidraw Docker	Run 'make excalidraw-update' after starting Docker Desktop when needed
OK	WSL	APT update	completed in 2s
EOF
	cat >"$snapshot" <<'EOF'
uv	0.11.16	0.11.16	unchanged
EOF
	local script="${TEST_TEMP_DIR}/docker-summary.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_print_concise_summary "$windows" "$wsl" "$snapshot" "${TEST_TEMP_DIR}/logs"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Skipped"* ]]
	[[ "$output" == *"SKIP  Excalidraw Docker: Docker Desktop is not running"* ]]
	[[ "$output" == *"run: make excalidraw-update after starting Docker Desktop"* ]]
	[[ "$output" == *"Completed successfully. 1 optional step skipped: Excalidraw Docker."* ]]
	[[ "$output" != *"Incidents"* ]]
	[[ "$output" != *"APT update"* ]]
	[[ "$(grep -o 'Excalidraw Docker:' <<<"$output" | wc -l)" -eq 1 ]]
}

@test "version formatting normalizes labels and changed versions" {
	local fake_home="${TEST_TEMP_DIR}/home-tools"
	local stub_dir="${TEST_TEMP_DIR}/tools-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	write_global_npm_package "$npm_prefix" "gitnexus" "1.6.5"
	printf '1.6.5\n' >"${TEST_TEMP_DIR}/gitnexus-version"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  echo "1.6.6"
  exit 0
fi
if [[ "\$1" == "install" && "\$*" == *"gitnexus@latest"* ]]; then
  printf '1.6.6\n' >"${TEST_TEMP_DIR}/gitnexus-version"
  cat >"${npm_prefix}/lib/node_modules/gitnexus/package.json" <<'PKG'
{"name":"gitnexus","version":"1.6.6"}
PKG
fi
if [[ "\$1" == "install" && "\$*" == *"corepack@latest"* ]]; then
  cat >"${npm_prefix}/bin/corepack" <<'COREPACK'
#!/usr/bin/env bash
echo "corepack $*"
exit 0
COREPACK
  chmod +x "${npm_prefix}/bin/corepack"
fi
echo "npm install \$*"
exit 0
EOF
	cat >"${stub_dir}/gitnexus" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) printf 'gitnexus %s\n' "\$(cat "${TEST_TEMP_DIR}/gitnexus-version")";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/corepack" <<'EOF'
#!/usr/bin/env bash
echo "corepack $*"
exit 0
EOF
	cat >"${stub_dir}/pnpm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.2.2";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/actionlint" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "actionlint 1.7.12";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/osv-scanner" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "osv-scanner version: 2.3.8";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
	cat >"${stub_dir}/jq" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
exit 0
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus" "${stub_dir}/corepack" "${stub_dir}/pnpm" "${stub_dir}/actionlint" "${stub_dir}/osv-scanner" "${stub_dir}/curl" "${stub_dir}/jq"
	run env HOME="$fake_home" NPM_CONFIG_PREFIX="$npm_prefix" PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-tools" "${DOTFILES_DIR}/scripts/update/update-wsl.sh" --section tools
	[[ "$status" -eq 0 ]]
	grep -q $'INFO\tWSL\tGitNexus CLI version\t1.6.5 → 1.6.6' "${TEST_TEMP_DIR}/run-tools/wsl-results.tsv"
	grep -q $'INFO\tWSL\tpnpm version\t11.2.2 (unchanged)' "${TEST_TEMP_DIR}/run-tools/wsl-results.tsv"
	[[ "$output" == *"GitNexus CLI version: 1.6.5 → 1.6.6"* ]]
	[[ "$output" == *"pnpm version: 11.2.2 (unchanged)"* ]]
	[[ "$output" == *"WARN   actionlint update check failed; keeping installed version 1.7.12"* ]]
	[[ "$output" != *"version: version:"* ]]
	grep -q $'WARN\tWSL\tactionlint\tupdate check failed; keeping installed version 1.7.12' "${TEST_TEMP_DIR}/run-tools/wsl-results.tsv"
	grep -q $'WARN\tWSL\tosv-scanner\tupdate check failed; keeping installed version 2.3.8' "${TEST_TEMP_DIR}/run-tools/wsl-results.tsv"
	grep -q $'actionlint\t1.7.12\t1.7.12\tunchanged' "${TEST_TEMP_DIR}/run-tools/tool-snapshot.tsv"
	grep -q $'osv-scanner\t2.3.8\t2.3.8\tunchanged' "${TEST_TEMP_DIR}/run-tools/tool-snapshot.tsv"
}

@test "concise summary shows agent tool update-check warnings in incidents" {
	local windows="${TEST_TEMP_DIR}/windows-agent-warn.tsv"
	local wsl="${TEST_TEMP_DIR}/wsl-agent-warn.tsv"
	local snapshot="${TEST_TEMP_DIR}/snapshot-agent-warn.tsv"
	: >"$windows"
	cat >"$wsl" <<'EOF'
OK	WSL	Agent validation tools	completed in 1s
WARN	WSL	actionlint	update check failed; keeping installed version 1.7.12
WARN	WSL	osv-scanner	update check failed; keeping installed version 2.3.8
EOF
	cat >"$snapshot" <<'EOF'
actionlint	1.7.12	1.7.12	unchanged
osv-scanner	2.3.8	2.3.8	unchanged
EOF
	local script="${TEST_TEMP_DIR}/agent-warn-summary.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_print_concise_summary "$windows" "$wsl" "$snapshot" "${TEST_TEMP_DIR}/logs"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Incidents"* ]]
	[[ "$output" == *"WARN  WSL / actionlint: update check failed; keeping installed version 1.7.12"* ]]
	[[ "$output" == *"WARN  WSL / osv-scanner: update check failed; keeping installed version 2.3.8"* ]]
	[[ "$output" == *"actionlint             1.7.12         1.7.12         unchanged"* ]]
	[[ "$output" == *"Completed with 2 incident"* ]]
	[[ "$output" != *"Skipped"* ]]
}

@test "concise summary combines Pandoc and agent tool update-check warnings" {
	local windows="${TEST_TEMP_DIR}/windows-pandoc-agent.tsv"
	local wsl="${TEST_TEMP_DIR}/wsl-pandoc-agent.tsv"
	local snapshot="${TEST_TEMP_DIR}/snapshot-pandoc-agent.tsv"
	cat >"$windows" <<EOF
WARN	Windows	WinGet packages	exit -1978335188 in 5s; log: ${TEST_TEMP_DIR}/logs/windows-winget-upgrade.log
WARN	Windows	WinGet package details	could not parse package-level results; see log: ${TEST_TEMP_DIR}/logs/windows-winget-upgrade.log
WARN	Windows	WinGet package Pandoc [JohnMacFarlane.Pandoc]	upgrade failed with code 1603
EOF
	cat >"$wsl" <<'EOF'
WARN	WSL	actionlint	update check failed; keeping installed version 1.7.12
EOF
	cat >"$snapshot" <<'EOF'
actionlint	1.7.12	1.7.12	unchanged
EOF
	local script="${TEST_TEMP_DIR}/pandoc-agent-summary.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/results.sh"
result_print_concise_summary "$windows" "$wsl" "$snapshot" "${TEST_TEMP_DIR}/logs"
EOF
	chmod +x "$script"
	run env NO_COLOR=1 "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"WARN  Windows / WinGet / Pandoc: upgrade failed with code 1603"* ]]
	[[ "$output" == *"WARN  WSL / actionlint: update check failed; keeping installed version 1.7.12"* ]]
	[[ "$output" != *"WinGet packages: exit -1978335188"* ]]
	[[ "$output" == *"Completed with 2 incident"* ]]
}

@test "global npm helper skips reinstall when package already matches remote target" {
	local fake_home="${TEST_TEMP_DIR}/home-npm-same"
	local stub_dir="${TEST_TEMP_DIR}/npm-same-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	write_global_npm_package "$npm_prefix" "gitnexus" "1.6.5"
	printf '1.6.5\n' >"${TEST_TEMP_DIR}/gitnexus-version"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  echo "1.6.5"
  exit 0
fi
if [[ "\$1" == "install" ]]; then
  echo "install should not run" >&2
  exit 97
fi
exit 0
EOF
	cat >"${stub_dir}/gitnexus" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) printf 'gitnexus %s\n' "\$(cat "${TEST_TEMP_DIR}/gitnexus-version")";; *) exit 0;; esac
EOF
	local script="${TEST_TEMP_DIR}/npm-same.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
NPM_CONFIG_PREFIX="${npm_prefix}"
PATH="${stub_dir}:/usr/bin:/bin"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-npm-same"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_global_npm_tool_if_needed "WSL" "GitNexus CLI" "${TEST_TEMP_DIR}/run-npm-same/gitnexus.log" "${npm_prefix}" "gitnexus" "latest" gitnexus --version --
tool_snapshot_print "${TEST_TEMP_DIR}/run-npm-same/tool-snapshot.tsv"
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus" "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"OK    GitNexus CLI already latest: 1.6.5"* ]]
	[[ "$output" == *"GitNexus CLI           1.6.5          1.6.5          unchanged"* ]]
	grep -q $'OK\tWSL\tGitNexus CLI\talready latest: 1.6.5' "${TEST_TEMP_DIR}/run-npm-same/wsl-results.tsv"
	grep -q $'GitNexus CLI\t1.6.5\t1.6.5\tunchanged' "${TEST_TEMP_DIR}/run-npm-same/tool-snapshot.tsv"
	[[ "$output" != *"SKIP"* ]]
	[[ "$output" != *"npm warn"* ]]
}

@test "global npm helper installs when remote version is newer" {
	local fake_home="${TEST_TEMP_DIR}/home-npm-update"
	local stub_dir="${TEST_TEMP_DIR}/npm-update-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	write_global_npm_package "$npm_prefix" "gitnexus" "1.6.5"
	printf '1.6.5\n' >"${TEST_TEMP_DIR}/gitnexus-version"
	printf '0\n' >"${TEST_TEMP_DIR}/gitnexus-install-count"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  echo "1.6.6"
  exit 0
fi
if [[ "\$1" == "install" && "\$*" == *"gitnexus@latest"* ]]; then
  echo 1 >"${TEST_TEMP_DIR}/gitnexus-install-count"
  printf '1.6.6\n' >"${TEST_TEMP_DIR}/gitnexus-version"
  cat >"${npm_prefix}/lib/node_modules/gitnexus/package.json" <<'PKG'
{"name":"gitnexus","version":"1.6.6"}
PKG
  echo "changed 1 package"
  exit 0
fi
exit 0
EOF
	cat >"${stub_dir}/gitnexus" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) printf 'gitnexus %s\n' "\$(cat "${TEST_TEMP_DIR}/gitnexus-version")";; *) exit 0;; esac
EOF
	local script="${TEST_TEMP_DIR}/npm-update.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
NPM_CONFIG_PREFIX="${npm_prefix}"
PATH="${stub_dir}:/usr/bin:/bin"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-npm-update"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_global_npm_tool_if_needed "WSL" "GitNexus CLI" "${TEST_TEMP_DIR}/run-npm-update/gitnexus.log" "${npm_prefix}" "gitnexus" "latest" gitnexus --version --
tool_snapshot_print "${TEST_TEMP_DIR}/run-npm-update/tool-snapshot.tsv"
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus" "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"INFO  GitNexus CLI update available: 1.6.5 → 1.6.6"* ]]
	[[ "$output" == *"OK    GitNexus CLI ("* ]]
	[[ "$output" == *"GitNexus CLI           1.6.5          1.6.6          updated"* ]]
	[[ "$(cat "${TEST_TEMP_DIR}/gitnexus-install-count")" -eq 1 ]]
	grep -q $'GitNexus CLI\t1.6.5\t1.6.6\tupdated' "${TEST_TEMP_DIR}/run-npm-update/tool-snapshot.tsv"
}

@test "global npm helper installs missing tool and records installed snapshot" {
	local fake_home="${TEST_TEMP_DIR}/home-npm-install"
	local stub_dir="${TEST_TEMP_DIR}/npm-install-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  echo "0.133.0"
  exit 0
fi
if [[ "\$1" == "install" && "\$*" == *"@openai/codex@latest"* ]]; then
  mkdir -p "${npm_prefix}/lib/node_modules/@openai/codex"
  cat >"${npm_prefix}/lib/node_modules/@openai/codex/package.json" <<'PKG'
{"name":"@openai/codex","version":"0.133.0"}
PKG
  printf '0.133.0\n' >"${TEST_TEMP_DIR}/codex-version"
  echo "added 1 package"
  exit 0
fi
exit 0
EOF
	cat >"${stub_dir}/codex" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "--version" && -f "${TEST_TEMP_DIR}/codex-version" ]]; then
  printf 'codex-cli %s\n' "\$(cat "${TEST_TEMP_DIR}/codex-version")"
  exit 0
fi
exit 1
EOF
	local script="${TEST_TEMP_DIR}/npm-install.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
NPM_CONFIG_PREFIX="${npm_prefix}"
PATH="${stub_dir}:/usr/bin:/bin"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-npm-install"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_global_npm_tool_if_needed "WSL" "Codex CLI" "${TEST_TEMP_DIR}/run-npm-install/codex.log" "${npm_prefix}" "@openai/codex" "latest" codex --version --
tool_snapshot_print "${TEST_TEMP_DIR}/run-npm-install/tool-snapshot.tsv"
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/codex" "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"INFO  Codex CLI is not installed; installing latest available version 0.133.0"* ]]
	[[ "$output" == *"0.133.0"* ]]
	[[ "$output" == *"installed"* ]]
	grep -q $'Codex CLI\t\t0.133.0\tinstalled' "${TEST_TEMP_DIR}/run-npm-install/tool-snapshot.tsv"
}

@test "global npm helper warns on remote lookup failure and keeps installed version" {
	local fake_home="${TEST_TEMP_DIR}/home-npm-warn"
	local stub_dir="${TEST_TEMP_DIR}/npm-warn-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	write_global_npm_package "$npm_prefix" "gitnexus" "1.6.5"
	printf '1.6.5\n' >"${TEST_TEMP_DIR}/gitnexus-version"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  exit 1
fi
if [[ "\$1" == "install" ]]; then
  echo "install should not run" >&2
  exit 91
fi
exit 0
EOF
	cat >"${stub_dir}/gitnexus" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) printf 'gitnexus %s\n' "\$(cat "${TEST_TEMP_DIR}/gitnexus-version")";; *) exit 0;; esac
EOF
	local script="${TEST_TEMP_DIR}/npm-warn.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
NPM_CONFIG_PREFIX="${npm_prefix}"
PATH="${stub_dir}:/usr/bin:/bin"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-npm-warn"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_global_npm_tool_if_needed "WSL" "GitNexus CLI" "${TEST_TEMP_DIR}/run-npm-warn/gitnexus.log" "${npm_prefix}" "gitnexus" "latest" gitnexus --version --
tool_snapshot_print "${TEST_TEMP_DIR}/run-npm-warn/tool-snapshot.tsv"
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus" "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"WARN  GitNexus CLI update check failed; keeping installed version 1.6.5"* ]]
	[[ "$output" == *"GitNexus CLI           1.6.5          1.6.5          unchanged"* ]]
	grep -q $'WARN\tWSL\tGitNexus CLI\tupdate check failed; keeping installed version 1.6.5' "${TEST_TEMP_DIR}/run-npm-warn/wsl-results.tsv"
}

@test "global npm helper preserves real installation failures" {
	local fake_home="${TEST_TEMP_DIR}/home-npm-fail"
	local stub_dir="${TEST_TEMP_DIR}/npm-fail-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	write_global_npm_package "$npm_prefix" "gitnexus" "1.6.5"
	printf '1.6.5\n' >"${TEST_TEMP_DIR}/gitnexus-version"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  echo "1.6.6"
  exit 0
fi
if [[ "\$1" == "install" ]]; then
  echo "install failed" >&2
  exit 42
fi
exit 0
EOF
	cat >"${stub_dir}/gitnexus" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) printf 'gitnexus %s\n' "\$(cat "${TEST_TEMP_DIR}/gitnexus-version")";; *) exit 0;; esac
EOF
	local script="${TEST_TEMP_DIR}/npm-fail.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
NPM_CONFIG_PREFIX="${npm_prefix}"
PATH="${stub_dir}:/usr/bin:/bin"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-npm-fail"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_global_npm_tool_if_needed "WSL" "GitNexus CLI" "${TEST_TEMP_DIR}/run-npm-fail/gitnexus.log" "${npm_prefix}" "gitnexus" "latest" gitnexus --version --
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/gitnexus" "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	grep -q $'FAIL\tWSL\tGitNexus CLI\texit 42' "${TEST_TEMP_DIR}/run-npm-fail/wsl-results.tsv"
	run grep -q $'GitNexus CLI\t1.6.5\t1.6.6\tupdated' "${TEST_TEMP_DIR}/run-npm-fail/tool-snapshot.tsv"
	[[ "$status" -ne 0 ]]
}

@test "global npm helper resolves scoped package versions without reinstalling" {
	local fake_home="${TEST_TEMP_DIR}/home-npm-scoped"
	local stub_dir="${TEST_TEMP_DIR}/npm-scoped-bin"
	local npm_prefix="${fake_home}/.npm-global"
	mkdir -p "$stub_dir" "$npm_prefix/bin"
	write_global_npm_package "$npm_prefix" "@ast-grep/cli" "0.42.3"
	printf '0.42.3\n' >"${TEST_TEMP_DIR}/ast-grep-version"
	make_passthrough_node_stub "$stub_dir" "v24.11.1"
	cat >"${stub_dir}/npm" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "root" && "\$2" == "-g" ]]; then
  echo "${npm_prefix}/lib/node_modules"
  exit 0
fi
if [[ "\$1" == "view" ]]; then
  echo "0.42.3"
  exit 0
fi
if [[ "\$1" == "install" ]]; then
  echo "install should not run" >&2
  exit 98
fi
exit 0
EOF
	cat >"${stub_dir}/ast-grep" <<EOF
#!/usr/bin/env bash
case "\$1" in --version) printf 'ast-grep %s\n' "\$(cat "${TEST_TEMP_DIR}/ast-grep-version")";; *) exit 0;; esac
EOF
	local script="${TEST_TEMP_DIR}/npm-scoped.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
set -- --section none
HOME="${fake_home}"
NPM_CONFIG_PREFIX="${npm_prefix}"
PATH="${stub_dir}:/usr/bin:/bin"
DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-npm-scoped"
source "${DOTFILES_DIR}/scripts/update/update-wsl.sh"
update_global_npm_tool_if_needed "WSL" "ast-grep CLI" "${TEST_TEMP_DIR}/run-npm-scoped/ast-grep.log" "${npm_prefix}" "@ast-grep/cli" "latest" ast-grep --version --
tool_snapshot_print "${TEST_TEMP_DIR}/run-npm-scoped/tool-snapshot.tsv"
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/ast-grep" "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"OK    ast-grep CLI already latest: 0.42.3"* ]]
	[[ "$output" == *"ast-grep CLI           0.42.3         0.42.3         unchanged"* ]]
}

@test "update-wsl shell section updates Oh My Zsh through zsh script from Bash" {
	local fake_home="${TEST_TEMP_DIR}/home"
	local stub_dir="${TEST_TEMP_DIR}/shell-bin"
	mkdir -p "${fake_home}/.oh-my-zsh/tools" "${fake_home}/.oh-my-zsh/custom/plugins/z/.git" "${fake_home}/.oh-my-zsh/custom/plugins/zsh-autosuggestions/.git" "$stub_dir"
	cat >"${fake_home}/.oh-my-zsh/tools/upgrade.sh" <<'EOF'
#!/usr/bin/env bash
echo "omz upgraded with ZSH=$ZSH"
exit 0
EOF
	chmod +x "${fake_home}/.oh-my-zsh/tools/upgrade.sh"
	cat >"${stub_dir}/zsh" <<'EOF'
#!/usr/bin/env bash
script="$1"
shift
exec bash "$script" "$@"
EOF
	cat >"${stub_dir}/git" <<'EOF'
#!/usr/bin/env bash
echo "git $*"
exit 0
EOF
	chmod +x "${stub_dir}/zsh" "${stub_dir}/git"
	run env HOME="$fake_home" ZSH="${fake_home}/.oh-my-zsh" ZSH_CUSTOM="${fake_home}/.oh-my-zsh/custom" PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-shell" "${DOTFILES_DIR}/scripts/update/update-wsl.sh" --section shell
	[[ "$status" -eq 0 ]]
	grep -q 'omz upgraded' "${TEST_TEMP_DIR}/run-shell/logs/wsl-omz.log"
	grep -q $'OK\tWSL\tOh My Zsh\tcompleted' "${TEST_TEMP_DIR}/run-shell/wsl-results.tsv"
	grep -q $'OK\tWSL\tOh My Zsh plugin z\tcompleted' "${TEST_TEMP_DIR}/run-shell/wsl-results.tsv"
	[[ "$output" != *"failed with exit 0"* ]]
}

@test "update-wsl reports unchanged uv version cleanly" {
	local fake_home="${TEST_TEMP_DIR}/home"
	local stub_dir="${fake_home}/.local/bin"
	mkdir -p "$stub_dir"
	cat >"${stub_dir}/uv" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  --version) echo "uv 0.6.1" ;;
  self) echo "already up to date"; exit 0 ;;
  *) exit 0 ;;
esac
EOF
	chmod +x "${stub_dir}/uv"
	run env HOME="${fake_home}" PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-uv" "${DOTFILES_DIR}/scripts/update/update-wsl.sh" --section shell
	[[ "$status" -eq 0 ]]
	grep -q $'INFO\tWSL\tuv version\t0.6.1 (unchanged)' "${TEST_TEMP_DIR}/run-uv/wsl-results.tsv"
	[[ "$output" == *"uv version: 0.6.1 (unchanged)"* ]]
	[[ "$output" != *"version: version:"* ]]
}

@test "winget parser extracts Spanish package failure and success" {
	local log="${TEST_TEMP_DIR}/windows-winget-upgrade.log"
	cat >"$log" <<'EOF'
(1/2) Encontrado Pandoc [JohnMacFarlane.Pandoc] Versión 3.9.0.2
Iniciando la desinstalación de paquete...
Error de desinstalación con el código de salida: 1603

(2/2) Encontrado Microsoft Teams [Microsoft.Teams] Versión 26106.1911.4707.3286
Iniciando instalación de paquete...
Se instaló correctamente. Reinicie la aplicación para completar la actualización.
EOF
	run python3 "${DOTFILES_DIR}/scripts/update/parse-winget-log.py" "$log"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *$'WARN\tWindows\tWinGet package Pandoc [JohnMacFarlane.Pandoc]\tupgrade failed with code 1603'* ]]
	[[ "$output" == *$'OK\tWindows\tWinGet package Microsoft Teams [Microsoft.Teams]\tupdated successfully'* ]]
}

@test "winget parser extracts legacy UTF-16 mojibake package details" {
	local log="${TEST_TEMP_DIR}/legacy-winget.log"
	python3 - "$log" <<'PY'
from pathlib import Path
import sys
text = """(1/2) Encontrado Pandoc [JohnMacFarlane.Pandoc] Versi├│n 3.9.0.2
Iniciando la desinstalaci├│n de paquete...
Error de desinstalaci├│n con el c├│digo de salida: 1603

(2/2) Encontrado Microsoft Teams [Microsoft.Teams] Versi├│n 26106.1911.4707.3286
Iniciando instalaci├│n de paquete...
Se instal├│ correctamente. Reinicie la aplicaci├│n para completar la actualizaci├│n.
"""
Path(sys.argv[1]).write_bytes(text.encode("utf-16"))
PY
	run python3 "${DOTFILES_DIR}/scripts/update/parse-winget-log.py" "$log"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *$'WARN\tWindows\tWinGet package Pandoc [JohnMacFarlane.Pandoc]\tupgrade failed with code 1603'* ]]
	[[ "$output" == *$'OK\tWindows\tWinGet package Microsoft Teams [Microsoft.Teams]\tupdated successfully'* ]]
}

@test "winget parser extracts package details from real binary log fixture when present" {
	local real_log="/mnt/c/Users/jesus/AppData/Local/dotfiles/update-runs/20260523T155942Z-62167/logs/windows-winget-upgrade.log"
	[[ -f "$real_log" ]] || skip "real Windows winget log fixture not present on this host"
	run python3 "${DOTFILES_DIR}/scripts/update/parse-winget-log.py" "$real_log"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *$'WARN\tWindows\tWinGet package Pandoc [JohnMacFarlane.Pandoc]\tupgrade failed with code 1603'* ]]
	[[ "$output" == *$'OK\tWindows\tWinGet package Microsoft Teams [Microsoft.Teams]\tupdated successfully'* ]]
}

@test "PowerShell Windows logging uses native process capture and UTF-8 log writes" {
	local ps1="${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	grep -q 'Run-NativeLogged' "$ps1"
	grep -q 'StandardOutputEncoding' "$ps1"
	grep -Fq '[System.IO.File]::WriteAllText($log, $content, [System.Text.UTF8Encoding]::new($false))' "$ps1"
	run grep -F '*> $log' "$ps1"
	[[ "$status" -ne 0 ]]
}

@test "PowerShell Windows logging keeps WSL and WinGet encoding contracts explicit" {
	local ps1="${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	grep -q 'Run-NativeLogged "WinGet packages".*"utf8"' "$ps1"
	grep -q 'Run-NativeLogged "WSL status".*"unicode"' "$ps1"
	grep -q 'Run-NativeLogged "WSL update".*"unicode"' "$ps1"
}

@test "PowerShell native runner passes arguments to child processes" {
	command -v powershell.exe >/dev/null 2>&1 || skip "requires powershell.exe accessible from WSL (Windows interop)"
	command -v wslpath >/dev/null 2>&1 || skip "requires wslpath to pass repo paths to powershell.exe"
	run powershell.exe -NoProfile -Command 'exit 0'
	if [[ "$status" -ne 0 ]]; then
		skip "powershell.exe is present but not runnable in this environment (WSL interop unavailable; status=$status)"
	fi
	run powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w "${DOTFILES_DIR}/scripts/update/update-windows.ps1")" -SelfTestNativeArguments
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"source"* ]]
	[[ "$output" == *"update"* ]]
	[[ "$output" == *"value with spaces"* ]]
	[[ "$output" == *'quote"inside'* ]]
	[[ "$output" == *"--status"* ]]
	[[ "$output" == *"OK native argument self-test passed"* ]]
}

@test "PowerShell native argument serializer avoids reserved Args parameter" {
	local ps1="${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	run grep -q 'param(\[string\[\]\]\$Args)' "$ps1"
	[[ "$status" -ne 0 ]]
	grep -q 'param(\[string\[\]\]\$NativeArguments)' "$ps1"
	grep -q 'Join-NativeArguments -NativeArguments \$NativeArguments' "$ps1"
}

@test "PowerShell tab prints step output and Windows summary" {
	local ps1="${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	grep -q 'Write-Host "==> \$Name"' "$ps1"
	grep -q 'Write-Host "==> Windows summary"' "$ps1"
	grep -q 'ReadToEndAsync' "$ps1"
}

@test "winget parser degrades cleanly for unknown log format" {
	local log="${TEST_TEMP_DIR}/unknown-winget.log"
	echo "unrecognized winget output" >"$log"
	run python3 "${DOTFILES_DIR}/scripts/update/parse-winget-log.py" "$log"
	[[ "$status" -eq 0 ]]
	[[ -z "$output" ]]
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
	local stub_dir="${TEST_TEMP_DIR}/node24-mock-warning"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Pandoc failed with installer exit code 1603"* ]]
	[[ "${output}" != *"Personal projects are not part of make update"* ]]
	[[ -f "${TEST_TEMP_DIR}/run/windows-results.tsv" ]]
	[[ -f "${TEST_TEMP_DIR}/run/wsl-results.tsv" ]]
}

@test "make update mock records successful Windows results when provided" {
	local stub_dir="${TEST_TEMP_DIR}/node24-mock-ok"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=ok DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-ok" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"WinGet: mocked winget success"* ]]
	[[ "${output}" != *"WSL update: mocked wsl --update"* ]]
	[[ "${output}" != *"Pandoc failed"* ]]
	[[ "${output}" != *"Waiting for Windows update result"* ]]
	[[ "${output}" != *"> Services"* ]]
	[[ "${output}" != *"> Update summary"* ]]
	[[ "${output}" == *"=== Update summary ="* ]]
	[[ "${output}" == *"Completed successfully"* ]]
}

@test "make update replaces WinGet detail fallback when package details are parseable" {
	local stub_dir="${TEST_TEMP_DIR}/node24-winget-details"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=winget-fallback-with-parseable-log DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-winget-details" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"WinGet packages: exit -1978335188"* ]]
	[[ "${output}" == *"Windows / WinGet / Pandoc: upgrade failed with code 1603"* ]]
	[[ "${output}" != *"WinGet package Microsoft Teams [Microsoft.Teams]: updated successfully"* ]]
	[[ "${output}" != *"could not parse package-level results"* ]]
	[[ "${output}" == *"Completed with 1 incident: Windows / WinGet / Pandoc."* ]]
}

@test "make update mock surfaces WinGet package failure without aborting WSL" {
	local stub_dir="${TEST_TEMP_DIR}/node20"
	make_node_stub "$stub_dir" "v20.18.2"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=winget-failure DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-winget" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Windows / WinGet: Pandoc failed with installer exit code 1603"* ]]
	[[ "${output}" != *"WSL update: mocked wsl --update"* ]]
	[[ "${output}" == *"Node runtime for managed tools: switched from v20.18.2"* ]]
	[[ "${output}" != *"GitNexus: skipped because Node runtime is incompatible"* ]]
	[[ "${output}" == *"Completed with 1 incident: Windows / WinGet."* ]]
	[[ "$(grep -c $'INFO\tWSL\tNode runtime for managed tools\t' "${TEST_TEMP_DIR}/run-winget/wsl-results.tsv")" -eq 1 ]]
	! grep -q $'FAIL\tWSL\tNode\t' "${TEST_TEMP_DIR}/run-winget/wsl-results.tsv"
	! find "${TEST_TEMP_DIR}/run-winget" -maxdepth 1 -type d -name 'node-runtime.*' -print | grep -q .
}

@test "make update mock surfaces wsl --update failure and never uses shutdown" {
	local stub_dir="${TEST_TEMP_DIR}/node24-wsl-fail"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=wsl-failure DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-wsl-fail" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Windows / WSL update: wsl --update failed with exit 1"* ]]
	[[ "${output}" == *"Completed with 1 incident: Windows / WSL update."* ]]
	run grep -Eq 'Run-Logged.*wsl --shutdown|^[[:space:]]*wsl --shutdown' "${DOTFILES_DIR}/scripts/update"/*.sh "${DOTFILES_DIR}/scripts/update"/*.ps1
	[[ "${status}" -ne 0 ]]
}

@test "make update mock does not wait indefinitely when Windows result is missing" {
	local stub_dir="${TEST_TEMP_DIR}/node24-missing"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_FORCE_WSL=1 DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=missing-no-done DOTFILES_UPDATE_WINDOWS_TIMEOUT=2 DOTFILES_UPDATE_WAIT_PROGRESS_INTERVAL=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-missing" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Waiting for Windows update result... elapsed"* ]]
	[[ "${output}" == *"No structured Windows result was produced before timeout (2s)"* ]]
	[[ "${output}" == *"Completed with 1 incident: Windows / Windows result."* ]]
}

@test "make update reports partial Windows results when done marker is missing" {
	local stub_dir="${TEST_TEMP_DIR}/node24-partial"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_FORCE_WSL=1 DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=partial-no-done DOTFILES_UPDATE_WINDOWS_TIMEOUT=2 DOTFILES_UPDATE_WAIT_PROGRESS_INTERVAL=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-partial" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"WinGet sources: mocked partial result before hang"* ]]
	[[ "${output}" != *"WinGet packages: mocked partial result before hang"* ]]
	[[ "${output}" == *"Windows update did not write windows.done before timeout (2s); using partial results"* ]]
	[[ "${output}" == *"Completed with 1 incident: Windows / Windows result."* ]]
}

@test "make update mock consolidates multiple Windows incidents" {
	local stub_dir="${TEST_TEMP_DIR}/node24-multi"
	make_node_stub "$stub_dir" "v24.15.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_MOCK_WINDOWS_RESULT=multi-failure DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-multi" make -C "${DOTFILES_DIR}" update
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Windows / WinGet: Pandoc failed with installer exit code 1603"* ]]
	[[ "${output}" == *"Windows / WSL update: wsl --update failed with exit 1"* ]]
	[[ "${output}" == *"Completed with 2 incidents:"* ]]
	[[ "${output}" == *"Windows / WinGet"* ]]
	[[ "${output}" == *"Windows / WSL update"* ]]
}

@test "update run retention preserves current and recent runs while removing old overflow" {
	local root="${TEST_TEMP_DIR}/runs"
	mkdir -p "$root"
	for i in $(seq -w 1 12); do
		mkdir -p "${root}/old-${i}"
		touch -d "30 days ago + ${i} minutes" "${root}/old-${i}"
	done
	mkdir -p "${root}/current"
	local script="${TEST_TEMP_DIR}/retention-check.sh"
	cat >"$script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
source "${DOTFILES_DIR}/scripts/update/lib/environment.sh"
DOTFILES_UPDATE_KEEP_RUNS=10 DOTFILES_UPDATE_RETENTION_DAYS=14 cleanup_old_update_runs "${root}" "${root}/current"
EOF
	chmod +x "$script"
	run "$script"
	[[ "$status" -eq 0 ]]
	[[ -d "${root}/current" ]]
	[[ ! -d "${root}/old-01" ]]
	[[ -d "${root}/old-12" ]]
	[[ "$output" == *"Removed"* ]]
}

@test "update-check reports recoverable Node 20 shadowing" {
	local stub_dir="${TEST_TEMP_DIR}/node20-check"
	make_node_stub "$stub_dir" "v20.18.2"
	run env PATH="${stub_dir}:/usr/bin:/bin" "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node.js effective runtime is below required >=22: v20.18.2 (${stub_dir}/node, unknown-shadowing)"* ]]
	[[ "${output}" == *"Managed compatible runtime available for update tools"* ]]
}

@test "update-check accepts Node 22 and Node 24" {
	local stub_dir="${TEST_TEMP_DIR}/node22-check"
	make_node_stub "$stub_dir" "v22.12.0"
	run env PATH="${stub_dir}:/usr/bin:/bin" "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node.js effective runtime: v22.12.0 (${stub_dir}/node)"* ]]

	local stub_dir24="${TEST_TEMP_DIR}/node24-check"
	make_node_stub "$stub_dir24" "v24.11.1"
	run env PATH="${stub_dir24}:/usr/bin:/bin" "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node.js effective runtime: v24.11.1 (${stub_dir24}/node)"* ]]
}

@test "update-check ignores Docker Desktop helper for unrelated registry" {
	local fake_home="${TEST_TEMP_DIR}/home-update-check-unrelated"
	local stub_dir="${TEST_TEMP_DIR}/update-check-unrelated-bin"
	local docker_config="${TEST_TEMP_DIR}/update-check-unrelated-docker"
	mkdir -p "$fake_home" "$stub_dir" "$docker_config"
	write_update_check_fake_bin "$stub_dir" ok
	cat >"${docker_config}/config.json" <<'EOF'
{"credHelpers":{"registry.example.com":"desktop.exe"}}
EOF
	local before
	before="$(<"${docker_config}/config.json")"
	run env HOME="$fake_home" PATH="$stub_dir" DOTFILES_FORCE_WSL=1 DOCKER_CONFIG="$docker_config" bash "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Docker config has no credential helper requirement for requested images"* ]]
	[[ "$output" != *"make install-docker-desktop-helper"* ]]
	[[ ! -e "${fake_home}/.local/bin/docker-credential-desktop.exe" ]]
	[[ "$(<"${docker_config}/config.json")" == "$before" ]]
}

@test "update-check reports missing helper for Excalidraw registry" {
	local fake_home="${TEST_TEMP_DIR}/home-update-check-ghcr"
	local stub_dir="${TEST_TEMP_DIR}/update-check-ghcr-bin"
	local docker_config="${TEST_TEMP_DIR}/update-check-ghcr-docker"
	mkdir -p "$fake_home" "$stub_dir" "$docker_config"
	write_update_check_fake_bin "$stub_dir" ok
	cat >"${docker_config}/config.json" <<'EOF'
{"credHelpers":{"ghcr.io":"desktop.exe"}}
EOF
	run env HOME="$fake_home" PATH="$stub_dir" DOTFILES_FORCE_WSL=1 DOCKER_CONFIG="$docker_config" bash "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"docker-credential-desktop.exe"* ]]
	[[ "$output" == *"make install-docker-desktop-helper"* ]]
}

@test "update-check defers credential helper warning when Docker daemon is down" {
	local fake_home="${TEST_TEMP_DIR}/home-update-check-daemon"
	local stub_dir="${TEST_TEMP_DIR}/update-check-daemon-bin"
	local docker_config="${TEST_TEMP_DIR}/update-check-daemon-docker"
	mkdir -p "$fake_home" "$stub_dir" "$docker_config"
	write_update_check_fake_bin "$stub_dir" down
	cat >"${docker_config}/config.json" <<'EOF'
{"credHelpers":{"ghcr.io":"desktop.exe"}}
EOF
	run env HOME="$fake_home" PATH="$stub_dir" DOTFILES_FORCE_WSL=1 DOCKER_CONFIG="$docker_config" bash "${DOTFILES_DIR}/scripts/update/update-check.sh"
	[[ "$status" -eq 0 ]]
	[[ "$output" == *"Docker daemon does not respond"* ]]
	[[ "$output" == *"Docker does not respond"* ]]
	[[ "$output" != *"make install-docker-desktop-helper"* ]]
}

@test "update-wsl recovers managed tools under Node 20 shadowing" {
	local stub_dir="${TEST_TEMP_DIR}/node20-wsl"
	make_node_stub "$stub_dir" "v20.18.2"
	run env PATH="${stub_dir}:/usr/bin:/bin" DOTFILES_UPDATE_MOCK=1 DOTFILES_UPDATE_RUN_DIR="${TEST_TEMP_DIR}/run-node20" "${DOTFILES_DIR}/scripts/update/update-wsl.sh" --section tools
	[[ "${status}" -eq 0 ]]
	grep -q $'INFO\tWSL\tNode runtime for managed tools\tswitched from v20.18.2' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
	! grep -q $'FAIL\tWSL\tNode\t' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
	! grep -q 'GitNexus.*skipped because Node runtime is incompatible' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
	! grep -q 'GitNexus.*usable' "${TEST_TEMP_DIR}/run-node20/wsl-results.tsv"
}

@test "update PowerShell script invokes wsl --update and never wsl --shutdown" {
	grep -q 'Run-NativeLogged "WSL update" "windows-wsl-update.log" "wsl" @("--update") "unicode"' "${DOTFILES_DIR}/scripts/update/update-windows.ps1"
	! grep -Eq '^.*Run-Logged.*wsl --shutdown|^[[:space:]]*wsl --shutdown' "${DOTFILES_DIR}/scripts/update/update-windows.ps1"
}

@test "ups command is absent from aliases and Make targets" {
	run grep -Eq '(^|[[:space:]])ups\\(\\)' "${DOTFILES_DIR}/aliases"
	[[ "${status}" -ne 0 ]]
	run grep -Eq '^ups:' "${DOTFILES_DIR}/Makefile" "${DOTFILES_DIR}"/*.mk
	[[ "${status}" -ne 0 ]]
}
