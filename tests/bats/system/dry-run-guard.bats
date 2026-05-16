#!/usr/bin/env bats
# Verifies the DRY_RUN hardening introduced for enterprise WSL bootstrap:
#   - Make-level guard rejects hyphenated variants (DRY-RUN, dry-run, ...).
#   - Make-level supported flag (DRY_RUN=1) still routes to dry-run plumbing.
#   - Script-level safety belt forces dry-run if a hyphen variant slipped via env.

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_PKGS="${DOTFILES_DIR}/scripts/install-system-packages.sh"
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
