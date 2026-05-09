#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_DOTFILES="${DOTFILES_DIR}/scripts/install-dotfiles.sh"
}

@test "install-dotfiles warns when DOTFILES_APPLY is unset" {
	run bash "${INSTALL_DOTFILES}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DOTFILES_APPLY"* ]] || [[ "${output}" == *"not set"* ]]
}

@test "install-dotfiles DRY_RUN with DOTFILES_APPLY shows planned chezmoi only" {
	run env DRY_RUN=1 DOTFILES_APPLY=1 bash "${INSTALL_DOTFILES}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"[DRY_RUN]"* ]] || [[ "${output}" == *"Planned"* ]]
}

@test "install-verify STRICT fails when PATH has no user tools" {
	run env PATH= STRICT=1 /bin/bash "${DOTFILES_DIR}/scripts/install-verify.sh"
	[[ "${status}" -eq 1 ]]
}

@test "install-check normal mode does not fatal-fail on declarative missing items" {
	# Force a fake inventory by pointing at a tmp YAML with a missing required cmd.
	local fake_root
	fake_root="$(mktemp -d)"
	mkdir -p "${fake_root}/system/packages" "${fake_root}/scripts/lib"
	cat > "${fake_root}/system/packages/required.yaml" <<EOF
schema_version: 1
platform: test
manager: apt
packages:
  - package: definitely-not-installed-xyz
    command: definitely-not-installed-xyz
    required: true
    capability: testing
    note: forced miss
EOF

	run bash -c "
		set -euo pipefail
		# Wrap check-system-deps so install-check sees the fake inventory.
		mkdir -p '${fake_root}/scripts'
		cat > '${fake_root}/scripts/check-system-deps.sh' <<'WRAP'
#!/usr/bin/env bash
exec bash '${DOTFILES_DIR}/scripts/check-system-deps.sh' --inventory '${fake_root}/system/packages/required.yaml' \"\$@\"
WRAP
		chmod +x '${fake_root}/scripts/check-system-deps.sh'
		ln -s '${DOTFILES_DIR}/scripts/lib' '${fake_root}/scripts/lib_real' 2>/dev/null || true
		# Run a copy of install-check.sh whose DOTFILES_ROOT resolves to fake_root.
		mkdir -p '${fake_root}/scripts/lib'
		cp '${DOTFILES_DIR}/scripts/lib/install_common.sh' '${fake_root}/scripts/lib/install_common.sh'
		cp '${DOTFILES_DIR}/scripts/install-check.sh' '${fake_root}/scripts/install-check.sh'
		bash '${fake_root}/scripts/install-check.sh'
	"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"PASS_WITH_WARNINGS"* ]]
	rm -rf "${fake_root}"
}

@test "install-zsh-stack DRY_RUN never clones and is idempotent" {
	run env DRY_RUN=1 bash "${DOTFILES_DIR}/scripts/install-zsh-stack.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* || "${output}" == *"already present"* ]]
	[[ "${output}" == *"never touches"* || "${output}" == *"NOT touched"* ]]
}

@test "install-external surfaces zsh stack detection" {
	run bash "${DOTFILES_DIR}/scripts/install-external.sh"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Zsh stack"* ]]
}

@test "install-check STRICT fails when declarative requirements are missing" {
	local fake_root
	fake_root="$(mktemp -d)"
	mkdir -p "${fake_root}/system/packages" "${fake_root}/scripts/lib"
	cat > "${fake_root}/system/packages/required.yaml" <<EOF
schema_version: 1
platform: test
manager: apt
packages:
  - package: definitely-not-installed-xyz
    command: definitely-not-installed-xyz
    required: true
    capability: testing
    note: forced miss
EOF
	cat > "${fake_root}/scripts/check-system-deps.sh" <<WRAP
#!/usr/bin/env bash
exec bash '${DOTFILES_DIR}/scripts/check-system-deps.sh' --inventory '${fake_root}/system/packages/required.yaml' "\$@"
WRAP
	chmod +x "${fake_root}/scripts/check-system-deps.sh"
	cp "${DOTFILES_DIR}/scripts/lib/install_common.sh" "${fake_root}/scripts/lib/install_common.sh"
	cp "${DOTFILES_DIR}/scripts/install-check.sh" "${fake_root}/scripts/install-check.sh"

	run env STRICT=1 bash "${fake_root}/scripts/install-check.sh"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"FAIL (STRICT=1)"* ]]
	[[ "${output}" == *"STRICT=1 promoted"* ]]
	rm -rf "${fake_root}"
}
