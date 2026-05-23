#!/usr/bin/env bash
# Idempotent, explicit materializer for the GitHub MCP wrapper.
#
# What this installs:
#   ~/.local/bin/codex-mcp-github — a small Bash launcher referenced by every
#   Chezmoi MCP template (Cursor, Codex, OpenCode). The wrapper exists so the
#   GitHub token never appears in mcp.json: it sources ~/.config/mcp-secrets.env
#   first, falls back to ~/.secrets/codex.env, validates that a token is set,
#   and execs the canonical GitHub MCP.
#
# Contract:
#   - DRY_RUN=1: prints the wrapper that would be written and exits.
#   - Never sudo. Writes only to ~/.local/bin/codex-mcp-github.
#   - Idempotent: if the wrapper already matches the canonical body, do nothing.
#     Otherwise, overwrites with a single atomic mv.
#   - Never writes to ~/.secrets/* nor reads token values.
#   - The materialized wrapper itself:
#       * sources ~/.config/mcp-secrets.env when present (set -a / set +a),
#         or ~/.secrets/codex.env as the compatibility fallback,
#       * accepts GITHUB_PERSONAL_ACCESS_TOKEN or GITHUB_TOKEN,
#       * fails with exit 2 and a clear message (no token value printed) when
#         neither is set,
#       * execs `npx -y @modelcontextprotocol/server-github` once the token is
#         exported as GITHUB_PERSONAL_ACCESS_TOKEN (which is the env var the
#         upstream server reads).
#
# Pairs with: docs/MCP_TAXONOMY.md (GitHub MCP wrapper) and ai-cursor-check.sh
# (which separately reports wrapper-missing vs token-missing).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

TARGET_DIR="${HOME}/.local/bin"
TARGET_PATH="${TARGET_DIR}/codex-mcp-github"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

# The canonical wrapper body. Kept as a single heredoc so DRY_RUN can show the
# exact file we would write. Update this and re-run install-mcp-github to roll
# the wrapper forward; the script will rewrite atomically when the content
# differs.
wrapper_body() {
	cat <<'WRAPPER'
#!/usr/bin/env bash
# codex-mcp-github — wrapper that injects the GitHub token from the canonical
# MCP secrets file and execs the canonical GitHub MCP server. Managed by dotfiles
# (scripts/install-mcp-github.sh); do not edit by hand. The wrapper never
# prints the token, only the variable names it expects.
set -euo pipefail

CANONICAL_SECRETS_FILE="${HOME}/.config/mcp-secrets.env"
COMPAT_SECRETS_FILE="${HOME}/.secrets/codex.env"
SECRETS_FILE=""
if [[ -f "${CANONICAL_SECRETS_FILE}" ]]; then
	SECRETS_FILE="${CANONICAL_SECRETS_FILE}"
elif [[ -f "${COMPAT_SECRETS_FILE}" ]]; then
	SECRETS_FILE="${COMPAT_SECRETS_FILE}"
fi

if [[ -n "${SECRETS_FILE}" ]]; then
	# shellcheck disable=SC1090
	set -a
	. "${SECRETS_FILE}"
	set +a
fi

token="${GITHUB_PERSONAL_ACCESS_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "${token}" ]]; then
	echo "codex-mcp-github: missing GITHUB_PERSONAL_ACCESS_TOKEN (or GITHUB_TOKEN)." >&2
	echo "                  Set it in ~/.config/mcp-secrets.env (or the legacy" >&2
	echo "                  ~/.secrets/codex.env adapter); never" >&2
	echo "                  print the value). Then re-run the MCP from Cursor/Codex." >&2
	exit 2
fi

export GITHUB_PERSONAL_ACCESS_TOKEN="${token}"

if ! command -v npx >/dev/null 2>&1; then
	echo "codex-mcp-github: npx not in PATH. Install the Node.js stack first:" >&2
	echo "                  make install-node-stack   # NodeSource 24.x, Node >=22 policy" >&2
	exit 127
fi

exec npx -y @modelcontextprotocol/server-github
WRAPPER
}

print_header() {
	echo "==> install-mcp-github (idempotent, opt-in)"
	echo "    Target: ${TARGET_PATH}"
	if dry; then
		echo "[DRY_RUN] No files will be written. Below is the wrapper body that"
		echo "          would be materialized at the target path:"
	fi
}

print_dry_plan() {
	echo ""
	echo "----- BEGIN wrapper body -----"
	wrapper_body
	echo "----- END wrapper body -----"
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. mkdir -p ${TARGET_DIR}"
	echo "  2. Write the wrapper above to ${TARGET_PATH}"
	echo "  3. chmod 755 ${TARGET_PATH}"
	echo "  4. Verify with: test -x ${TARGET_PATH}"
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - The wrapper sources ~/.config/mcp-secrets.env at runtime, falling"
	echo "    back to ~/.secrets/codex.env; this script never reads or prints"
	echo "    either file's content."
	echo "  - Without a token, the wrapper exits 2 with a clear message and no"
	echo "    secret material in the output."
	echo "  - Without npx in PATH, the wrapper exits 127 and hints at"
	echo "    'make install-node-stack'."
}

write_wrapper() {
	mkdir -p "${TARGET_DIR}"
	local tmp
	tmp="$(mktemp "${TARGET_DIR}/.codex-mcp-github.XXXXXX")"
	# shellcheck disable=SC2064
	trap "rm -f '${tmp}'" EXIT INT TERM
	wrapper_body >"${tmp}"
	chmod 755 "${tmp}"
	mv "${tmp}" "${TARGET_PATH}"
	trap - EXIT INT TERM
}

main() {
	print_header

	if dry; then
		print_dry_plan
		return 0
	fi

	if [[ -f "${TARGET_PATH}" ]]; then
		# Compare to the canonical body to stay idempotent.
		if diff -q <(wrapper_body) "${TARGET_PATH}" >/dev/null 2>&1; then
			install_label OK "codex-mcp-github already present and up to date (${TARGET_PATH})"
		else
			install_label WARN "codex-mcp-github differs from canonical body; rewriting (${TARGET_PATH})"
			write_wrapper
			install_label OK "codex-mcp-github updated (${TARGET_PATH})"
		fi
	else
		write_wrapper
		install_label OK "codex-mcp-github installed (${TARGET_PATH})"
	fi

	echo ""
	echo "Next steps (no secrets are read by this script):"
	echo "  1. Ensure GITHUB_PERSONAL_ACCESS_TOKEN is materialized in ~/.config/mcp-secrets.env."
	echo "  2. Run 'make ai-cursor-check' to see wrapper-presence vs token-presence."
	echo "  3. Restart Cursor/Codex to pick up the wrapper."
}

main "$@"
