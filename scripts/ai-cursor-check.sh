#!/usr/bin/env bash
# Non-mutating readiness check: Cursor MCPs, skills, AI commands (dotfiles).
# Does not run Cursor, chezmoi apply, MCP servers, or print secret values.
# STRICT=1 promotes missing critical Cursor pieces to FAIL / exit 1.
#
# TODO: a canonical MCP manifest (e.g. ai/assets/mcps/MANIFEST.yaml) could
# drive counts and drift detection across Cursor/Codex/OpenCode from one source.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/install_common.sh
source "${SCRIPT_DIR}/lib/install_common.sh"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

HOME_ROOT="${HOME}"
CURSOR_DIR="${HOME_ROOT}/.cursor"
CURSOR_MCP="${CURSOR_DIR}/mcp.json"
CURSOR_SKILLS="${CURSOR_DIR}/skills-cursor"
CURSOR_COMMANDS="${CURSOR_DIR}/commands"
CONFIG_AI="${HOME_ROOT}/.config/ai"
VENV_PY="${CONFIG_AI}/runtime/.venv/bin/python"

CURSOR_TMPL="${DOTFILES_ROOT}/dot_cursor/mcp.json.tmpl"
CODEX_TMPL="${DOTFILES_ROOT}/dot_codex/config.toml.tmpl"
OPENCODE_TMPL="${DOTFILES_ROOT}/dot_config/opencode/opencode.json.tmpl"
SKILLS_SRC="${DOTFILES_ROOT}/ai/assets/skills"
REGISTRY="${DOTFILES_ROOT}/ai/assets/commands/registry.yaml"
VALIDATE_SKILLS="${DOTFILES_ROOT}/scripts/validate-skills-structure.sh"
EXCALIDRAW_REL="mcp-servers/excalidraw-mcp/dist/index.js"

strict_mode=0
if install_is_truthy "${STRICT:-}"; then
	strict_mode=1
fi

ok=0
warn=0
missing=0
fail=0
line() {
	local state="$1"
	local msg="$2"
	install_label "${state}" "${msg}"
	case "${state}" in
	OK) ok=$((ok + 1)) ;;
	WARN) warn=$((warn + 1)) ;;
	MISSING) missing=$((missing + 1)) ;;
	FAIL) fail=$((fail + 1)) ;;
	esac
}

line_info() {
	local msg="$1"
	printf '%-6s %s\n' "INFO" "${msg}"
}

probe_cmd_warn() {
	local label="$1"
	local cmd="$2"
	if command -v "${cmd}" >/dev/null 2>&1; then
		line OK "${label} (${cmd} in PATH)"
	else
		line WARN "${label} (${cmd} not in PATH)"
	fi
}

probe_cmd_missing_strict() {
	local label="$1"
	local cmd="$2"
	if command -v "${cmd}" >/dev/null 2>&1; then
		line OK "${label} (${cmd} in PATH)"
	else
		if [[ ${strict_mode} -eq 1 ]]; then
			line MISSING "${label} (${cmd} not in PATH; needed for several Cursor MCPs)"
		else
			line WARN "${label} (${cmd} not in PATH)"
		fi
	fi
}

file_perm_line() {
	local path="$1"
	local label="$2"
	if [[ ! -e "${path}" ]]; then
		line WARN "${label}: not found (${path})"
		return
	fi
	local mode
	mode="$(stat -c '%a' "${path}" 2>/dev/null || stat -f '%OLp' "${path}" 2>/dev/null || echo "?")"
	if [[ -f "${path}" && "${mode}" != "?" && "${mode}" != "600" && "${mode}" != "400" ]]; then
		line WARN "${label}: present but mode ${mode} (prefer 600 for secret files)"
	else
		line OK "${label}: present (${path}, mode ${mode})"
	fi
}

secret_presence_only() {
	local path="$1"
	local label="$2"
	if [[ -e "${path}" ]]; then
		file_perm_line "${path}" "${label}"
	else
		line WARN "${label}: missing (${path})"
	fi
}

# --- Embedded Python: MCP counts from templates + optional home JSON probe paths ---
mcp_stats_py() {
	python3 - "${DOTFILES_ROOT}" "${HOME_ROOT}" "${CURSOR_MCP}" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

dotfiles = Path(sys.argv[1])
home = Path(sys.argv[2])
cursor_home = Path(sys.argv[3])


def strip_chezmoi_placeholders(s: str) -> str:
    # Replace with a path-like token so JSON strings stay valid (not empty "").
    return re.sub(r"\{\{[^}]*\}\}", "/CHEZMOI_HOME", s)


def load_json_maybe_templated(path: Path):
    raw = path.read_text(encoding="utf-8")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return json.loads(strip_chezmoi_placeholders(raw))


def count_cursor_servers(data) -> int:
    return len((data or {}).get("mcpServers") or {})


def count_codex_enabled(text: str) -> int:
    """Count [mcp_servers.X] blocks with enabled = true (explicit)."""
    enabled = 0
    blocks = re.split(r"(?m)^\[mcp_servers\.[^\]]+\]\s*$", text)
    # first chunk is preamble before first mcp_servers
    for chunk in blocks[1:]:
        m = re.search(r"(?m)^enabled\s*=\s*(true|false)\s*$", chunk)
        if m and m.group(1) == "true":
            enabled += 1
    return enabled


def count_opencode_enabled(text: str) -> int:
    data = json.loads(strip_chezmoi_placeholders(text))
    mcp = (data or {}).get("mcp") or {}
    n = 0
    for _name, cfg in mcp.items():
        if isinstance(cfg, dict) and cfg.get("enabled") is True:
            n += 1
    return n


def collect_paths_from_mcp_json(data, home: str):
    out = []
    servers = (data or {}).get("mcpServers") or {}
    for _name, cfg in servers.items():
        if not isinstance(cfg, dict):
            continue
        cmd = cfg.get("command")
        if isinstance(cmd, str) and cmd.startswith("/"):
            out.append(cmd)
        for a in cfg.get("args") or []:
            if isinstance(a, str) and a.startswith("/") and not a.startswith("/usr"):
                out.append(a)
            elif isinstance(a, str) and a.startswith(home + "/"):
                out.append(a)
            elif isinstance(a, str) and a.startswith("/mnt/"):
                out.append(a)
            elif isinstance(a, str) and a.startswith("/home/"):
                out.append(a)
        # Heuristic: -lc string may contain exec /path
        for a in cfg.get("args") or []:
            if isinstance(a, str) and "exec " in a:
                for m in re.finditer(r"exec\s+(\S+)", a):
                    p = m.group(1)
                    if p.startswith("/"):
                        out.append(p)
    return out


cursor_t = dotfiles / "dot_cursor" / "mcp.json.tmpl"
codex_t = dotfiles / "dot_codex" / "config.toml.tmpl"
opencode_t = dotfiles / "dot_config" / "opencode" / "opencode.json.tmpl"

cursor_tpl_n = 0
if cursor_t.is_file():
    cursor_tpl_n = count_cursor_servers(load_json_maybe_templated(cursor_t))

codex_en = 0
if codex_t.is_file():
    codex_en = count_codex_enabled(codex_t.read_text(encoding="utf-8"))

opencode_en = 0
if opencode_t.is_file():
    opencode_en = count_opencode_enabled(opencode_t.read_text(encoding="utf-8"))

home_n = -1
home_paths = []
home_err = ""
if cursor_home.is_file():
    try:
        hd = json.loads(cursor_home.read_text(encoding="utf-8"))
        home_n = count_cursor_servers(hd)
        home_paths = collect_paths_from_mcp_json(hd, str(home))
    except Exception as exc:  # noqa: BLE001
        home_err = str(exc)
else:
    home_err = "missing_file"

print(
    json.dumps(
        {
            "cursor_template_count": cursor_tpl_n,
            "codex_enabled_count": codex_en,
            "opencode_enabled_count": opencode_en,
            "cursor_home_count": home_n,
            "cursor_home_error": home_err,
            "cursor_home_paths": home_paths,
        }
    )
)
PY
}

# --- Section 1: Runtime AI ---
echo "==> 1. Runtime AI (non-destructive)"
if [[ -x "${VENV_PY}" ]]; then
	line OK "AI runtime venv python present (${VENV_PY})"
elif [[ -d "$(dirname "${VENV_PY}")" ]]; then
	line_info "AI runtime venv python not found (Cursor global MCPs may still work without it): ${VENV_PY}"
else
	line_info "AI runtime venv dir not created yet (~/.config/ai/runtime/.venv) — optional for Cursor-only"
fi

probe_cmd_warn "uv (preferred Python tool)" "uv"
probe_cmd_warn "uvx (uv tool runner)" "uvx"
probe_cmd_missing_strict "node (used by several Cursor MCPs)" "node"
probe_cmd_missing_strict "npx (used by several Cursor MCPs)" "npx"

excal_path="${HOME_ROOT}/${EXCALIDRAW_REL}"
if [[ -f "${CURSOR_MCP}" ]]; then
	if python3 -c "import json; d=json.load(open('${CURSOR_MCP}')); exit(0 if 'excalidraw' in d.get('mcpServers',{}) else 1)" 2>/dev/null; then
		if [[ -f "${excal_path}" ]]; then
			line OK "Excalidraw MCP bundle present (${excal_path})"
		else
			line MISSING "Excalidraw MCP bundle missing (${excal_path}) but excalidraw is in ~/.cursor/mcp.json"
		fi
	else
		line_info "Excalidraw entry not in ~/.cursor/mcp.json — skipping excalidraw path check"
	fi
else
	line_info "No ~/.cursor/mcp.json — skipping excalidraw path check"
fi

echo ""
echo "==> 2. Skills (repo + validate-skills-structure)"
if [[ -d "${SKILLS_SRC}" ]]; then
	categories=0
	skill_md=0
	while IFS= read -r -d '' d; do
		categories=$((categories + 1))
	done < <(find "${SKILLS_SRC}" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
	skill_md="$(find "${SKILLS_SRC}" -name 'SKILL.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
	line OK "Skills source tree present (${SKILLS_SRC})"
	line_info "Skill categories (top-level under skills): ${categories}, SKILL.md files: ${skill_md}"
	# Brief ops listing (max 12 names)
	ops_dir="${SKILLS_SRC}/ops"
	if [[ -d "${ops_dir}" ]]; then
		mapfile -t ops_skills < <(find "${ops_dir}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort | head -n 12)
		if [[ ${#ops_skills[@]} -gt 0 ]]; then
			line_info "Sample ops skills: ${ops_skills[*]}"
		fi
	fi
else
	line FAIL "Skills directory missing: ${SKILLS_SRC}"
fi

if [[ -x "${VALIDATE_SKILLS}" ]]; then
	set +e
	sk_out="$("${VALIDATE_SKILLS}" 2>&1)"
	sk_st=$?
	set -e
	# shellcheck disable=SC2001
	sk_summary="$(printf '%s\n' "${sk_out}" | tail -n 8)"
	printf '%s\n' "${sk_summary}"
	if [[ ${sk_st} -ne 0 ]]; then
		line FAIL "validate-skills-structure.sh exited ${sk_st}"
	else
		if printf '%s\n' "${sk_out}" | grep -q 'Warnings:' && printf '%s\n' "${sk_out}" | grep 'Warnings:' | grep -qv 'Warnings: *0'; then
			line WARN "validate-skills-structure reported warnings (see output above)"
		else
			line OK "validate-skills-structure.sh passed"
		fi
	fi
else
	line WARN "validate-skills-structure.sh not found or not executable: ${VALIDATE_SKILLS}"
fi

echo ""
echo "==> 3. AI assets linked (expected after chezmoi run_after_11)"
for pair in \
	"${CONFIG_AI}/skills|${SKILLS_SRC}" \
	"${CONFIG_AI}/prompts|${DOTFILES_ROOT}/ai/assets/prompts" \
	"${CONFIG_AI}/rules|${DOTFILES_ROOT}/ai/assets/rules"; do
	link="${pair%%|*}"
	want="${pair##*|}"
	if [[ -L "${link}" ]]; then
		resolved="$(readlink -f "${link}" 2>/dev/null || true)"
		want_abs="$(readlink -f "${want}" 2>/dev/null || true)"
		if [[ -n "${resolved}" && "${resolved}" == "${want_abs}" ]]; then
			line OK "Symlink OK: ${link} -> ${want}"
		else
			line WARN "Symlink present but target mismatch: ${link} (resolved=${resolved}, expected=${want_abs})"
		fi
	elif [[ -e "${link}" ]]; then
		line WARN "Path exists but is not a symlink (expected symlink from chezmoi): ${link}"
	else
		line MISSING "Expected hub symlink missing: ${link} (run chezmoi apply if you use this machine)"
	fi
	if [[ -L "${link}" ]] && [[ ! -e "${link}" ]]; then
		line WARN "Dangling symlink: ${link}"
	fi
done

if [[ -d "${CURSOR_SKILLS}" ]]; then
	line OK "Cursor skills surface directory exists (${CURSOR_SKILLS})"
	while IFS= read -r -d '' catdir; do
		name="$(basename "${catdir}")"
		[[ "${name}" == .* ]] && continue
		target="${CURSOR_SKILLS}/${name}"
		if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
			if [[ -L "${target}" ]] && [[ ! -e "${target}" ]]; then
				line WARN "Dangling symlink in Cursor skills: ${target}"
			fi
		else
			line MISSING "Category not published to ~/.cursor/skills-cursor/: ${name} (expected ${target})"
		fi
	done < <(find "${SKILLS_SRC}" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
else
	line WARN "Cursor skills surface missing: ${CURSOR_SKILLS}"
fi

echo ""
echo "==> 4. AI commands materialized for Cursor"
if command -v python3 >/dev/null 2>&1; then
	set +e
	cmd_ids="$(
		python3 - "${REGISTRY}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.is_file():
    print("")
    sys.exit(0)
try:
    import yaml  # type: ignore
except ImportError:
    print("")
    sys.exit(0)

data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
for c in data.get("commands") or []:
    if not c.get("enabled"):
        continue
    plats = c.get("platforms") or []
    if "cursor" in plats:
        cid = c.get("id")
        if cid:
            print(cid)
PY
	)"
	set -e
	if [[ ! -f "${REGISTRY}" ]]; then
		line WARN "Commands registry missing: ${REGISTRY}"
	elif [[ -z "${cmd_ids}" ]]; then
		line WARN "Could not list Cursor commands from registry (install PyYAML or check registry.yaml)"
	else
		while IFS= read -r cid; do
			[[ -z "${cid}" ]] && continue
			f="${CURSOR_COMMANDS}/${cid}.md"
			if [[ -f "${f}" ]]; then
				line OK "Cursor command present: ${f}"
			else
				line MISSING "Cursor command missing for registry id '${cid}': ${f}"
			fi
		done <<<"${cmd_ids}"
	fi
else
	line WARN "python3 not available — skipping registry-based command checks"
fi

echo ""
echo "==> 5. MCPs (Cursor template vs home; other surfaces INFO only)"
if [[ ! -f "${CURSOR_TMPL}" ]]; then
	line FAIL "Cursor MCP template missing: ${CURSOR_TMPL}"
fi

stats_json="$(mcp_stats_py 2>/dev/null || echo '{}')"
ct="$(printf '%s' "${stats_json}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('cursor_template_count',0))" 2>/dev/null || echo 0)"
ce="$(printf '%s' "${stats_json}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('codex_enabled_count',0))" 2>/dev/null || echo 0)"
oe="$(printf '%s' "${stats_json}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('opencode_enabled_count',0))" 2>/dev/null || echo 0)"
hn="$(printf '%s' "${stats_json}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('cursor_home_count',-1))" 2>/dev/null || echo -1)"
herr="$(printf '%s' "${stats_json}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('cursor_home_error',''))" 2>/dev/null || echo "")"

if [[ "${hn}" -ge 0 ]]; then
	line_info "MCP surfaces (from repo templates; asymmetry is expected): Cursor template=${ct}, Cursor home=${hn}, Codex enabled=${ce}, OpenCode enabled=${oe}"
else
	line_info "MCP surfaces (from repo templates; asymmetry is expected): Cursor template=${ct}, Cursor home=(no ~/.cursor/mcp.json), Codex enabled=${ce}, OpenCode enabled=${oe}"
fi
line_info "TODO: canonical MCP manifest under ai/assets/mcps/ would unify surfaces in a future phase"

if [[ ! -f "${CURSOR_MCP}" ]]; then
	line MISSING "~/.cursor/mcp.json missing (chezmoi apply likely not run for Cursor MCPs)"
elif [[ -n "${herr}" && "${herr}" != "missing_file" ]]; then
	line FAIL "~/.cursor/mcp.json is not valid JSON: ${herr}"
else
	line OK "~/.cursor/mcp.json present and valid JSON"
	if [[ "${hn}" -ge 0 && "${ct}" -gt 0 && "${hn}" -ne "${ct}" ]]; then
		line WARN "Cursor MCP count mismatch: home=${hn} template=${ct} (re-run chezmoi apply if you changed dot_cursor/mcp.json.tmpl)"
	fi
fi

# Soft path checks from rendered home json
if [[ -f "${CURSOR_MCP}" ]] && python3 -c "import json; json.load(open('${CURSOR_MCP}'))" 2>/dev/null; then
	while IFS= read -r p; do
		[[ -z "${p}" ]] && continue
		if [[ -f "${p}" ]] || [[ -x "${p}" ]]; then
			line_info "MCP path exists: ${p}"
		elif [[ "${p}" == /mnt/* ]] && [[ ! -e "${p}" ]]; then
			line WARN "MCP path not found (WSL/host path?): ${p}"
		else
			line MISSING "MCP path missing on disk: ${p}"
		fi
	done < <(python3 - "${CURSOR_MCP}" "${HOME_ROOT}" <<'PY'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
home = Path(sys.argv[2])
data = json.loads(path.read_text(encoding="utf-8"))
seen = set()

def add(p: str):
    p = p.strip()
    if p.startswith("/") and p not in seen:
        seen.add(p)

for _name, cfg in (data.get("mcpServers") or {}).items():
    if not isinstance(cfg, dict):
        continue
    cmd = cfg.get("command")
    if isinstance(cmd, str):
        if cmd.startswith("/"):
            add(cmd)
        elif cmd in ("bash", "sh"):
            pass
    for a in cfg.get("args") or []:
        if not isinstance(a, str):
            continue
        if a.startswith("/usr/") or a.startswith(str(home) + "/") or a.startswith("/mnt/") or a.startswith("/home/"):
            add(a)
        for m in re.finditer(r"(?:^|\s)(/home/\S+|/mnt/\S+|/\S+\.py)\b", a):
            cand = m.group(1)
            if cand.endswith(";"):
                cand = cand[:-1]
            if Path(cand).suffix == ".py" or "/bin/" in cand or cand.startswith("/home/") or cand.startswith("/mnt/"):
                add(cand)

for p in sorted(seen):
    print(p)
PY
	)
fi

echo ""
echo "==> 6. Cursor config (HOME)"
if [[ -f "${CURSOR_MCP}" ]]; then
	line OK "Cursor MCP config file: ${CURSOR_MCP}"
else
	line_info "Cursor MCP config file absent: ${CURSOR_MCP}"
fi
if [[ -d "${CURSOR_SKILLS}" ]]; then
	line OK "Cursor skills-cursor directory: ${CURSOR_SKILLS}"
else
	line WARN "Cursor skills-cursor directory missing: ${CURSOR_SKILLS}"
fi
if [[ -d "${CURSOR_COMMANDS}" ]]; then
	line OK "Cursor commands directory: ${CURSOR_COMMANDS}"
else
	line WARN "Cursor commands directory missing: ${CURSOR_COMMANDS}"
fi
line_info "Cursor settings/rules: not managed by dotfiles (this repo's .cursor/ is checkout-local; Cursor reads ~/.cursor/settings.json etc.)"
line_info "dotfiles/.cursor/ in the repo is not necessarily published to HOME — use chezmoi-managed paths under dot_cursor/"

echo ""
echo "==> 7. Secrets (presence and permissions only; never print values)"
secret_presence_only "${HOME_ROOT}/.config/mcp-secrets.env" "mcp-secrets.env"
if [[ -L "${HOME_ROOT}/.secrets/codex.env" ]] || [[ -f "${HOME_ROOT}/.secrets/codex.env" ]]; then
	line OK "~/.secrets/codex.env present (symlink or file)"
else
	line WARN "~/.secrets/codex.env missing (github MCP in Cursor sources this for tokens)"
fi
if [[ -f "${HOME_ROOT}/.config/sops/age/keys.txt" ]]; then
	line OK "SOPS age key file present"
else
	line WARN "SOPS age key file missing (~/.config/sops/age/keys.txt) — secrets generation may be incomplete"
fi

# If github MCP is in home config, nudge about secrets in STRICT
if [[ -f "${CURSOR_MCP}" ]] && python3 -c "import json; d=json.load(open('${CURSOR_MCP}')); exit(0 if 'github' in d.get('mcpServers',{}) else 1)" 2>/dev/null; then
	if [[ ! -f "${HOME_ROOT}/.secrets/codex.env" && ! -L "${HOME_ROOT}/.secrets/codex.env" ]]; then
		if [[ ${strict_mode} -eq 1 ]]; then
			line MISSING "github MCP enabled in ~/.cursor/mcp.json but ~/.secrets/codex.env missing"
		fi
	fi
fi

echo ""
echo "=== Summary ==="
printf 'Counters: OK=%s WARN=%s MISSING=%s FAIL=%s\n' "${ok}" "${warn}" "${missing}" "${fail}"

overall="PASS"
if [[ ${fail} -gt 0 ]]; then
	overall="FAIL"
elif [[ ${warn} -gt 0 || ${missing} -gt 0 ]]; then
	overall="PASS_WITH_WARNINGS"
fi

# STRICT promotions
if [[ ${strict_mode} -eq 1 ]]; then
	if [[ ! -f "${CURSOR_MCP}" ]]; then
		overall="FAIL"
	fi
	if [[ ${fail} -gt 0 ]]; then
		overall="FAIL"
	fi
	if [[ -f "${CURSOR_MCP}" ]]; then
		if ! python3 -c "import json; json.load(open('${CURSOR_MCP}'))" 2>/dev/null; then
			overall="FAIL"
		fi
		if [[ "${hn}" -ge 0 && "${ct}" -gt 0 && "${hn}" -ne "${ct}" ]]; then
			overall="FAIL"
		fi
	fi
	if command -v node >/dev/null 2>&1; then
		: # ok
	else
		overall="FAIL"
	fi
	if command -v npx >/dev/null 2>&1; then
		: # ok
	else
		overall="FAIL"
	fi
fi

printf '\nCursor readiness: %s' "${overall}"
if [[ ${strict_mode} -eq 1 ]]; then
	printf ' (STRICT=1)\n'
else
	printf '\n'
fi

if [[ "${overall}" == "FAIL" ]]; then
	exit 1
fi
exit 0
