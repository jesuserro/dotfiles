#!/usr/bin/env bash
# Idempotent, explicit materializer for the Excalidraw MCP.
#
# Clones yctimlin/mcp_excalidraw under ~/mcp-servers/excalidraw-mcp, installs
# its npm dependencies, runs the project's build script, and validates that
# dist/index.js exists (which is the entrypoint referenced by every MCP
# template in this repo).
#
# Contract:
#   - DRY_RUN=1: prints the plan (repo URL, target dir, build steps) and exits.
#     Nothing is cloned or installed.
#   - Idempotent: re-running on a fully-built tree updates with
#     `git pull --rebase --autostash` and re-runs the build.
#   - No sudo. Writes only under ~/mcp-servers/excalidraw-mcp.
#   - If `npm run build` succeeds but dist/index.js is missing, the script
#     stops, lists the entrypoint candidates it found (dist/, build/, bin/,
#     package.json "main"/"bin") and exits 2. We never invent a path.
#
# Pairs with: docs/MCP_TAXONOMY.md (Excalidraw row) and ai-cursor-check.sh
# (hint that points to this target when dist/index.js is missing).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"

REPO_URL="${EXCALIDRAW_MCP_REPO_URL:-https://github.com/yctimlin/mcp_excalidraw}"
TARGET_DIR="${HOME}/mcp-servers/excalidraw-mcp"
EXPECTED_ENTRY="${TARGET_DIR}/dist/index.js"

dry() {
	install_is_truthy "${DRY_RUN:-}"
}

print_header() {
	echo "==> install-mcp-excalidraw (idempotent, opt-in)"
	echo "    Repo:    ${REPO_URL}"
	echo "    Target:  ${TARGET_DIR}"
	echo "    Entry:   ${EXPECTED_ENTRY}"
	if dry; then
		echo "[DRY_RUN] No clone, no install, no build."
	fi
}

print_dry_plan() {
	echo ""
	echo "[DRY_RUN] Plan:"
	echo "  1. mkdir -p $(dirname "${TARGET_DIR}")"
	echo "  2. If ${TARGET_DIR}/.git exists:"
	echo "       git -C ${TARGET_DIR} pull --rebase --autostash"
	echo "     Else:"
	echo "       git clone ${REPO_URL} ${TARGET_DIR}"
	echo "  3. cd ${TARGET_DIR} && npm install"
	echo "  4. cd ${TARGET_DIR} && npm run build  # if 'build' script exists in package.json"
	echo "  5. Verify with: test -f ${EXPECTED_ENTRY}"
	echo ""
	echo "[DRY_RUN] Notes:"
	echo "  - This script never inflates a hand-rolled path: if the build does"
	echo "    not produce dist/index.js, it fails and lists the candidates it"
	echo "    actually found (dist/, build/, bin/, package.json main/bin)."
	echo "  - Override the upstream URL by exporting EXCALIDRAW_MCP_REPO_URL."
}

ensure_tools() {
	local missing=()
	command -v git >/dev/null 2>&1 || missing+=("git")
	command -v npm >/dev/null 2>&1 || missing+=("npm")
	if [[ ${#missing[@]} -gt 0 ]]; then
		install_label FAIL "missing tools: ${missing[*]}"
		echo "    Install them first:"
		echo "      sudo apt-get install -y git nodejs npm"
		echo "    Or, for the JS stack only: make install-node-stack"
		exit 1
	fi
}

clone_or_update() {
	mkdir -p "$(dirname "${TARGET_DIR}")"
	if [[ -d "${TARGET_DIR}/.git" ]]; then
		echo "==> Updating ${TARGET_DIR}"
		git -C "${TARGET_DIR}" pull --rebase --autostash
		return 0
	fi
	if [[ -e "${TARGET_DIR}" ]]; then
		install_label FAIL "${TARGET_DIR} exists but is not a git checkout. Refusing to overwrite."
		echo "    Move it aside (e.g. mv ${TARGET_DIR} ${TARGET_DIR}.bak) and re-run."
		exit 1
	fi
	echo "==> Cloning ${REPO_URL} into ${TARGET_DIR}"
	git clone "${REPO_URL}" "${TARGET_DIR}"
}

has_build_script() {
	# Cheap heuristic: parse package.json for a "build" script.
	local pkg="${TARGET_DIR}/package.json"
	[[ -f "${pkg}" ]] || return 1
	python3 - "${pkg}" <<'PY' >/dev/null 2>&1
import json, sys
pkg = json.load(open(sys.argv[1]))
scripts = pkg.get("scripts") or {}
sys.exit(0 if isinstance(scripts.get("build"), str) and scripts["build"].strip() else 1)
PY
}

install_and_build() {
	echo "==> npm install (in ${TARGET_DIR})"
	(cd "${TARGET_DIR}" && npm install)
	if has_build_script; then
		echo "==> npm run build (in ${TARGET_DIR})"
		(cd "${TARGET_DIR}" && npm run build)
	else
		install_label WARN "package.json has no 'build' script; skipping build step."
	fi
}

report_entrypoint_candidates() {
	echo "    Searching for actual entrypoints under ${TARGET_DIR}:"
	for sub in dist build bin lib out; do
		if [[ -d "${TARGET_DIR}/${sub}" ]]; then
			# List up to 10 .js / .mjs / .cjs files per candidate dir.
			while IFS= read -r f; do
				echo "      candidate: ${f#"${TARGET_DIR}/"}"
			done < <(find "${TARGET_DIR}/${sub}" -maxdepth 3 -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) 2>/dev/null | head -n 10)
		fi
	done
	# Also report package.json main/bin if present.
	if [[ -f "${TARGET_DIR}/package.json" ]]; then
		python3 - "${TARGET_DIR}/package.json" <<'PY' 2>/dev/null || true
import json, sys
pkg = json.load(open(sys.argv[1]))
m = pkg.get("main")
b = pkg.get("bin")
if isinstance(m, str):
    print(f"      package.json main: {m}")
if isinstance(b, str):
    print(f"      package.json bin: {b}")
elif isinstance(b, dict):
    for k, v in b.items():
        print(f"      package.json bin[{k}]: {v}")
PY
	fi
}

verify_entrypoint() {
	if [[ -f "${EXPECTED_ENTRY}" ]]; then
		install_label OK "Excalidraw MCP entrypoint present: ${EXPECTED_ENTRY}"
		return 0
	fi
	install_label FAIL "Expected entrypoint missing after build: ${EXPECTED_ENTRY}"
	report_entrypoint_candidates
	echo ""
	echo "    Action: update the MCP recipe / templates if the upstream"
	echo "    project has moved its entrypoint, then re-run this installer."
	exit 2
}

main() {
	print_header

	if dry; then
		print_dry_plan
		return 0
	fi

	ensure_tools
	clone_or_update
	install_and_build
	verify_entrypoint

	echo ""
	echo "Next steps:"
	echo "  - make ai-cursor-check    # should now show Excalidraw bundle present"
	echo "  - Restart Cursor/Codex to pick up the MCP."
}

main "$@"
