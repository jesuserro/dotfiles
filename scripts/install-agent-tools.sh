#!/usr/bin/env bash
# Install agent validation/security CLIs that are not fully covered by APT.
#
# Contract:
#   - DRY_RUN=1 or --dry-run prints the plan and writes nothing.
#   - Existing tools are left alone unless --upgrade is passed.
#   - npm tools use the repo's user global prefix, never sudo.
#   - GitHub release tools are downloaded from official repositories and
#     verified against the release checksum file before installation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

TARGET_DIR="${HOME}/.local/bin"
NPM_PREFIX="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"
dry_run=0
upgrade=0
npm_only=0
external_only=0

usage() {
	cat <<'EOF'
Usage: scripts/install-agent-tools.sh [--dry-run] [--upgrade] [--npm-only|--external-only]

Installs/updates non-APT agent tools:
  - @ast-grep/cli through npm user prefix
  - actionlint from rhysd/actionlint GitHub Releases
  - osv-scanner from google/osv-scanner GitHub Releases
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run)
		dry_run=1
		shift
		;;
	--upgrade)
		upgrade=1
		shift
		;;
	--npm-only)
		npm_only=1
		shift
		;;
	--external-only)
		external_only=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "install-agent-tools.sh: unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

if [[ ${npm_only} -eq 1 && ${external_only} -eq 1 ]]; then
	echo "install-agent-tools.sh: --npm-only and --external-only are mutually exclusive" >&2
	exit 2
fi

dry() {
	[[ ${dry_run} -eq 1 ]] || install_is_truthy "${DRY_RUN:-}"
}

detect_arch() {
	case "$(uname -m)" in
	x86_64 | amd64) echo "amd64" ;;
	aarch64 | arm64) echo "arm64" ;;
	*) echo "" ;;
	esac
}

need_command() {
	local cmd="$1"
	if command -v "${cmd}" >/dev/null 2>&1; then
		return 0
	fi
	install_label FAIL "Missing required helper: ${cmd}"
	return 1
}

latest_tag() {
	local repo="$1"
	curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name'
}

normalize_release_version() {
	local tool="$1" version_line="${2:-}"
	version_line="$(printf '%s\n' "$version_line" | head -n 1 | tr -d '\r')"
	case "$tool" in
	actionlint)
		printf '%s\n' "$version_line" | sed -E 's/^actionlint[[:space:]]+//; s/^v//'
		;;
	osv-scanner)
		printf '%s\n' "$version_line" | sed -E 's/^osv-scanner[[:space:]]+(version:?[[:space:]]*)?//; s/^version:?[[:space:]]*//; s/^v([0-9])/\1/'
		;;
	*)
		printf '%s\n' "$version_line"
		;;
	esac
}

installed_tool_version() {
	local tool="$1"
	command -v "$tool" >/dev/null 2>&1 || return 1
	normalize_release_version "$tool" "$("$tool" --version 2>/dev/null | head -n 1)"
}

install_ast_grep() {
	echo ""
	echo "==> ast-grep (@ast-grep/cli via npm)"
	if command -v ast-grep >/dev/null 2>&1 && [[ ${upgrade} -ne 1 ]]; then
		install_label OK "ast-grep already present at $(command -v ast-grep)"
		return 0
	fi
	if ! command -v npm >/dev/null 2>&1; then
		install_label FAIL "npm is required for @ast-grep/cli. Install Node/npm with make install-node-stack."
		return 1
	fi
	if dry; then
		echo "[DRY_RUN] Would run: npm install -g --prefix=\"${NPM_PREFIX}\" @ast-grep/cli@latest"
		return 0
	fi
	mkdir -p "${NPM_PREFIX}/bin" "${NPM_PREFIX}/lib/node_modules"
	npm install -g --prefix="${NPM_PREFIX}" @ast-grep/cli@latest
	install_label OK "ast-grep installed/updated in ${NPM_PREFIX}"
}

install_actionlint() {
	echo ""
	echo "==> actionlint (official GitHub release)"
	if command -v actionlint >/dev/null 2>&1 && [[ ${upgrade} -ne 1 ]]; then
		install_label OK "actionlint already present at $(command -v actionlint)"
		return 0
	fi
	need_command curl && need_command jq && need_command tar && need_command sha256sum || return 1

	local arch tag version asset checksums_url asset_url
	arch="$(detect_arch)"
	if [[ -z "${arch}" ]]; then
		install_label FAIL "Unsupported architecture for actionlint: $(uname -m)"
		return 1
	fi
	if dry; then
		echo "[DRY_RUN] Would query latest release: https://api.github.com/repos/rhysd/actionlint/releases/latest"
		echo "[DRY_RUN] Would download actionlint_<version>_linux_${arch}.tar.gz"
		echo "[DRY_RUN] Would verify using actionlint_<version>_checksums.txt"
		echo "[DRY_RUN] Would install actionlint to ${TARGET_DIR}/actionlint"
		return 0
	fi

	local installed_version=""
	installed_version="$(installed_tool_version actionlint || true)"
	tag="$(latest_tag rhysd/actionlint)" || {
		if [[ -n "${installed_version}" ]]; then
			install_label WARN "actionlint update check failed; keeping installed version ${installed_version}"
			return 0
		fi
		install_label FAIL "Could not resolve latest actionlint release"
		return 1
	}
	version="${tag#v}"
	if [[ -n "${installed_version}" && "${installed_version}" == "${version}" ]]; then
		install_label OK "actionlint already latest: ${installed_version}"
		return 0
	fi
	if [[ -n "${installed_version}" ]]; then
		install_label INFO "actionlint update available: ${installed_version} -> ${version}"
	else
		install_label INFO "actionlint is not installed; installing latest available version ${version}"
	fi
	asset="actionlint_${version}_linux_${arch}.tar.gz"
	asset_url="https://github.com/rhysd/actionlint/releases/download/${tag}/${asset}"
	checksums_url="https://github.com/rhysd/actionlint/releases/download/${tag}/actionlint_${version}_checksums.txt"

	local tmp_dir
	tmp_dir="$(mktemp -d -t install-actionlint.XXXXXX)"
	# shellcheck disable=SC2064
	trap "rm -rf '${tmp_dir}'" EXIT INT TERM

	curl -fsSL "${asset_url}" -o "${tmp_dir}/${asset}"
	curl -fsSL "${checksums_url}" -o "${tmp_dir}/checksums.txt"
	(cd "${tmp_dir}" && grep "  ${asset}$" checksums.txt | sha256sum -c - >/dev/null)
	tar -xzf "${tmp_dir}/${asset}" -C "${tmp_dir}" actionlint
	mkdir -p "${TARGET_DIR}"
	install -m 0755 "${tmp_dir}/actionlint" "${TARGET_DIR}/actionlint"
	rm -rf "${tmp_dir}"
	trap - EXIT INT TERM
	install_label OK "actionlint ${tag} installed at ${TARGET_DIR}/actionlint"
}

install_osv_scanner() {
	echo ""
	echo "==> osv-scanner (official GitHub release)"
	if command -v osv-scanner >/dev/null 2>&1 && [[ ${upgrade} -ne 1 ]]; then
		install_label OK "osv-scanner already present at $(command -v osv-scanner)"
		return 0
	fi
	need_command curl && need_command jq && need_command sha256sum || return 1

	local arch tag asset asset_url checksums_url
	arch="$(detect_arch)"
	if [[ -z "${arch}" ]]; then
		install_label FAIL "Unsupported architecture for osv-scanner: $(uname -m)"
		return 1
	fi
	if dry; then
		echo "[DRY_RUN] Would query latest release: https://api.github.com/repos/google/osv-scanner/releases/latest"
		echo "[DRY_RUN] Would download osv-scanner_linux_${arch}"
		echo "[DRY_RUN] Would verify using osv-scanner_SHA256SUMS"
		echo "[DRY_RUN] Would install osv-scanner to ${TARGET_DIR}/osv-scanner"
		return 0
	fi

	local installed_version=""
	installed_version="$(installed_tool_version osv-scanner || true)"
	tag="$(latest_tag google/osv-scanner)" || {
		if [[ -n "${installed_version}" ]]; then
			install_label WARN "osv-scanner update check failed; keeping installed version ${installed_version}"
			return 0
		fi
		install_label FAIL "Could not resolve latest osv-scanner release"
		return 1
	}
	local version="${tag#v}"
	if [[ -n "${installed_version}" && "${installed_version}" == "${version}" ]]; then
		install_label OK "osv-scanner already latest: ${installed_version}"
		return 0
	fi
	if [[ -n "${installed_version}" ]]; then
		install_label INFO "osv-scanner update available: ${installed_version} -> ${version}"
	else
		install_label INFO "osv-scanner is not installed; installing latest available version ${version}"
	fi
	asset="osv-scanner_linux_${arch}"
	asset_url="https://github.com/google/osv-scanner/releases/download/${tag}/${asset}"
	checksums_url="https://github.com/google/osv-scanner/releases/download/${tag}/osv-scanner_SHA256SUMS"

	local tmp_dir
	tmp_dir="$(mktemp -d -t install-osv-scanner.XXXXXX)"
	# shellcheck disable=SC2064
	trap "rm -rf '${tmp_dir}'" EXIT INT TERM

	curl -fsSL "${asset_url}" -o "${tmp_dir}/${asset}"
	curl -fsSL "${checksums_url}" -o "${tmp_dir}/SHA256SUMS"
	(cd "${tmp_dir}" && grep "  ${asset}$" SHA256SUMS | sha256sum -c - >/dev/null)
	mkdir -p "${TARGET_DIR}"
	install -m 0755 "${tmp_dir}/${asset}" "${TARGET_DIR}/osv-scanner"
	rm -rf "${tmp_dir}"
	trap - EXIT INT TERM
	install_label OK "osv-scanner ${tag} installed at ${TARGET_DIR}/osv-scanner"
}

main() {
	echo "==> install-agent-tools (idempotent, checksum-verified where applicable)"
	if dry; then
		echo "[DRY_RUN] No downloads, npm installs or writes will be performed."
	fi

	local errors=0
	if [[ ${external_only} -ne 1 ]]; then
		install_ast_grep || errors=$((errors + 1))
	fi
	if [[ ${npm_only} -ne 1 ]]; then
		install_actionlint || errors=$((errors + 1))
		install_osv_scanner || errors=$((errors + 1))
	fi

	if [[ ${errors} -gt 0 ]]; then
		install_label FAIL "install-agent-tools finished with ${errors} error(s)"
		return 1
	fi
	install_label OK "install-agent-tools finished"
}

main "$@"
