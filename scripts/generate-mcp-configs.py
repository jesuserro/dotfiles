#!/usr/bin/env python3
"""
Dry-run and productive MCP config generation from ai/assets/mcps/MANIFEST.yaml + Python recipes.

Subcommands:
  render   — write build/mcps/* (does not touch Chezmoi templates)
  drift    — compare renders + manifest intent vs current templates; classify drift
  generate — plan only unless --apply: then validate → render → write templates → drift (no unexpected)

Chezmoi placeholders must appear literally; never use str.format on strings containing {{.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Mapping, MutableMapping, Optional, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent
CHEZMOI_PREAMBLE_LINE = re.compile(r"^\{\{-.*?-\}\}\s*$")
DEFAULT_MANIFEST = REPO_ROOT / "ai" / "assets" / "mcps" / "MANIFEST.yaml"
BUILD_MCPS = REPO_ROOT / "build" / "mcps"
OUT_CURSOR = BUILD_MCPS / "dot_cursor" / "mcp.json.tmpl"
OUT_CODEX = BUILD_MCPS / "dot_codex" / "mcp_servers.toml.tmpl"
OUT_OPENCODE = BUILD_MCPS / "dot_config" / "opencode" / "opencode.json.tmpl"
OUT_DRIFT_JSON = BUILD_MCPS / "drift-report.json"
BACKUP_ROOT = BUILD_MCPS / "backups"

TMPL_CURSOR = REPO_ROOT / "dot_cursor" / "mcp.json.tmpl"
TMPL_CODEX = REPO_ROOT / "dot_codex" / "config.toml.tmpl"
TMPL_OPENCODE = REPO_ROOT / "dot_config" / "opencode" / "opencode.json.tmpl"

# Literal Chezmoi template fragments (do not pass through str.format)
H = "{{ .chezmoi.homeDir }}"
# {{ .chezmoi.sourceDir }} — add to recipes only as literal string when needed (never str.format).
# Obsidian mcpvault vault root — set in .chezmoi.toml [data.ai] obsidian_vault_path (override locally).
OBSIDIAN_VAULT_TMPL = "{{ .ai.obsidian_vault_path }}"
# Productive Chezmoi templates define $excalidrawWorkspaceHost at file top (see dot_*/*.tmpl).
EXCALIDRAW_WORKSPACE_HOST_TMPL = "{{ $excalidrawWorkspaceHost }}"
EXCALIDRAW_WORKSPACE_CONTAINER = "/workspace/excalidraw"

SURFACES = ("cursor", "codex", "opencode")


def strip_chezmoi_template_preamble(text: str) -> str:
    """Drop leading Chezmoi {{ ... }} lines so JSON/TOML parsers can read productive templates."""
    lines = text.splitlines(keepends=True)
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        if stripped == "" or CHEZMOI_PREAMBLE_LINE.match(stripped):
            i += 1
            continue
        break
    return "".join(lines[i:])


def _need_yaml():
    try:
        import yaml  # type: ignore noqa: PLC0415

        return yaml
    except ImportError:
        print(
            "FAIL PyYAML is required: pip install pyyaml "
            "(or apt install python3-yaml on Debian/Ubuntu)",
            file=sys.stderr,
        )
        raise SystemExit(2)


def load_manifest(path: Path) -> Tuple[Dict[str, Any], List[Dict[str, Any]]]:
    yaml = _need_yaml()
    doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(doc, dict):
        raise ValueError("manifest root must be a mapping")
    mcps = doc.get("mcps")
    if not isinstance(mcps, list):
        raise ValueError("manifest mcps must be a list")
    return doc, mcps


def manifest_surface_enabled(entry: Mapping[str, Any], surface: str) -> bool:
    surfaces = entry.get("surfaces") or {}
    if not isinstance(surfaces, dict):
        return False
    cfg = surfaces.get(surface)
    if not isinstance(cfg, dict):
        return False
    return bool(cfg.get("enabled")) is True


def manifest_ids(mcps: List[Dict[str, Any]]) -> Set[str]:
    out: Set[str] = set()
    for e in mcps:
        mid = e.get("id")
        if isinstance(mid, str):
            out.add(mid)
    return out


def count_manifest_surface_enabled(mcps: List[Dict[str, Any]], surface: str) -> int:
    return sum(1 for e in mcps if isinstance(e, dict) and manifest_surface_enabled(e, surface))


_RE_MCP_SERVERS_HEADER = re.compile(r"(?m)^\[mcp_servers\.[^\]]+\]\s*$")
_RE_PLUGINS_HEADER = re.compile(r"(?m)^\[plugins\.[^\]]+\]\s*$")


def merge_codex_productive(full_toml: str, mcp_fragment: str) -> str:
    """
    Replace every [mcp_servers.*] block (and nested [mcp_servers.*.env]) with mcp_fragment,
    preserving preamble before the first [mcp_servers. and any trailing [plugins.*] section.
    """
    m0 = _RE_MCP_SERVERS_HEADER.search(full_toml)
    if not m0:
        raise ValueError("Codex template: no [mcp_servers.*] section found")
    preamble = full_toml[: m0.start()]
    m1 = _RE_PLUGINS_HEADER.search(full_toml, m0.start())
    if m1:
        tail = full_toml[m1.start() :]
    else:
        tail = ""
    frag = mcp_fragment.strip()
    if frag:
        frag = frag + "\n" if not frag.endswith("\n") else frag
    body = preamble.rstrip() + "\n\n" + frag
    if tail.strip():
        body = body.rstrip() + "\n\n" + tail.lstrip("\n")
    if not body.endswith("\n"):
        body += "\n"
    return body


def _run_validate_manifest(manifest_path: Path) -> int:
    script = REPO_ROOT / "scripts" / "validate-mcp-manifest.py"
    r = subprocess.run(
        [sys.executable, str(script), str(manifest_path)],
        cwd=str(REPO_ROOT),
    )
    return int(r.returncode)


def _atomic_write_text(
    dest: Path,
    content: str,
    *,
    backup_dir: Path,
    validate_json: bool = False,
    validate_toml: bool = False,
) -> None:
    import tempfile  # noqa: PLC0415
    import tomllib  # noqa: PLC0415

    dest.parent.mkdir(parents=True, exist_ok=True)
    backup_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    if dest.is_file():
        shutil.copy2(dest, backup_dir / f"{ts}_{dest.name}.bak")

    fd, tmp_name = tempfile.mkstemp(prefix=f".{dest.name}.", suffix=".tmp", dir=str(dest.parent), text=True)
    os.close(fd)
    tmp_path = Path(tmp_name)
    try:
        tmp_path.write_text(content, encoding="utf-8")
        if validate_json:
            json.loads(tmp_path.read_text(encoding="utf-8"))
        if validate_toml:
            tomllib.loads(tmp_path.read_text(encoding="utf-8"))
        os.replace(tmp_path, dest)
    except Exception:
        if tmp_path.exists():
            tmp_path.unlink()
        raise


# --- Recipes: canonical execution payload per MCP per surface (matches current templates) ---


def _r(
    *,
    cursor: Optional[Dict[str, Any]] = None,
    codex: Optional[Dict[str, Any]] = None,
    opencode: Optional[Dict[str, Any]] = None,
) -> Dict[str, Dict[str, Any]]:
    return {"cursor": cursor or {}, "codex": codex or {}, "opencode": opencode or {}}


def build_mcp_surface_recipes() -> Dict[str, Dict[str, Dict[str, Any]]]:
    """Full recipe table for all manifest MCP ids (payload only; enabled comes from manifest)."""
    py = f"{H}/.config/ai/runtime/.venv/bin/python"
    df = f"{H}/dotfiles/ai/runtime/mcp/servers"
    excalidraw_args = [
        "run",
        "-i",
        "--rm",
        "-e",
        "EXPRESS_SERVER_URL=http://host.docker.internal:3210",
        "-e",
        "ENABLE_CANVAS_SYNC=true",
        "-e",
        f"EXCALIDRAW_EXPORT_DIR={EXCALIDRAW_WORKSPACE_CONTAINER}",
        "-v",
        f"{EXCALIDRAW_WORKSPACE_HOST_TMPL}:{EXCALIDRAW_WORKSPACE_CONTAINER}",
        "ghcr.io/yctimlin/mcp_excalidraw:latest",
    ]
    return {
        "excalidraw_canvas": _r(
            cursor={
                "command": "docker",
                "args": excalidraw_args,
                "env": {},
            },
            codex={
                "command": "docker",
                "args": excalidraw_args,
                "env": {},
            },
            opencode={
                "type": "local",
                "command": ["docker", *excalidraw_args],
            },
        ),
        "context7": _r(
            cursor={"command": "npx", "args": ["-y", "@upstash/context7-mcp"], "env": {}},
            codex={"command": "npx", "args": ["-y", "@upstash/context7-mcp"], "env": {}},
            opencode={
                "type": "local",
                "command": ["npx", "-y", "@upstash/context7-mcp"],
                "environment": {},
            },
        ),
        "docker": _r(
            cursor={
                "command": "docker.exe",
                "args": ["mcp", "gateway", "run"],
                "env": {},
            },
            codex={
                "command": "docker.exe",
                "args": ["mcp", "gateway", "run"],
                "env": {},
            },
            opencode={
                "type": "local",
                "command": ["docker.exe", "mcp", "gateway", "run"],
                "environment": {},
            },
        ),
        "grafana": _r(
            cursor={
                "command": "uvx",
                "args": ["mcp-grafana"],
                "env": {
                    "GRAFANA_URL": "http://localhost:3002",
                    "GRAFANA_USERNAME": "admin",
                    "GRAFANA_PASSWORD": "admin",
                },
            },
            codex={
                "command": "uvx",
                "args": ["mcp-grafana"],
                "env": {
                    "GRAFANA_URL": "http://localhost:3002",
                    "GRAFANA_USERNAME": "admin",
                    "GRAFANA_PASSWORD": "admin",
                },
            },
            opencode={
                "type": "local",
                "command": ["uvx", "mcp-grafana"],
                "environment": {
                    "GRAFANA_URL": "http://localhost:3002",
                    "GRAFANA_USERNAME": "admin",
                    "GRAFANA_PASSWORD": "admin",
                },
            },
        ),
        "opentelemetry": _r(
            cursor={
                "command": "uvx",
                "args": ["--with", "opentelemetry-semantic-conventions-ai==0.4.13", "opentelemetry-mcp"],
                "env": {"BACKEND_TYPE": "tempo", "BACKEND_URL": "http://localhost:3200"},
            },
            codex={
                "command": "uvx",
                "args": ["--with", "opentelemetry-semantic-conventions-ai==0.4.13", "opentelemetry-mcp"],
                "env": {"BACKEND_TYPE": "tempo", "BACKEND_URL": "http://localhost:3200"},
            },
            opencode={
                "type": "local",
                "command": ["uvx", "--with", "opentelemetry-semantic-conventions-ai==0.4.13", "opentelemetry-mcp"],
                "environment": {"BACKEND_TYPE": "tempo", "BACKEND_URL": "http://localhost:3200"},
            },
        ),
        "github": _r(
            cursor={
                "command": "/usr/bin/bash",
                "args": [
                    "-lc",
                    f"source ~/.secrets/codex.env 2>/dev/null; exec {H}/.local/bin/codex-mcp-github",
                ],
                "env": {},
            },
            codex={
                "command": "/usr/bin/bash",
                "args": [
                    "-lc",
                    f"source ~/.secrets/codex.env 2>/dev/null; exec {H}/.local/bin/codex-mcp-github",
                ],
                "env": {},
            },
            opencode={
                "type": "local",
                "command": [
                    "/usr/bin/bash",
                    "-lc",
                    f"source ~/.secrets/codex.env 2>/dev/null; exec {H}/.local/bin/codex-mcp-github",
                ],
                "environment": {},
            },
        ),
        "fetch": _r(
            cursor={"command": "uvx", "args": ["mcp-server-fetch"], "env": {}},
            codex={"command": "uvx", "args": ["mcp-server-fetch"], "env": {}},
            opencode={"type": "local", "command": ["uvx", "mcp-server-fetch"], "environment": {}},
        ),
        "gitnexus": _r(
            cursor={"command": f"{H}/.local/share/chezmoi/bin/mcp-gitnexus-launcher", "args": [], "env": {}},
            codex={"command": f"{H}/.local/share/chezmoi/bin/mcp-gitnexus-launcher", "args": [], "env": {}},
            opencode={
                "type": "local",
                "command": [f"{H}/.local/share/chezmoi/bin/mcp-gitnexus-launcher"],
                "environment": {},
            },
        ),
        "filesystem": _r(
            cursor={"command": f"{H}/.local/share/chezmoi/bin/mcp-filesystem-launcher", "args": [], "env": {}},
            codex={"command": f"{H}/.local/share/chezmoi/bin/mcp-filesystem-launcher", "args": [], "env": {}},
            opencode={
                "type": "local",
                "command": [f"{H}/.local/share/chezmoi/bin/mcp-filesystem-launcher"],
                "environment": {},
            },
        ),
        "git": _r(
            cursor={"command": f"{H}/.local/share/chezmoi/bin/mcp-git-launcher", "args": [], "env": {}},
            codex={"command": f"{H}/.local/share/chezmoi/bin/mcp-git-launcher", "args": [], "env": {}},
            opencode={
                "type": "local",
                "command": [f"{H}/.local/share/chezmoi/bin/mcp-git-launcher"],
                "environment": {},
            },
        ),
        "sequential-thinking": _r(
            cursor={
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
                "env": {},
            },
            codex={
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
                "env": {},
            },
            opencode={
                "type": "local",
                "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
                "environment": {},
            },
        ),
        "obsidian": _r(
            cursor={
                "command": "npx",
                "args": ["-y", "@bitbonsai/mcpvault", OBSIDIAN_VAULT_TMPL],
                "env": {},
            },
            codex={
                "command": "npx",
                "args": ["-y", "@bitbonsai/mcpvault", OBSIDIAN_VAULT_TMPL],
                "env": {},
            },
            opencode={
                "type": "local",
                "command": ["npx", "-y", "@bitbonsai/mcpvault", OBSIDIAN_VAULT_TMPL],
                "environment": {},
            },
        ),
        "playwright": _r(
            cursor={"command": "npx", "args": ["-y", "@executeautomation/playwright-mcp-server"], "env": {}},
            codex={"command": "npx", "args": ["-y", "@executeautomation/playwright-mcp-server"], "env": {}},
            opencode={
                "type": "local",
                "command": ["npx", "-y", "@executeautomation/playwright-mcp-server"],
                "environment": {},
            },
        ),
        "postgres": _r(
            cursor={
                "command": f"{H}/.local/share/chezmoi/bin/mcp-postgres-launcher",
                "args": [],
                "env": {"MCP_POSTGRES_SECRETS": f"{H}/.config/mcp-secrets.env"},
            },
            codex={
                "command": f"{H}/.local/share/chezmoi/bin/mcp-postgres-launcher",
                "args": [],
                "env": {"MCP_POSTGRES_SECRETS": f"{H}/.config/mcp-secrets.env"},
            },
            opencode={
                "type": "local",
                "command": [f"{H}/.local/share/chezmoi/bin/mcp-postgres-launcher"],
                "environment": {"MCP_POSTGRES_SECRETS": f"{H}/.config/mcp-secrets.env"},
            },
        ),
        "trino": _r(
            cursor={
                "command": py,
                "args": ["-m", "trino_mcp"],
                "env": {
                    "TRINO_HOST": "localhost",
                    "TRINO_PORT": "8080",
                    "TRINO_USER": "admin",
                    "TRINO_CATALOG": "iceberg",
                    "TRINO_HTTP_SCHEME": "http",
                    "AUTH_METHOD": "NONE",
                },
            },
            codex={
                "command": py,
                "args": ["-m", "trino_mcp"],
                "env": {
                    "TRINO_HOST": "localhost",
                    "TRINO_PORT": "8080",
                    "TRINO_USER": "admin",
                    "TRINO_CATALOG": "iceberg",
                    "TRINO_HTTP_SCHEME": "http",
                    "AUTH_METHOD": "NONE",
                },
            },
            opencode={
                "type": "local",
                "command": [py, "-m", "trino_mcp"],
                "environment": {
                    "TRINO_HOST": "localhost",
                    "TRINO_PORT": "8080",
                    "TRINO_USER": "admin",
                    "TRINO_CATALOG": "iceberg",
                    "TRINO_HTTP_SCHEME": "http",
                    "AUTH_METHOD": "NONE",
                },
            },
        ),
        "dagster": _r(
            cursor={
                "command": py,
                "args": [f"{df}/dagster/server.py"],
                "env": {"DAGSTER_GRAPHQL_URL": "http://localhost:3000/graphql", "DAGSTER_TIMEOUT_SECONDS": "30"},
            },
            codex={
                "command": py,
                "args": [f"{df}/dagster/server.py"],
                "env": {"DAGSTER_GRAPHQL_URL": "http://localhost:3000/graphql", "DAGSTER_TIMEOUT_SECONDS": "30"},
            },
            opencode={
                "type": "local",
                "command": [py, f"{df}/dagster/server.py"],
                "environment": {
                    "DAGSTER_GRAPHQL_URL": "http://localhost:3000/graphql",
                    "DAGSTER_TIMEOUT_SECONDS": "30",
                },
            },
        ),
        "minio": _r(
            cursor={
                "command": "/usr/bin/bash",
                "args": [
                    "-lc",
                    "source ~/.secrets/codex.env 2>/dev/null; export MINIO_ENDPOINT='http://localhost:9000'; "
                    "export MINIO_SECURE='false'; export MINIO_REGION='us-east-1'; "
                    f"exec {py} {df}/minio/server.py",
                ],
                "env": {},
            },
            codex={
                "command": "/usr/bin/bash",
                "args": [
                    "-lc",
                    "source ~/.secrets/codex.env 2>/dev/null; export MINIO_ENDPOINT='http://localhost:9000'; "
                    "export MINIO_SECURE='false'; export MINIO_REGION='us-east-1'; "
                    f"exec {py} {df}/minio/server.py",
                ],
                "env": {},
            },
            opencode={
                "type": "local",
                "command": [
                    "/usr/bin/bash",
                    "-lc",
                    "source ~/.secrets/codex.env 2>/dev/null; export MINIO_ENDPOINT='http://localhost:9000'; "
                    "export MINIO_SECURE='false'; export MINIO_REGION='us-east-1'; "
                    f"exec {py} {df}/minio/server.py",
                ],
                "environment": {},
            },
        ),
        "tempo": _r(
            cursor={
                "command": py,
                "args": [f"{df}/tempo/server.py"],
                "env": {"TEMPO_BASE_URL": "http://localhost:3200", "TEMPO_TIMEOUT_SECONDS": "30"},
            },
            codex={
                "command": py,
                "args": [f"{df}/tempo/server.py"],
                "env": {"TEMPO_BASE_URL": "http://localhost:3200", "TEMPO_TIMEOUT_SECONDS": "30"},
            },
            opencode={
                "type": "local",
                "command": [py, f"{df}/tempo/server.py"],
                "environment": {"TEMPO_BASE_URL": "http://localhost:3200", "TEMPO_TIMEOUT_SECONDS": "30"},
            },
        ),
        "loki": _r(
            cursor={
                "command": py,
                "args": [f"{df}/loki/server.py"],
                "env": {"LOKI_BASE_URL": "http://localhost:3100", "LOKI_TIMEOUT_SECONDS": "30"},
            },
            codex={
                "command": py,
                "args": [f"{df}/loki/server.py"],
                "env": {"LOKI_BASE_URL": "http://localhost:3100", "LOKI_TIMEOUT_SECONDS": "30"},
            },
            opencode={
                "type": "local",
                "command": [py, f"{df}/loki/server.py"],
                "environment": {"LOKI_BASE_URL": "http://localhost:3100", "LOKI_TIMEOUT_SECONDS": "30"},
            },
        ),
        "prometheus": _r(
            cursor={
                "command": py,
                "args": [f"{df}/prometheus/server.py"],
                "env": {"PROMETHEUS_URL": "http://localhost:9090", "PROMETHEUS_TIMEOUT_SECONDS": "15"},
            },
            codex={
                "command": py,
                "args": [f"{df}/prometheus/server.py"],
                "env": {"PROMETHEUS_URL": "http://localhost:9090", "PROMETHEUS_TIMEOUT_SECONDS": "15"},
            },
            opencode={
                "type": "local",
                "command": [py, f"{df}/prometheus/server.py"],
                "environment": {"PROMETHEUS_URL": "http://localhost:9090", "PROMETHEUS_TIMEOUT_SECONDS": "15"},
            },
        ),
        "store_etl_ops": _r(
            cursor={"command": py, "args": [f"{df}/store_etl_ops/server.py"], "env": {}},
            codex={"command": py, "args": [f"{df}/store_etl_ops/server.py"], "env": {}},
            opencode={
                "type": "local",
                "command": [py, f"{df}/store_etl_ops/server.py"],
                "environment": {},
            },
        ),
    }


MCP_SURFACE_RECIPES = build_mcp_surface_recipes()


def _toml_escape_basic(s: str) -> str:
    """Double-quoted TOML string content escapes (minimal subset for our literals)."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def _format_toml_value(v: Any) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int) and not isinstance(v, bool):
        return str(v)
    if isinstance(v, str):
        # Prefer TOML basic strings in double quotes; single quotes inside need no escape.
        if "\n" in v:
            body = v.replace("\\", "\\\\").replace('"', '\\"')
            return '"""' + body + '"""'
        return '"' + _toml_escape_basic(v) + '"'
    if isinstance(v, list):
        parts = [_format_toml_value(x) for x in v]
        return "[" + ", ".join(parts) + "]"
    raise TypeError(f"unsupported TOML value type: {type(v)}")


def render_codex_fragment(mcps: List[Dict[str, Any]], recipes: Dict[str, Dict[str, Dict[str, Any]]]) -> str:
    lines: List[str] = []
    for entry in mcps:
        mid = entry.get("id")
        if not isinstance(mid, str) or not manifest_surface_enabled(entry, "codex"):
            continue
        rec = recipes.get(mid, {}).get("codex")
        if not rec:
            raise KeyError(f"missing codex recipe for enabled mcp: {mid}")
        lines.append("")
        lines.append(f"[mcp_servers.{mid}]")
        lines.append(f"command = {_format_toml_value(rec['command'])}")
        if rec.get("args") is not None:
            lines.append(f"args = {_format_toml_value(rec['args'])}")
        lines.append("enabled = true")
        if rec.get("cwd"):
            lines.append(f"cwd = {_format_toml_value(rec['cwd'])}")
        env = rec.get("env") or {}
        if env:
            lines.append("")
            lines.append(f"[mcp_servers.{mid}.env]")
            for k in sorted(env.keys()):
                lines.append(f"{k} = {_format_toml_value(env[k])}")
    body = "\n".join(lines).strip()
    if body:
        body += "\n"
    return body


def render_cursor_json(mcps: List[Dict[str, Any]], recipes: Dict[str, Dict[str, Dict[str, Any]]]) -> str:
    servers: Dict[str, Any] = {}
    for entry in mcps:
        mid = entry.get("id")
        if not isinstance(mid, str) or not manifest_surface_enabled(entry, "cursor"):
            continue
        rec = recipes.get(mid, {}).get("cursor")
        if not rec:
            raise KeyError(f"missing cursor recipe for enabled mcp: {mid}")
        servers[mid] = {
            "command": rec["command"],
            "args": list(rec.get("args") or []),
            "env": dict(rec.get("env") or {}),
        }
    doc = {"mcpServers": servers}
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def render_opencode_json(mcps: List[Dict[str, Any]], recipes: Dict[str, Dict[str, Dict[str, Any]]]) -> str:
    mcp_block: Dict[str, Any] = {}
    for entry in mcps:
        mid = entry.get("id")
        if not isinstance(mid, str) or not manifest_surface_enabled(entry, "opencode"):
            continue
        rec = recipes.get(mid, {}).get("opencode")
        if not rec:
            raise KeyError(f"missing opencode recipe for enabled mcp: {mid}")
        block: Dict[str, Any] = {
            "type": rec.get("type", "local"),
            "command": list(rec.get("command") or []),
            "enabled": True,
        }
        env = rec.get("environment") or {}
        if env:
            block["environment"] = dict(env)
        mcp_block[mid] = block
    doc = {"$schema": "https://opencode.ai/config.json", "mcp": mcp_block}
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def cmd_render(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest)
    try:
        _, mcps = load_manifest(manifest_path)
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL could not load manifest: {exc}", file=sys.stderr)
        return 1

    known = {e.get("id") for e in mcps if isinstance(e.get("id"), str)}
    for mid in known:
        for surf in SURFACES:
            entry = next((x for x in mcps if x.get("id") == mid), None)
            if not entry:
                continue
            if manifest_surface_enabled(entry, surf):
                if mid not in MCP_SURFACE_RECIPES or surf not in MCP_SURFACE_RECIPES[mid]:
                    print(f"FAIL missing recipe surface {surf} for {mid}", file=sys.stderr)
                    return 1
                if not MCP_SURFACE_RECIPES[mid][surf]:
                    print(f"FAIL empty recipe for {mid}.{surf}", file=sys.stderr)
                    return 1

    try:
        OUT_CURSOR.parent.mkdir(parents=True, exist_ok=True)
        OUT_CODEX.parent.mkdir(parents=True, exist_ok=True)
        OUT_OPENCODE.parent.mkdir(parents=True, exist_ok=True)

        cj = render_cursor_json(mcps, MCP_SURFACE_RECIPES)
        json.loads(cj)
        OUT_CURSOR.write_text(cj, encoding="utf-8")

        cf = render_codex_fragment(mcps, MCP_SURFACE_RECIPES)
        import tomllib  # noqa: PLC0415

        if cf.strip():
            tomllib.loads(cf)
        OUT_CODEX.write_text(cf, encoding="utf-8")

        oj = render_opencode_json(mcps, MCP_SURFACE_RECIPES)
        json.loads(oj)
        OUT_OPENCODE.write_text(oj, encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL render: {exc}", file=sys.stderr)
        return 1

    if not getattr(args, "_quiet_render_ok", False):
        print(f"==> MCP render OK under {BUILD_MCPS}")
    return 0


# --- Parse templates ---


@dataclass
class NormConfig:
    tokens: List[str]
    env: Dict[str, str] = field(default_factory=dict)
    cwd: Optional[str] = None
    enabled: bool = True


def normalize_cursor_entry(obj: Mapping[str, Any]) -> NormConfig:
    cmd = str(obj.get("command", ""))
    args = [str(x) for x in (obj.get("args") or [])]
    env_raw = obj.get("env") or {}
    env = {str(k): str(v) for k, v in env_raw.items()} if isinstance(env_raw, dict) else {}
    return NormConfig(tokens=[cmd] + args, env=env, cwd=None, enabled=True)


def normalize_opencode_entry(obj: Mapping[str, Any]) -> NormConfig:
    cmd = obj.get("command")
    if isinstance(cmd, list):
        tokens = [str(x) for x in cmd]
    elif isinstance(cmd, str):
        tokens = [cmd]
    else:
        tokens = []
    env_raw = obj.get("environment") or {}
    env = {str(k): str(v) for k, v in env_raw.items()} if isinstance(env_raw, dict) else {}
    en = obj.get("enabled", True)
    if isinstance(en, str):
        enabled = en.lower() == "true"
    else:
        enabled = bool(en)
    return NormConfig(tokens=tokens, env=env, cwd=None, enabled=enabled)


def normalize_codex_entry(obj: Mapping[str, Any]) -> NormConfig:
    cmd = str(obj.get("command", ""))
    args = [str(x) for x in (obj.get("args") or [])]
    env: Dict[str, str] = {}
    nested = obj.get("env")
    if isinstance(nested, dict):
        env = {str(k): str(v) for k, v in nested.items()}
    en = obj.get("enabled", True)
    if isinstance(en, str):
        enabled = en.lower() == "true"
    else:
        enabled = bool(en)
    cwd = obj.get("cwd")
    cwd_s = str(cwd) if cwd is not None else None
    return NormConfig(tokens=[cmd] + args, env=env, cwd=cwd_s, enabled=enabled)


def parse_cursor_template(path: Path) -> Dict[str, NormConfig]:
    data = json.loads(strip_chezmoi_template_preamble(path.read_text(encoding="utf-8")))
    servers = data.get("mcpServers") or {}
    if not isinstance(servers, dict):
        return {}
    return {str(k): normalize_cursor_entry(v) for k, v in servers.items() if isinstance(v, dict)}


def parse_opencode_template(path: Path) -> Dict[str, NormConfig]:
    data = json.loads(strip_chezmoi_template_preamble(path.read_text(encoding="utf-8")))
    mcp = data.get("mcp") or {}
    if not isinstance(mcp, dict):
        return {}
    return {str(k): normalize_opencode_entry(v) for k, v in mcp.items() if isinstance(v, dict)}


def parse_codex_mcp_servers(path: Path) -> Dict[str, NormConfig]:
    import tomllib  # noqa: PLC0415

    raw = strip_chezmoi_template_preamble(path.read_text(encoding="utf-8"))
    doc = tomllib.loads(raw)
    root = doc.get("mcp_servers")
    if not isinstance(root, dict):
        return {}
    out: Dict[str, NormConfig] = {}
    for mid, val in root.items():
        if not isinstance(val, dict):
            continue
        merged = dict(val)
        env_sub = merged.get("env")
        if isinstance(env_sub, dict):
            merged = {k: v for k, v in merged.items() if k != "env"}
            merged["env"] = env_sub
        out[str(mid)] = normalize_codex_entry(merged)
    return out


def parse_codex_fragment_text(text: str) -> Dict[str, NormConfig]:
    import tomllib  # noqa: PLC0415

    if not text.strip():
        return {}
    doc = tomllib.loads(text)
    root = doc.get("mcp_servers")
    if not isinstance(root, dict):
        return {}
    out: Dict[str, NormConfig] = {}
    for mid, val in root.items():
        if not isinstance(val, dict):
            continue
        merged = dict(val)
        env_sub = merged.get("env")
        if isinstance(env_sub, dict):
            merged = {k: v for k, v in merged.items() if k != "env"}
            merged["env"] = env_sub
        out[str(mid)] = normalize_codex_entry(merged)
    return out


def norm_from_recipe_cursor(rec: Mapping[str, Any]) -> NormConfig:
    return normalize_cursor_entry(rec)


def norm_from_recipe_codex(rec: Mapping[str, Any]) -> NormConfig:
    d = {
        "command": rec["command"],
        "args": list(rec.get("args") or []),
        "env": dict(rec.get("env") or {}),
        "cwd": rec.get("cwd"),
        "enabled": True,
    }
    return normalize_codex_entry(d)


def norm_from_recipe_opencode(rec: Mapping[str, Any]) -> NormConfig:
    d = {
        "command": list(rec.get("command") or []),
        "environment": dict(rec.get("environment") or {}),
        "enabled": True,
    }
    return normalize_opencode_entry(d)


def configs_equal(a: NormConfig, b: NormConfig) -> bool:
    return a.tokens == b.tokens and a.env == b.env and (a.cwd or "") == (b.cwd or "") and a.enabled == b.enabled


@dataclass
class DriftFinding:
    surface: str
    category: str
    mcp_id: str
    bucket: str  # INTENTIONAL_PENDING_PARITY | UNEXPECTED_DRIFT
    detail: str


def manifest_surface_off(entry: Mapping[str, Any], surf: str) -> Tuple[bool, str]:
    surfaces = entry.get("surfaces") or {}
    if not isinstance(surfaces, dict):
        return False, ""
    cfg = surfaces.get(surf)
    if not isinstance(cfg, dict):
        return False, ""
    if cfg.get("enabled") is False:
        return True, str(cfg.get("reason") or "")
    return False, ""


def classify_drift_surface(
    surface: str,
    manifest_mcps: List[Dict[str, Any]],
    manifest_id_set: Set[str],
    template_map: Dict[str, NormConfig],
    render_map: Dict[str, NormConfig],
) -> List[DriftFinding]:
    findings: List[DriftFinding] = []

    def entry_for(mid: str) -> Optional[Dict[str, Any]]:
        for x in manifest_mcps:
            if x.get("id") == mid:
                return x
        return None

    tmpl_ids = set(template_map.keys())

    for mid in sorted(tmpl_ids - manifest_id_set):
        findings.append(
            DriftFinding(
                surface=surface,
                category="extra_in_template",
                mcp_id=mid,
                bucket="UNEXPECTED_DRIFT",
                detail="MCP present in template but not declared in MANIFEST",
            )
        )

    for mid in sorted(manifest_id_set):
        e = entry_for(mid)
        if e is None:
            continue
        want_on = manifest_surface_enabled(e, surface)
        off, reason = manifest_surface_off(e, surface)
        in_t = mid in template_map
        if surface == "cursor":
            t_active = in_t
        else:
            t_active = in_t and template_map[mid].enabled

        if want_on:
            if not t_active:
                sub = "missing_in_template" if not in_t else "enabled_mismatch"
                findings.append(
                    DriftFinding(
                        surface=surface,
                        category=sub,
                        mcp_id=mid,
                        bucket="INTENTIONAL_PENDING_PARITY",
                        detail="manifest enabled=true; template absent or disabled (pending real parity)",
                    )
                )
            else:
                rn = render_map.get(mid)
                tn = template_map.get(mid)
                if rn is None or tn is None:
                    continue
                if not configs_equal(rn, tn):
                    if rn.env != tn.env:
                        cat, detail = "env_mismatch", "env maps differ"
                    elif (rn.cwd or "") != (tn.cwd or ""):
                        cat, detail = "cwd_mismatch", "cwd differs"
                    elif rn.tokens != tn.tokens:
                        if rn.tokens and tn.tokens and rn.tokens[0] == tn.tokens[0]:
                            cat, detail = "args_mismatch", "args differ (command token matches)"
                        else:
                            cat, detail = "command_mismatch", "tokenized command+args differ"
                    else:
                        cat, detail = "enabled_mismatch", "normalized config differs (enabled or other)"
                    findings.append(
                        DriftFinding(
                            surface=surface,
                            category=cat,
                            mcp_id=mid,
                            bucket="UNEXPECTED_DRIFT",
                            detail=detail,
                        )
                    )

        if off and t_active:
            findings.append(
                DriftFinding(
                    surface=surface,
                    category="enabled_mismatch",
                    mcp_id=mid,
                    bucket="UNEXPECTED_DRIFT",
                    detail=f"manifest enabled=false ({reason!r}) but template active",
                )
            )

    return findings


def build_render_norm_maps(
    mcps: List[Dict[str, Any]], recipes: Dict[str, Dict[str, Dict[str, Any]]]
) -> Tuple[Dict[str, NormConfig], Dict[str, NormConfig], Dict[str, NormConfig]]:
    c: Dict[str, NormConfig] = {}
    o: Dict[str, NormConfig] = {}
    x: Dict[str, NormConfig] = {}
    for entry in mcps:
        mid = entry.get("id")
        if not isinstance(mid, str):
            continue
        if manifest_surface_enabled(entry, "cursor") and mid in recipes:
            c[mid] = norm_from_recipe_cursor(recipes[mid]["cursor"])
        if manifest_surface_enabled(entry, "codex") and mid in recipes:
            x[mid] = norm_from_recipe_codex(recipes[mid]["codex"])
        if manifest_surface_enabled(entry, "opencode") and mid in recipes:
            o[mid] = norm_from_recipe_opencode(recipes[mid]["opencode"])
    return c, x, o


def dedupe_findings(findings: List[DriftFinding]) -> List[DriftFinding]:
    seen: Set[Tuple[str, str, str, str, str]] = set()
    out: List[DriftFinding] = []
    for f in findings:
        key = (f.surface, f.category, f.mcp_id, f.bucket, f.detail)
        if key in seen:
            continue
        seen.add(key)
        out.append(f)
    return out


def cmd_drift(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest)
    try:
        _, mcps = load_manifest(manifest_path)
    except SystemExit as se:
        return int(se.code) if isinstance(se.code, int) else 2
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL could not load manifest: {exc}", file=sys.stderr)
        return 2

    rc = cmd_render(argparse.Namespace(manifest=str(manifest_path), _quiet_render_ok=True))
    if rc != 0:
        return rc

    manifest_ids_set = manifest_ids(mcps)

    try:
        tmpl_c = parse_cursor_template(TMPL_CURSOR)
        tmpl_x = parse_codex_mcp_servers(TMPL_CODEX)
        tmpl_o = parse_opencode_template(TMPL_OPENCODE)
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL parse templates or renders: {exc}", file=sys.stderr)
        return 1

    r_c, r_x, r_o = build_render_norm_maps(mcps, MCP_SURFACE_RECIPES)

    all_findings: List[DriftFinding] = []
    all_findings.extend(classify_drift_surface("cursor", mcps, manifest_ids_set, tmpl_c, r_c))
    all_findings.extend(classify_drift_surface("codex", mcps, manifest_ids_set, tmpl_x, r_x))
    all_findings.extend(classify_drift_surface("opencode", mcps, manifest_ids_set, tmpl_o, r_o))
    all_findings = dedupe_findings(all_findings)

    intentional = [f for f in all_findings if f.bucket == "INTENTIONAL_PENDING_PARITY"]
    unexpected = [f for f in all_findings if f.bucket == "UNEXPECTED_DRIFT"]

    report = {
        "intentional_pending_parity": [f.__dict__ for f in intentional],
        "unexpected_drift": [f.__dict__ for f in unexpected],
    }
    OUT_DRIFT_JSON.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print("==> MCP drift report")
    print("")
    print("--- INTENTIONAL_PENDING_PARITY ---")
    if not intentional:
        print("(none)")
    else:
        by_s: Dict[str, List[DriftFinding]] = {}
        for f in intentional:
            by_s.setdefault(f.surface, []).append(f)
        for surf in SURFACES:
            if surf not in by_s:
                continue
            print(f"[{surf}]")
            for f in by_s[surf]:
                print(f"  - {f.category}  {f.mcp_id}: {f.detail}")
    print("")
    print("--- UNEXPECTED_DRIFT ---")
    if not unexpected:
        print("(none)")
    else:
        for f in unexpected:
            print(f"  - [{f.surface}] {f.category}  {f.mcp_id}: {f.detail}")
    print("")
    print(f"==> Wrote {OUT_DRIFT_JSON}")
    if unexpected:
        print("FAIL unexpected drift present (exit 1)", file=sys.stderr)
        return 1
    print("OK drift within intentional pending parity (exit 0)")
    return 0


def cmd_generate(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest)
    apply = bool(getattr(args, "apply", False))
    if not apply:
        print("==> MCP generate — plan only (no files written, including build/mcps/)")
        print("")
        print("Would update productive Chezmoi templates from rendered artifacts:")
        print(f"  {OUT_CURSOR}")
        print(f"    -> {TMPL_CURSOR}")
        print(f"  {OUT_CODEX} (MCP fragment)")
        print(f"    -> {TMPL_CODEX} (replace [mcp_servers.*] only; preamble + [plugins.*] preserved)")
        print(f"  {OUT_OPENCODE}")
        print(f"    -> {TMPL_OPENCODE}")
        print("")
        print("Recommended gate sequence before APPLY=1:")
        print("  make ai-mcp-validate && make ai-mcp-render && make ai-mcp-drift")
        print("")
        print("Re-run with APPLY=1 to update productive MCP templates:")
        print("  make ai-mcp-generate APPLY=1")
        print("  # or: python3 scripts/generate-mcp-configs.py generate --apply")
        return 0

    print("==> MCP generate APPLY=1 — pre-flight gates")
    vr = _run_validate_manifest(manifest_path)
    if vr != 0:
        print("FAIL manifest validation (see validate-mcp-manifest.py); not writing templates", file=sys.stderr)
        return 1

    r_ns = argparse.Namespace(manifest=str(manifest_path), _quiet_render_ok=False)
    if cmd_render(r_ns) != 0:
        print("FAIL render; not writing templates", file=sys.stderr)
        return 1

    # Do not require pre-apply drift=0: productive templates may legitimately lag
    # MANIFEST+recipes until this command writes them. Drift is enforced after write.

    print("==> MCP generate APPLY=1 — writing productive templates (atomic + backups)")
    try:
        cursor_body = OUT_CURSOR.read_text(encoding="utf-8")
        json.loads(cursor_body)
        _atomic_write_text(
            TMPL_CURSOR,
            cursor_body,
            backup_dir=BACKUP_ROOT,
            validate_json=True,
            validate_toml=False,
        )

        op_body = OUT_OPENCODE.read_text(encoding="utf-8")
        json.loads(op_body)
        _atomic_write_text(
            TMPL_OPENCODE,
            op_body,
            backup_dir=BACKUP_ROOT,
            validate_json=True,
            validate_toml=False,
        )

        codex_frag = OUT_CODEX.read_text(encoding="utf-8")
        full_codex = TMPL_CODEX.read_text(encoding="utf-8")
        merged = merge_codex_productive(full_codex, codex_frag)
        import tomllib  # noqa: PLC0415

        tomllib.loads(merged)
        _atomic_write_text(
            TMPL_CODEX,
            merged,
            backup_dir=BACKUP_ROOT,
            validate_json=False,
            validate_toml=True,
        )
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL apply write/validate: {exc}", file=sys.stderr)
        return 1

    try:
        json.loads(strip_chezmoi_template_preamble(TMPL_CURSOR.read_text(encoding="utf-8")))
        json.loads(strip_chezmoi_template_preamble(TMPL_OPENCODE.read_text(encoding="utf-8")))
        import tomllib  # noqa: PLC0415

        tomllib.loads(strip_chezmoi_template_preamble(TMPL_CODEX.read_text(encoding="utf-8")))
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL post-write validation: {exc}", file=sys.stderr)
        return 1

    d_ns = argparse.Namespace(manifest=str(manifest_path))
    if cmd_drift(d_ns) != 0:
        print(
            "FAIL drift after apply (unexpected drift, parse error, or render issue); "
            "productive templates may be inconsistent",
            file=sys.stderr,
        )
        return 1

    try:
        _, mcps = load_manifest(manifest_path)
    except Exception:
        mcps = []
    print("")
    print("==> Summary (MANIFEST.yaml enabled counts)")
    print(f"  cursor:   {count_manifest_surface_enabled(mcps, 'cursor')} MCPs")
    print(f"  codex:    {count_manifest_surface_enabled(mcps, 'codex')} MCPs")
    print(f"  opencode: {count_manifest_surface_enabled(mcps, 'opencode')} MCPs")
    print("")
    print("OK productive templates updated.")
    print("Publish to HOME with: chezmoi --source=$HOME/dotfiles apply  (or make install-dotfiles DOTFILES_APPLY=1)")
    print("Then: make ai-cursor-check")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="MCP config dry-run render + drift + generate from MANIFEST.yaml")
    parser.add_argument(
        "command",
        choices=("render", "drift", "generate"),
        help="render | drift | generate (use generate --apply to write templates)",
    )
    parser.add_argument(
        "--manifest",
        default=str(DEFAULT_MANIFEST),
        help="Path to MANIFEST.yaml",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="With generate: run gates and write productive Chezmoi templates",
    )
    args = parser.parse_args()
    try:
        if args.command == "render":
            return cmd_render(args)
        if args.command == "drift":
            return cmd_drift(args)
        return cmd_generate(args)
    except SystemExit as se:
        code = se.code
        if isinstance(code, int):
            return code
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
