#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: github-identity-check [--offline|--online] [--warn-only|--strict]

Read-only diagnostic for GitHub identity, repository remotes, and token
environment variables that can affect gh.

Options:
  --offline    Do not call gh network commands (default)
  --online     Query gh effective login and repo permission when available
  --warn-only  Report warnings without failing (default)
  --strict     Return non-zero when a FAIL is detected
  --help       Show this help
EOF
}

mode="offline"
strict=0
warnings=0
failures=0

warn() {
	warnings=$((warnings + 1))
	printf 'WARN: %s\n' "$*"
}

fail() {
	failures=$((failures + 1))
	printf 'FAIL: %s\n' "$*"
}

ok() {
	printf 'OK: %s\n' "$*"
}

info() {
	printf 'INFO: %s\n' "$*"
}

normalize_github_repo() {
	local value="${1%.git}"
	case "${value}" in
	git@github.com:*)
		value="${value#git@github.com:}"
		;;
	ssh://git@github.com/*)
		value="${value#ssh://git@github.com/}"
		;;
	https://github.com/*)
		value="${value#https://github.com/}"
		;;
	http://github.com/*)
		value="${value#http://github.com/}"
		;;
	esac
	printf '%s\n' "${value}"
}

git_config_value() {
	git config --get "$1" 2>/dev/null || true
}

git_remote_url() {
	git remote get-url "$1" 2>/dev/null || true
}

load_machine_config() {
	local config="${HOME}/.config/dotfiles/github-identity.env"
	if [[ -f "${config}" ]]; then
		# shellcheck disable=SC1090
		source "${config}"
		info "Loaded config: ${config}"
	else
		info "No machine config: ${config}"
	fi
}

report_token() {
	local name="$1"
	if [[ -n "${!name+x}" ]]; then
		warn "${name}=<set>; this can alter the effective identity used by GitHub CLI. Suggested manual action: unset GH_TOKEN GITHUB_TOKEN"
	else
		ok "${name} unset"
	fi
}

infer_profile() {
	local origin="$1"
	local upstream="$2"
	if [[ "${origin}" == "jesuserro/dotfiles" ]]; then
		printf 'personal/casa\n'
	elif [[ "${origin}" == "jesus-ixatu/dotfiles" && "${upstream}" == "jesuserro/dotfiles" ]]; then
		printf 'oficina/fork\n'
	else
		printf 'unknown\n'
	fi
}

check_expected_remote() {
	local label="$1"
	local actual="$2"
	local expected="$3"
	[[ -n "${expected}" ]] || return 0

	local normalized_expected
	normalized_expected="$(normalize_github_repo "${expected}")"
	info "Expected ${label}: ${normalized_expected}"
	if [[ "${actual}" == "${normalized_expected}" ]]; then
		ok "${label} matches expectation"
	else
		fail "${label} mismatch: expected ${normalized_expected}, got ${actual:-<unset>}"
	fi
}

online_checks() {
	local origin="$1"
	local expected_login="${DOTFILES_GITHUB_EXPECTED_LOGIN:-}"

	if ! command -v gh >/dev/null 2>&1; then
		fail "gh is required for --online but is not in PATH"
		return
	fi

	local login=""
	if login="$(gh api user --jq .login 2>/dev/null)"; then
		info "gh effective login: ${login}"
		if [[ -n "${expected_login}" ]]; then
			info "Expected login: ${expected_login}"
			if [[ "${login}" == "${expected_login}" ]]; then
				ok "gh login matches expectation"
			else
				fail "gh login mismatch: expected ${expected_login}, got ${login}"
			fi
		fi
	else
		warn "Unable to query gh effective login"
	fi

	if [[ -n "${origin}" ]]; then
		local repo_view=""
		if repo_view="$(gh repo view "${origin}" --json nameWithOwner,viewerPermission --jq '"\(.nameWithOwner) viewerPermission=\(.viewerPermission)"' 2>/dev/null)"; then
			info "gh repo view: ${repo_view}"
		else
			warn "Unable to query gh repo view for ${origin}"
		fi
	fi
}

while (($#)); do
	case "$1" in
	--offline)
		mode="offline"
		;;
	--online)
		mode="online"
		;;
	--warn-only)
		strict=0
		;;
	--strict)
		strict=1
		;;
	--help | -h)
		usage
		exit 0
		;;
	*)
		usage >&2
		exit 2
		;;
	esac
	shift
done

load_machine_config

printf 'GitHub identity diagnostic (read-only)\n'
info "hostname: $(hostname 2>/dev/null || printf unknown)"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
	info "git repo: ${repo_root:-<unknown>}"
else
	repo_root=""
	warn "Current directory is not inside a git work tree"
fi

origin_url="$(git_remote_url origin)"
upstream_url="$(git_remote_url upstream)"
origin_repo="$(normalize_github_repo "${origin_url}")"
upstream_repo="$(normalize_github_repo "${upstream_url}")"

info "origin: ${origin_url:-<unset>}"
info "upstream: ${upstream_url:-<unset>}"
info "git user.name: $(git_config_value user.name)"
info "git user.email: $(git_config_value user.email)"

report_token GH_TOKEN
report_token GITHUB_TOKEN

if command -v gh >/dev/null 2>&1; then
	ok "gh available"
else
	warn "gh unavailable; offline diagnostics can still run"
fi

profile="$(infer_profile "${origin_repo}" "${upstream_repo}")"
if [[ "${profile}" == "unknown" ]]; then
	warn "Unable to infer profile from remotes; expected personal jesuserro/dotfiles or office fork jesus-ixatu/dotfiles with upstream jesuserro/dotfiles"
else
	ok "Inferred profile: ${profile}"
fi

if [[ -n "${DOTFILES_GITHUB_IDENTITY_PROFILE:-}" ]]; then
	info "Configured profile: ${DOTFILES_GITHUB_IDENTITY_PROFILE}"
fi
check_expected_remote "origin" "${origin_repo}" "${DOTFILES_GITHUB_EXPECTED_ORIGIN:-}"
check_expected_remote "upstream" "${upstream_repo}" "${DOTFILES_GITHUB_EXPECTED_UPSTREAM:-}"

if [[ "${mode}" == "online" ]]; then
	online_checks "${origin_repo}"
else
	info "offline mode: skipping gh api and gh repo view"
fi

info "Summary: warnings=${warnings} failures=${failures}"
if [[ "${strict}" -eq 1 && "${failures}" -gt 0 ]]; then
	exit 1
fi
exit 0
