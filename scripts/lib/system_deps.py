#!/usr/bin/env python3
"""Helpers for the dotfiles system dependency inventory."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


class InventoryError(Exception):
    """Raised when an inventory file does not match the supported schema."""


def _parse_scalar(raw: str):
    value = raw.strip()
    if value.lower() == "true":
        return True
    if value.lower() == "false":
        return False
    if value.isdigit():
        return int(value)
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        return value[1:-1]
    return value


def _split_key_value(text: str, path: Path, lineno: int):
    if ":" not in text:
        raise InventoryError(f"{path}:{lineno}: expected key: value")
    key, value = text.split(":", 1)
    key = key.strip()
    value = value.strip()
    if not key:
        raise InventoryError(f"{path}:{lineno}: missing key")
    return key, value


def parse_inventory(path_str: str):
    path = Path(path_str)
    if not path.is_file():
        raise InventoryError(f"inventory file not found: {path}")

    data = {"packages": []}
    current_package = None
    in_packages = False

    for lineno, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        indent = len(raw_line) - len(raw_line.lstrip(" "))
        line = raw_line.strip()

        if indent == 0:
            if line == "packages:":
                in_packages = True
                current_package = None
                continue

            key, value = _split_key_value(line, path, lineno)
            data[key] = _parse_scalar(value)
            current_package = None
            in_packages = False
            continue

        if in_packages and indent == 2 and line.startswith("- "):
            entry = {}
            data["packages"].append(entry)
            current_package = entry
            remainder = line[2:].strip()
            if remainder:
                key, value = _split_key_value(remainder, path, lineno)
                current_package[key] = _parse_scalar(value)
            continue

        if in_packages and indent == 4 and current_package is not None:
            key, value = _split_key_value(line, path, lineno)
            current_package[key] = _parse_scalar(value)
            continue

        raise InventoryError(f"{path}:{lineno}: unsupported YAML structure")

    required_top_level = ("schema_version", "platform", "manager")
    missing = [key for key in required_top_level if key not in data]
    if missing:
        joined = ", ".join(missing)
        raise InventoryError(f"{path}: missing top-level keys: {joined}")
    if not isinstance(data["packages"], list):
        raise InventoryError(f"{path}: packages must be a list")

    normalized = []
    for index, package in enumerate(data["packages"], start=1):
        if not isinstance(package, dict):
            raise InventoryError(f"{path}: package entry #{index} must be a mapping")
        for key in ("package", "command"):
            if key not in package or not package[key]:
                raise InventoryError(f"{path}: package entry #{index} missing '{key}'")

        normalized.append(
            {
                "source_file": str(path),
                "platform": str(data["platform"]),
                "manager": str(data["manager"]),
                "package": str(package["package"]),
                "command": str(package["command"]),
                "required": bool(package.get("required", True)),
                "capability": str(package.get("capability", "")),
                "note": str(package.get("note", "")),
            }
        )

    return {"meta": data, "packages": normalized}


def load_packages(paths, include_optional=False, manager=None):
    merged = []
    seen = set()

    for path in paths:
        inventory = parse_inventory(path)
        for package in inventory["packages"]:
            if not include_optional and not package["required"]:
                continue
            if manager and package["manager"] != manager:
                raise InventoryError(
                    f"{package['source_file']}: manager '{package['manager']}' does not match expected '{manager}'"
                )
            key = (package["manager"], package["package"], package["command"])
            if key in seen:
                continue
            seen.add(key)
            merged.append(package)

    return merged


def _command_list(args):
    packages = load_packages(
        args.inventory,
        include_optional=args.include_optional,
        manager=args.manager,
    )
    for package in packages:
        print(
            "\t".join(
                [
                    "required" if package["required"] else "optional",
                    package["package"],
                    package["command"],
                    package["platform"],
                    package["capability"],
                    package["note"],
                    package["source_file"],
                ]
            )
        )


def _command_packages(args):
    packages = load_packages(
        args.inventory,
        include_optional=args.include_optional,
        manager=args.manager,
    )
    for package in packages:
        print(package["package"])


def _command_validate(args):
    payload = {}
    for path in args.inventory:
        payload[path] = parse_inventory(path)
    print(json.dumps(payload, indent=2, sort_keys=True))


def build_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_inventory_args(subparser, allow_manager=True):
        subparser.add_argument(
            "--inventory",
            action="append",
            required=True,
            help="Inventory YAML file. Pass multiple times to merge files.",
        )
        subparser.add_argument(
            "--include-optional",
            action="store_true",
            help="Include optional packages in the output.",
        )
        if allow_manager:
            subparser.add_argument(
                "--manager",
                default=None,
                help="Require a specific manager across all inventories.",
            )

    list_parser = subparsers.add_parser("list", help="Emit merged packages as TSV.")
    add_inventory_args(list_parser)
    list_parser.set_defaults(func=_command_list)

    packages_parser = subparsers.add_parser(
        "packages", help="Emit only package names, one per line."
    )
    add_inventory_args(packages_parser)
    packages_parser.set_defaults(func=_command_packages)

    validate_parser = subparsers.add_parser(
        "validate", help="Validate the inventories and print normalized JSON."
    )
    add_inventory_args(validate_parser, allow_manager=False)
    validate_parser.set_defaults(func=_command_validate)

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    try:
        args.func(args)
    except InventoryError as exc:
        print(f"system_deps.py: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
