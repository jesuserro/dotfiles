#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	INSTALL_NODE="${DOTFILES_DIR}/scripts/install-node-stack.sh"
	setup_temp_dir
}

teardown() {
	teardown_temp_dir
}

make_install_stubs() {
	local stub_dir="$1"
	mkdir -p "$stub_dir"
	export INSTALL_STUB_LOG="${TEST_TEMP_DIR}/install-stub.log"
	export NODE_INSTALLED_MARKER="${TEST_TEMP_DIR}/node-installed"
	export SUDO_FAIL_STAGE="${SUDO_FAIL_STAGE:-}"
	export CURL_FAIL="${CURL_FAIL:-}"
	export GPG_FAIL="${GPG_FAIL:-}"
	export TEE_FAIL="${TEE_FAIL:-}"
	export MKTEMP_FAIL="${MKTEMP_FAIL:-}"
	export MKTEMP_CREATED_LOG="${TEST_TEMP_DIR}/mktemp-created.log"
	: >"$INSTALL_STUB_LOG"
	: >"$MKTEMP_CREATED_LOG"

	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
	if [[ -f "$NODE_INSTALLED_MARKER" ]]; then
		echo "v24.15.0"
	else
		echo "v20.18.2"
	fi
	exit 0
fi
exit 0
EOF
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.12.1";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npx" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.12.1";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/corepack" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "0.34.1";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/sudo" <<'EOF'
#!/usr/bin/env bash
echo "sudo $*" >> "$INSTALL_STUB_LOG"
exec "$@"
EOF
	cat >"${stub_dir}/apt-get" <<'EOF'
#!/usr/bin/env bash
echo "apt-get $*" >> "$INSTALL_STUB_LOG"
count_file="${TEST_TEMP_DIR}/apt-update-count"
case "$1" in
	update)
		count=0
		[[ -f "$count_file" ]] && count="$(cat "$count_file")"
		count=$((count + 1))
		echo "$count" > "$count_file"
		if [[ "${SUDO_FAIL_STAGE:-}" == "first-update" && "$count" -eq 1 ]]; then
			echo "simulated initial apt-get update failure" >&2
			exit 41
		fi
		if [[ "${SUDO_FAIL_STAGE:-}" == "second-update" && "$count" -eq 2 ]]; then
			echo "simulated nodesource apt-get update failure" >&2
			exit 42
		fi
		;;
	install)
		if [[ "${SUDO_FAIL_STAGE:-}" == "node-install" && "$*" == *"nodejs"* ]]; then
			echo "simulated nodejs install failure" >&2
			exit 43
		fi
		if [[ "$*" == *"nodejs"* ]]; then
			: > "$NODE_INSTALLED_MARKER"
		fi
		;;
esac
exit 0
EOF
	cat >"${stub_dir}/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >> "$INSTALL_STUB_LOG"
if [[ -n "${CURL_FAIL:-}" ]]; then
	echo "simulated curl failure" >&2
	exit 44
fi
out=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		-o) out="$2"; shift 2 ;;
		*) shift ;;
	esac
done
printf 'fake-key\n' > "$out"
EOF
	cat >"${stub_dir}/gpg" <<'EOF'
#!/usr/bin/env bash
echo "gpg $*" >> "$INSTALL_STUB_LOG"
if [[ -n "${GPG_FAIL:-}" ]]; then
	echo "simulated gpg failure" >&2
	exit 45
fi
out=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		-o) out="$2"; shift 2 ;;
		*) shift ;;
	esac
done
printf 'fake-keyring\n' > "$out"
EOF
	cat >"${stub_dir}/tee" <<'EOF'
#!/usr/bin/env bash
echo "tee $*" >> "$INSTALL_STUB_LOG"
if [[ -n "${TEE_FAIL:-}" ]]; then
	echo "simulated tee failure" >&2
	exit 46
fi
cat > "$1"
EOF
	cat >"${stub_dir}/mktemp" <<'EOF'
#!/usr/bin/env bash
echo "mktemp" >> "$INSTALL_STUB_LOG"
if [[ -n "${MKTEMP_FAIL:-}" ]]; then
	echo "simulated mktemp failure" >&2
	exit 47
fi
file="${TEST_TEMP_DIR}/tmp.$RANDOM.$RANDOM"
: > "$file"
echo "$file" >> "$MKTEMP_CREATED_LOG"
printf '%s\n' "$file"
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/npx" "${stub_dir}/corepack" \
		"${stub_dir}/sudo" "${stub_dir}/apt-get" "${stub_dir}/curl" "${stub_dir}/gpg" \
		"${stub_dir}/tee" "${stub_dir}/mktemp"
}

assert_created_temporaries_removed() {
	while IFS= read -r tmp_file; do
		[[ -n "$tmp_file" ]] || continue
		[[ ! -e "$tmp_file" ]]
	done <"$MKTEMP_CREATED_LOG"
}

@test "install-node-stack.sh exists and passes bash -n" {
	[[ -f "${INSTALL_NODE}" ]]
	run bash -n "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
}

@test "install-node-stack DRY_RUN does not mutate and prints plan" {
	# Force node/npm "missing" by building a stub PATH that exposes only the
	# external utilities the dry-plan branch needs (dirname) but neither
	# node nor npm, regardless of whether the host already has them.
	local stub_path="${TEST_TEMP_DIR}/stub_bin"
	mkdir -p "${stub_path}"
	ln -s "$(command -v dirname)" "${stub_path}/dirname"
	local bash_abs
	bash_abs="$(command -v bash)"
	run env DRY_RUN=1 PATH="${stub_path}" "${bash_abs}" "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"DRY_RUN"* ]]
	[[ "${output}" == *"NodeSource"* ]]
	[[ "${output}" == *"apt-get install -y nodejs"* ]]
	[[ "${output}" == *"Plan:"* ]]
	# Must not claim to have run apt-get.
	[[ "${output}" != *"==> Installing"* ]]
}

@test "install-node-stack simulated full install cleans temporaries and exits 0" {
	local stub_dir="${TEST_TEMP_DIR}/full-install-bin"
	make_install_stubs "$stub_dir"
	local keyring="${TEST_TEMP_DIR}/etc/apt/keyrings/nodesource.gpg"
	local source_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/nodesource.list"

	run env PATH="${stub_dir}:/usr/bin:/bin" NODESOURCE_KEYRING="$keyring" NODESOURCE_LIST="$source_list" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"NodeSource 24.x repository configured with signed-by keyring"* ]]
	[[ "${output}" == *"node v24.15.0"* ]]
	[[ "${output}" == *"runtime ready for GitNexus"* ]]
	[[ "${output}" != *"unbound variable"* ]]
	[[ "${output}" != *"tmp_key"* ]]
	[[ -f "$keyring" ]]
	[[ -f "$source_list" ]]
	assert_created_temporaries_removed
}

@test "install-node-stack preserves original failure before temporary creation" {
	local stub_dir="${TEST_TEMP_DIR}/pre-temp-fail-bin"
	SUDO_FAIL_STAGE=first-update make_install_stubs "$stub_dir"
	local keyring="${TEST_TEMP_DIR}/etc/apt/keyrings/nodesource.gpg"
	local source_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/nodesource.list"

	run env PATH="${stub_dir}:/usr/bin:/bin" SUDO_FAIL_STAGE=first-update NODESOURCE_KEYRING="$keyring" NODESOURCE_LIST="$source_list" bash "${INSTALL_NODE}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"simulated initial apt-get update failure"* ]]
	[[ "${output}" != *"unbound variable"* ]]
	[[ "${output}" != *"tmp_key"* ]]
	[[ ! -s "$MKTEMP_CREATED_LOG" ]]
}

@test "install-node-stack cleans temporaries when key download fails" {
	local stub_dir="${TEST_TEMP_DIR}/curl-fail-bin"
	CURL_FAIL=1 make_install_stubs "$stub_dir"
	local keyring="${TEST_TEMP_DIR}/etc/apt/keyrings/nodesource.gpg"
	local source_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/nodesource.list"

	run env PATH="${stub_dir}:/usr/bin:/bin" CURL_FAIL=1 NODESOURCE_KEYRING="$keyring" NODESOURCE_LIST="$source_list" bash "${INSTALL_NODE}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"could not download NodeSource signing key"* ]]
	[[ "${output}" != *"unbound variable"* ]]
	[[ "${output}" != *"tmp_key"* ]]
	assert_created_temporaries_removed
}

@test "install-node-stack cleans temporaries when gpg dearmor fails" {
	local stub_dir="${TEST_TEMP_DIR}/gpg-fail-bin"
	GPG_FAIL=1 make_install_stubs "$stub_dir"
	local keyring="${TEST_TEMP_DIR}/etc/apt/keyrings/nodesource.gpg"
	local source_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/nodesource.list"

	run env PATH="${stub_dir}:/usr/bin:/bin" GPG_FAIL=1 NODESOURCE_KEYRING="$keyring" NODESOURCE_LIST="$source_list" bash "${INSTALL_NODE}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"could not convert NodeSource signing key"* ]]
	[[ "${output}" != *"unbound variable"* ]]
	[[ "${output}" != *"tmp_key"* ]]
	assert_created_temporaries_removed
}

@test "install-node-stack cleans temporaries when source list write fails" {
	local stub_dir="${TEST_TEMP_DIR}/tee-fail-bin"
	TEE_FAIL=1 make_install_stubs "$stub_dir"
	local keyring="${TEST_TEMP_DIR}/etc/apt/keyrings/nodesource.gpg"
	local source_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/nodesource.list"

	run env PATH="${stub_dir}:/usr/bin:/bin" TEE_FAIL=1 NODESOURCE_KEYRING="$keyring" NODESOURCE_LIST="$source_list" bash "${INSTALL_NODE}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"could not write NodeSource apt source"* ]]
	[[ "${output}" != *"unbound variable"* ]]
	[[ "${output}" != *"tmp_key"* ]]
	assert_created_temporaries_removed
}

@test "install-node-stack cleans temporaries before later apt install failure" {
	local stub_dir="${TEST_TEMP_DIR}/node-install-fail-bin"
	SUDO_FAIL_STAGE=node-install make_install_stubs "$stub_dir"
	local keyring="${TEST_TEMP_DIR}/etc/apt/keyrings/nodesource.gpg"
	local source_list="${TEST_TEMP_DIR}/etc/apt/sources.list.d/nodesource.list"

	run env PATH="${stub_dir}:/usr/bin:/bin" SUDO_FAIL_STAGE=node-install NODESOURCE_KEYRING="$keyring" NODESOURCE_LIST="$source_list" bash "${INSTALL_NODE}"
	[[ "${status}" -ne 0 ]]
	[[ "${output}" == *"simulated nodejs install failure"* ]]
	[[ "${output}" != *"unbound variable"* ]]
	[[ "${output}" != *"tmp_key"* ]]
	assert_created_temporaries_removed
}

@test "install-node-stack skips when node and npm are already present" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v22.99.0";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "10.99.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"already present"* ]]
	[[ "${output}" == *"22.99.0"* ]]
	# Must not attempt to call apt-get.
	[[ "${output}" != *"==> Installing"* ]]
	[[ "${output}" != *"apt-get update"* ]]
}

@test "install-node-stack accepts Node 24 as compatible" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v24.11.1";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.6.2";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npx" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.6.2";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/corepack" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "0.34.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm" "${stub_dir}/npx" "${stub_dir}/corepack"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"v24.11.1"* ]]
	[[ "${output}" == *"satisfies >=22"* ]]
	[[ "${output}" == *"corepack in PATH"* ]]
	[[ "${output}" != *"==> Installing"* ]]
}

@test "install-node-stack with Node 24 does not call sudo apt curl gpg or mktemp" {
	local stub_dir="${TEST_TEMP_DIR}/node24-noop-bin"
	make_install_stubs "$stub_dir"
	: >"$NODE_INSTALLED_MARKER"

	run env PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Node runtime satisfies >=22 for GitNexus and AI tooling"* ]]
	[[ "${output}" != *"==> Installing"* ]]
	run grep -Eq 'sudo |apt-get |curl |gpg |mktemp' "$INSTALL_STUB_LOG"
	[[ "$status" -ne 0 ]]
	[[ ! -s "$MKTEMP_CREATED_LOG" ]]
}

@test "install-node-stack treats Node 20 as incompatible and points to NodeSource plan in dry-run" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v20.18.2";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "11.0.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"below required >=22"* ]]
	[[ "${output}" == *"signed-by=/etc/apt/keyrings/nodesource.gpg"* ]]
	[[ "${output}" == *"NodeSource is an external APT package source"* ]]
	[[ "${output}" == *"Plan:"* ]]
}

@test "install-node-stack DRY_RUN with Node 20 does not call sudo apt curl gpg or mktemp" {
	local stub_dir="${TEST_TEMP_DIR}/node20-dry-run-bin"
	make_install_stubs "$stub_dir"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Plan:"* ]]
	[[ "${output}" == *"NodeSource 24.x"* ]]
	run grep -Eq 'sudo |apt-get |curl |gpg |mktemp' "$INSTALL_STUB_LOG"
	[[ "$status" -ne 0 ]]
	[[ ! -s "$MKTEMP_CREATED_LOG" ]]
}

@test "install-node-stack DRY_RUN with node+npm present still skips the install branch" {
	local stub_dir="${TEST_TEMP_DIR}/bin"
	mkdir -p "${stub_dir}"
	cat >"${stub_dir}/node" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "v22.99.0";; *) exit 0;; esac
EOF
	cat >"${stub_dir}/npm" <<'EOF'
#!/usr/bin/env bash
case "$1" in --version) echo "10.99.0";; *) exit 0;; esac
EOF
	chmod +x "${stub_dir}/node" "${stub_dir}/npm"

	run env DRY_RUN=1 PATH="${stub_dir}:/usr/bin:/bin" bash "${INSTALL_NODE}"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"already present"* ]]
	[[ "${output}" != *"Plan:"* ]]
}

@test "install-node-stack target exists in install.mk but is not chained from install" {
	run grep -E "^install-node-stack:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	run grep -E "^install:" "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"install-node-stack"* ]]
	[[ "${output}" != *"install-agent-tools"* ]]
}
