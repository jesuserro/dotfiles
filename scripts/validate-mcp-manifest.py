#!/usr/bin/env python3
"""
Validate ai/assets/mcps/MANIFEST.yaml — canonical MCP intent (non-mutating).

Requires PyYAML (same as generate-commands / optional ai-cursor-check registry parsing).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MANIFEST = REPO_ROOT / "ai" / "assets" / "mcps" / "MANIFEST.yaml"

EXPECTED_IDS: Set[str] = {
    "excalidraw_canvas",
    "context7",
    "docker",
    "grafana",
    "opentelemetry",
    "github",
    "fetch",
    "gitnexus",
    "filesystem",
    "git",
    "sequential-thinking",
    "obsidian",
    "playwright",
    "postgres",
    "trino",
    "dagster",
    "minio",
    "tempo",
    "loki",
    "prometheus",
    "store_etl_ops",
}

SURFACE_NAMES = ("cursor", "codex", "opencode")

ALLOWED_RUNTIMES = {
    "node",
    "npx",
    "uvx",
    "bash",
    "launcher",
    "venv_python",
    "docker",
    "shell",
}

# Secret entry: only these keys allowed; values must not look like embedded secrets.
ALLOWED_SECRET_KEYS = frozenset({"path", "keys_hint", "ref", "description"})

FORBIDDEN_VALUE_KEYS = frozenset(
    {
        "password",
        "secret_value",
        "api_key",
        "access_token",
        "refresh_token",
        "private_key",
        "client_secret",
    }
)

TOKEN_PATTERNS = (
    re.compile(r"ghp_[A-Za-z0-9]{20,}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"xox[baprs]-[A-Za-z0-9-]{10,}"),
)


def load_yaml(path: Path) -> Any:
    try:
        import yaml  # type: ignore
    except ImportError as exc:  # pragma: no cover - exercised when PyYAML missing
        print(
            "FAIL PyYAML is required: pip install pyyaml "
            "(or apt install python3-yaml on Debian/Ubuntu)",
            file=sys.stderr,
        )
        raise SystemExit(2) from exc
    text = path.read_text(encoding="utf-8")
    return yaml.safe_load(text)


def scan_strings_for_leaks(obj: Any, path: str = "") -> List[str]:
    """Detect obvious secret material in string values anywhere in the tree."""
    issues: List[str] = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            kp = f"{path}.{k}" if path else str(k)
            kl = str(k).lower()
            if kl in FORBIDDEN_VALUE_KEYS and isinstance(v, str) and v.strip():
                issues.append(f"suspicious key '{k}' with non-empty string at {kp}")
            if isinstance(v, str):
                for pat in TOKEN_PATTERNS:
                    if pat.search(v):
                        issues.append(f"possible token pattern in value at {kp}")
            issues.extend(scan_strings_for_leaks(v, kp))
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            issues.extend(scan_strings_for_leaks(item, f"{path}[{i}]"))
    elif isinstance(obj, str):
        for pat in TOKEN_PATTERNS:
            if pat.search(obj):
                issues.append(f"possible token pattern in value at {path}")
    return issues


def validate_secrets_list(secrets: Any, mcp_id: str) -> List[str]:
    errs: List[str] = []
    if secrets is None:
        return ["mcps[] secrets: must be a list (use [])"]
    if not isinstance(secrets, list):
        return ["mcps[] secrets: must be a list"]
    for i, item in enumerate(secrets):
        if not isinstance(item, dict):
            errs.append(f"{mcp_id}: secrets[{i}] must be a mapping")
            continue
        bad_keys = set(item) - ALLOWED_SECRET_KEYS
        if bad_keys:
            errs.append(f"{mcp_id}: secrets[{i}] has disallowed keys {sorted(bad_keys)}")
        for fk in FORBIDDEN_VALUE_KEYS:
            if fk in item:
                errs.append(f"{mcp_id}: secrets[{i}] must not contain field '{fk}'")
        if "keys_hint" in item and item["keys_hint"] is not None:
            kh = item["keys_hint"]
            if not isinstance(kh, list) or not all(isinstance(x, str) for x in kh):
                errs.append(f"{mcp_id}: secrets[{i}].keys_hint must be a list of strings")
        for key in ("path", "ref"):
            if key in item and item[key] is not None and not isinstance(item[key], str):
                errs.append(f"{mcp_id}: secrets[{i}].{key} must be a string")
    return errs


def validate_manifest(doc: Any) -> Tuple[str, List[str], List[str]]:
    """
    Returns (status, errors, warnings) where status is PASS | PASS_WITH_WARNINGS | FAIL.
    """
    errors: List[str] = []
    warnings: List[str] = []

    if not isinstance(doc, dict):
        return "FAIL", ["root must be a mapping"], warnings

    if "version" not in doc:
        errors.append("missing top-level 'version'")

    policy = doc.get("policy")
    if not isinstance(policy, dict):
        errors.append("policy must be a mapping")
    else:
        if policy.get("compatible_by_default_enabled") is not True:
            errors.append("policy.compatible_by_default_enabled must be boolean true")

    profiles = doc.get("profiles", None)
    if profiles is not None:
        if not isinstance(profiles, dict):
            errors.append("profiles must be a mapping when present")
        else:
            for pk, pv in profiles.items():
                if pv is not None and not isinstance(pv, dict):
                    errors.append(f"profiles.{pk} must be a mapping or empty")

    mcps = doc.get("mcps")
    if not isinstance(mcps, list) or len(mcps) == 0:
        errors.append("mcps must be a non-empty list")
        return ("FAIL", errors, warnings)

    seen: Set[str] = set()
    required_strings = (
        "id",
        "display_name",
        "description",
        "layer",
        "category",
        "runtime",
        "surfaces",
        "requires",
        "secrets",
        "paths_probe",
        "notes",
    )

    for idx, entry in enumerate(mcps):
        loc = f"mcps[{idx}]"
        if not isinstance(entry, dict):
            errors.append(f"{loc}: entry must be a mapping")
            continue
        for field in required_strings:
            if field not in entry:
                errors.append(f"{loc}: missing required field '{field}'")
        mcp_id = entry.get("id")
        if not isinstance(mcp_id, str) or not mcp_id.strip():
            errors.append(f"{loc}: id must be a non-empty string")
            continue
        if mcp_id in seen:
            errors.append(f"duplicate mcp id: {mcp_id}")
        seen.add(mcp_id)

        for s in ("display_name", "description", "layer", "category", "runtime"):
            val = entry.get(s)
            if not isinstance(val, str) or not str(val).strip():
                errors.append(f"{mcp_id}: field '{s}' must be a non-empty string")

        rt = entry.get("runtime")
        if isinstance(rt, str) and rt not in ALLOWED_RUNTIMES:
            warnings.append(f"{mcp_id}: runtime '{rt}' not in recommended set {sorted(ALLOWED_RUNTIMES)}")

        surfaces = entry.get("surfaces")
        if not isinstance(surfaces, dict):
            errors.append(f"{mcp_id}: surfaces must be a mapping")
        else:
            for sn in SURFACE_NAMES:
                if sn not in surfaces:
                    errors.append(f"{mcp_id}: surfaces missing required key '{sn}'")
                    continue
                cfg = surfaces[sn]
                if not isinstance(cfg, dict):
                    errors.append(f"{mcp_id}.surfaces.{sn}: must be a mapping")
                    continue
                if "enabled" not in cfg:
                    errors.append(f"{mcp_id}.surfaces.{sn}: missing 'enabled'")
                    continue
                en = cfg.get("enabled")
                if not isinstance(en, bool):
                    errors.append(f"{mcp_id}.surfaces.{sn}.enabled: must be a boolean")
                    continue
                if en is False:
                    reason = cfg.get("reason")
                    if not isinstance(reason, str) or not reason.strip():
                        errors.append(
                            f"{mcp_id}.surfaces.{sn}: enabled false requires non-empty 'reason'"
                        )

        req = entry.get("requires")
        if not isinstance(req, list) or not all(isinstance(x, str) for x in req):
            errors.append(f"{mcp_id}: requires must be a list of strings")

        errors.extend(validate_secrets_list(entry.get("secrets"), mcp_id))

        pp = entry.get("paths_probe")
        if not isinstance(pp, list) or not all(x is None or isinstance(x, str) for x in pp):
            errors.append(f"{mcp_id}: paths_probe must be a list of strings")

        notes = entry.get("notes")
        if notes is None:
            errors.append(f"{mcp_id}: notes must be present (use empty string if nothing to add)")
        elif not isinstance(notes, str):
            errors.append(f"{mcp_id}: notes must be a string")

    missing = EXPECTED_IDS - seen
    extra = seen - EXPECTED_IDS
    if missing:
        errors.append(f"missing required mcp ids: {sorted(missing)}")
    if extra:
        warnings.append(f"unexpected mcp ids (not in minimum union): {sorted(extra)}")

    leak_issues = scan_strings_for_leaks(doc.get("mcps", []))
    errors.extend(leak_issues)

    status = "FAIL" if errors else ("PASS_WITH_WARNINGS" if warnings else "PASS")
    return status, errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate MCP MANIFEST.yaml")
    parser.add_argument(
        "manifest",
        nargs="?",
        default=str(DEFAULT_MANIFEST),
        help="Path to MANIFEST.yaml (default: repo ai/assets/mcps/MANIFEST.yaml)",
    )
    args = parser.parse_args()
    path = Path(args.manifest)

    print(f"==> Validating MCP manifest: {path}")

    if not path.is_file():
        print(f"FAIL manifest file not found: {path}", file=sys.stderr)
        print("\nMCP manifest validation: FAIL")
        return 1

    try:
        doc = load_yaml(path)
    except SystemExit as se:
        return int(se.code) if isinstance(se.code, int) else 1
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL could not parse YAML: {exc}", file=sys.stderr)
        print("\nMCP manifest validation: FAIL")
        return 1

    status, errors, warnings = validate_manifest(doc)

    for w in warnings:
        print(f"WARN {w}")
    for e in errors:
        print(f"FAIL {e}")

    if status == "PASS":
        print("OK manifest structure and policy checks passed")
    elif status == "PASS_WITH_WARNINGS":
        print("OK manifest passed with warnings (see above)")
    else:
        print("FAIL manifest validation errors (see above)")

    print(f"\nMCP manifest validation: {status}")
    return 0 if status != "FAIL" else 1


if __name__ == "__main__":
    raise SystemExit(main())
