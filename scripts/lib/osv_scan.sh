#!/usr/bin/env bash
# Shared osv-scanner helpers for security gates.

is_osv_infrastructure_failure() {
	local output_file="$1"

	grep -Eiq \
		'service unavailable|connection refused|timed out|network is unreachable|failed to connect|dial tcp|no such host|temporary failure in name resolution|failed resolution|rpc error:.*unavailable|api.*unavailable|could not reach|error fetching' \
		"${output_file}"
}

has_osv_scan_inputs() {
	local root="${1:-${DOTFILES_DIR:-.}}"

	find "${root}" \
		\( -name 'package-lock.json' -o -name 'pnpm-lock.yaml' -o -name 'yarn.lock' \
		-o -name 'requirements*.txt' -o -name 'pyproject.toml' -o -name 'uv.lock' \
		-o -name 'go.mod' -o -name 'Cargo.lock' -o -name 'composer.lock' \) \
		-type f \
		! -path '*/.git/*' ! -path '*/.venv/*' ! -path '*/node_modules/*' \
		! -path '*/vendor/*' ! -path '*/__pycache__/*' \
		-print -quit | grep -q .
}

# run_osv_repo_scan ROOT [STRICT]
# Exit 0: clean scan or non-blocking infrastructure failure (when STRICT=0)
# Exit 1: vulnerability findings, missing tool, or infrastructure failure when STRICT=1
run_osv_repo_scan() {
	local root="$1"
	local strict="${2:-0}"
	local osv_output osv_status=0

	osv_output="$(mktemp "${TMPDIR:-/tmp}/osv-scan.XXXXXX")" || return 1

	osv-scanner scan source -r "${root}" >"${osv_output}" 2>&1 || osv_status=$?

	if [[ ${osv_status} -eq 0 ]] && ! is_osv_infrastructure_failure "${osv_output}"; then
		rm -f "${osv_output}"
		return 0
	fi

	if is_osv_infrastructure_failure "${osv_output}"; then
		printf 'WARN: osv-scanner remote service unavailable; dependency scan incomplete (not confirmed clean)\n' >&2
		printf '      This is not a vulnerability finding. Retry later or use SECURITY_ONLINE=1 for strict blocking.\n' >&2
		cat "${osv_output}" >&2
		rm -f "${osv_output}"
		if [[ "${strict}" == "1" ]]; then
			printf 'External dependency failure: osv-scanner service unavailable\n' >&2
			return 1
		fi
		return 0
	fi

	cat "${osv_output}" >&2
	rm -f "${osv_output}"
	return "${osv_status}"
}
