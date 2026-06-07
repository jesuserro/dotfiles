#!/usr/bin/env bats
# Dry-run/check convention guards:
#   - DRY_RUN hardening (Make + install-system-packages safety belt).
#   - Documented SCRIPT_CONVENTIONS.md contract.
#   - Critical mutating wrappers expose a safe preview/check mode.

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_PKGS="${DOTFILES_DIR}/scripts/install-system-packages.sh"
	CONVENTIONS="${DOTFILES_DIR}/docs/SCRIPT_CONVENTIONS.md"
	DOTFILES_APPLY="${DOTFILES_DIR}/bin/dotfiles-apply"
	AGENT_VALIDATE="${DOTFILES_DIR}/scripts/agent-validate-dotfiles.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

@test "make install DRY-RUN=1 fails fast with clear message and no sudo/apt invocation" {
	run env -i HOME="${HOME}" PATH="/usr/bin:/bin" make -C "${DOTFILES_DIR}" -n install DRY-RUN=1
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Unsupported variable name"* ]]
	[[ "${output}" == *"DRY-RUN=1"* ]]
	[[ "${output}" == *"DRY_RUN=1"* ]]
	# We must not even *plan* to run apt-get install (make -n would still print it).
	[[ "${output}" != *"apt-get install"* ]]
	[[ "${output}" != *"sudo apt-get"* ]]
	[[ "${output}" != *"install-system-packages.sh"* ]]
}

@test "make install dry-run=1 (lowercase) is also rejected" {
	run env -i HOME="${HOME}" PATH="/usr/bin:/bin" make -C "${DOTFILES_DIR}" -n install dry-run=1
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"Unsupported variable name"* ]]
	[[ "${output}" == *"dry-run=1"* ]]
}

@test "make install DRY_RUN=1 (underscore) is accepted and triggers --dry-run in install-apt" {
	# Use -n (no-op) so we only inspect the planned recipes without executing them.
	run env -i HOME="${HOME}" PATH="/usr/bin:/bin" make -C "${DOTFILES_DIR}" -n install-apt DRY_RUN=1
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"--dry-run"* ]]
	[[ "${output}" != *"Unsupported variable name"* ]]
}

@test "make install -n does not plan install-node-stack or install-agent-tools" {
	run env -i HOME="${HOME}" PATH="/usr/bin:/bin" make -C "${DOTFILES_DIR}" -n install
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-node-stack.sh"* ]]
	[[ "${output}" != *"install-agent-tools.sh"* ]]
}

@test "install-system-packages.sh forces dry-run when env has DRY-RUN=1 (safety belt)" {
	# Pass an unsupported env variant by name; printenv inside the script reads it
	# even though bash cannot assign to variables with hyphens directly.
	run env "DRY-RUN=1" bash "${INSTALL_PKGS}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"forcing --dry-run"* ]] || [[ "${output}" == *"unsupported env variant"* ]]
	[[ "${output}" == *"Dry run:"* ]]
	# It must not have actually run apt-get.
	[[ "${output}" != *"Reading package lists"* ]]
}

@test "SCRIPT_CONVENTIONS.md documents check dry-run yes and verbose flags" {
	[[ -f "${CONVENTIONS}" ]]
	grep -q '^## 1\. Flag semantics' "${CONVENTIONS}"
	grep -q '`--check`' "${CONVENTIONS}"
	grep -q '`--dry-run`' "${CONVENTIONS}"
	grep -q 'DRY_RUN=1' "${CONVENTIONS}"
	grep -q '`--yes`' "${CONVENTIONS}"
	grep -q '`--verbose`' "${CONVENTIONS}"
	grep -q '^## 2\. Agent policy' "${CONVENTIONS}"
	grep -q '^## 3\. Command audit' "${CONVENTIONS}"
}

@test "AGENT_WORKFLOW.md links SCRIPT_CONVENTIONS.md" {
	grep -q 'SCRIPT_CONVENTIONS.md' "${DOTFILES_DIR}/docs/AGENT_WORKFLOW.md"
}

@test "dotfiles-apply documents check and dry-run as preview aliases" {
	grep -q '\-\-check' "${DOTFILES_APPLY}"
	grep -q '\-\-dry-run' "${DOTFILES_APPLY}"
	local preview_body
	preview_body="$(awk '/^run_preview\(\) \{/,/^\}/' "${DOTFILES_APPLY}")"
	[[ "${preview_body}" == *'run_chezmoi diff'* ]]
	[[ "${preview_body}" == *'run_chezmoi status'* ]]
	run grep -q 'run_chezmoi apply' <<<"${preview_body}"
	[[ "${status}" -eq 1 ]]
}

@test "agent-validate-dotfiles.sh stays read-only" {
	run grep -q 'chezmoi apply' "${AGENT_VALIDATE}"
	[[ "${status}" -eq 1 ]]
	run grep -q 'make update' "${AGENT_VALIDATE}"
	[[ "${status}" -eq 1 ]]
}

@test "treegen.sh documents --check in header" {
	grep -q '\-\-check' "${DOTFILES_DIR}/scripts/treegen.sh"
	grep -q 'CHECK_MODE' "${DOTFILES_DIR}/scripts/treegen.sh"
}

@test "dotfiles-update does not pretend to be a dry-run wrapper" {
	run grep -q '\-\-dry-run' "${DOTFILES_DIR}/bin/dotfiles-update"
	[[ "${status}" -eq 1 ]]
	grep -q 'make update' "${DOTFILES_DIR}/bin/dotfiles-update"
}
