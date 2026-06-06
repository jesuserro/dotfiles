#!/usr/bin/env python3
"""Auxiliary parser for package-level WinGet results from a captured upgrade log.

The productive Windows update parser lives in scripts/update/update-windows.ps1.
This helper is for WSL-side diagnostics and tests; it is not a Windows runtime
dependency.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def read_text(path: Path) -> str:
    data = path.read_bytes()
    if data.startswith((b"\xff\xfe", b"\xfe\xff")) or data[:200].count(b"\x00") > 20:
        encodings = ("utf-16", "utf-8-sig", "utf-8", "cp1252")
    else:
        encodings = ("utf-8-sig", "utf-8", "cp1252", "utf-16")
    for encoding in encodings:
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            continue
    return data.decode("utf-8", errors="replace")


def parse(text: str) -> list[tuple[str, str, str]]:
    results: list[tuple[str, str, str]] = []
    current: tuple[str, str] | None = None
    found_re = re.compile(r"^\(\d+/\d+\)\s+(?:Encontrado|Found)\s+(.+?)\s+\[([^\]]+)\]", re.I)
    code_re = re.compile(r"(?:c[oó]digo de salida|exit code|salida):\s*(-?\d+)", re.I)
    success_re = re.compile(r"(?:Se instal.*correctamente|Successfully (?:installed|updated))", re.I)

    for raw_line in text.replace("\r", "\n").splitlines():
        line = raw_line.strip("\x00 ")
        found = found_re.search(line)
        if found:
            current = (found.group(1).strip(), found.group(2).strip())
            continue
        if current is None:
            continue
        code = code_re.search(line)
        if code:
            name, package_id = current
            results.append(("WARN", f"WinGet package {name} [{package_id}]", f"upgrade failed with code {code.group(1)}"))
            current = None
            continue
        if success_re.search(line):
            name, package_id = current
            results.append(("OK", f"WinGet package {name} [{package_id}]", "updated successfully"))
            current = None
    return results


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: parse-winget-log.py <windows-winget-upgrade.log>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if not path.is_file():
        return 0
    for status, name, message in parse(read_text(path)):
        print(f"{status}\tWindows\t{name}\t{message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
