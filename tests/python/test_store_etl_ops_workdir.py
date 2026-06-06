#!/usr/bin/env python3
import importlib.util
import os
import sys
import tempfile
import types
import unittest
from pathlib import Path

DOTFILES_DIR = Path(__file__).resolve().parents[2]
SERVER_PATH = DOTFILES_DIR / "ai/runtime/mcp/servers/store_etl_ops/server.py"

EXPECTED_ALLOWED_TARGETS = {
    "hydration-observability-report",
    "hydration-domain-workflow",
    "frontier-to-gold-domain-centric",
    "hydration-recover-failed-reviews",
    "db-reset-from-zero",
}


def install_mcp_import_stub() -> None:
    if "mcp.server.fastmcp" in sys.modules:
        return

    class FastMCP:
        def __init__(self, name: str) -> None:
            self.name = name

        def tool(self, *_args, **_kwargs):
            def decorator(fn):
                return fn

            return decorator

        def run(self, **_kwargs) -> None:
            return None

    fastmcp = types.ModuleType("mcp.server.fastmcp")
    fastmcp.FastMCP = FastMCP
    server = types.ModuleType("mcp.server")
    server.fastmcp = fastmcp
    mcp = types.ModuleType("mcp")
    mcp.server = server
    sys.modules["mcp"] = mcp
    sys.modules["mcp.server"] = server
    sys.modules["mcp.server.fastmcp"] = fastmcp


def load_server_module():
    install_mcp_import_stub()
    module_name = "store_etl_ops_server_test"
    if module_name in sys.modules:
        return sys.modules[module_name]

    spec = importlib.util.spec_from_file_location(module_name, SERVER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load module from {SERVER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


def make_store_etl_repo(root: Path) -> Path:
    repo = root / "store-etl"
    repo.mkdir(parents=True)
    (repo / "Makefile").write_text(".PHONY: test\ntest:\n\t@echo ok\n", encoding="utf-8")
    return repo


class StoreEtlOpsWorkdirTests(unittest.TestCase):
    def setUp(self):
        self._env_backup = os.environ.get("STORE_ETL_WORKDIR")
        if "STORE_ETL_WORKDIR" in os.environ:
            del os.environ["STORE_ETL_WORKDIR"]
        self.module = load_server_module()

    def tearDown(self):
        if self._env_backup is None:
            os.environ.pop("STORE_ETL_WORKDIR", None)
        else:
            os.environ["STORE_ETL_WORKDIR"] = self._env_backup

    def test_default_uses_fallback_path_when_env_unset(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = make_store_etl_repo(Path(tmp))
            original_default = self.module.DEFAULT_STORE_ETL_WORKDIR
            self.module.DEFAULT_STORE_ETL_WORKDIR = repo
            try:
                resolved = self.module.resolve_store_etl_workdir()
            finally:
                self.module.DEFAULT_STORE_ETL_WORKDIR = original_default

        self.assertEqual(resolved, repo.resolve())

    def test_store_etl_workdir_expands_tilde_and_resolves_absolute(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            repo = make_store_etl_repo(home)
            os.environ["STORE_ETL_WORKDIR"] = "~/store-etl"

            previous_home = os.environ.get("HOME")
            os.environ["HOME"] = str(home)
            try:
                resolved = self.module.resolve_store_etl_workdir()
            finally:
                if previous_home is None:
                    os.environ.pop("HOME", None)
                else:
                    os.environ["HOME"] = previous_home

        self.assertTrue(resolved.is_absolute())
        self.assertEqual(resolved, repo.resolve())

    def test_store_etl_workdir_resolves_relative_path_from_cwd(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            repo = make_store_etl_repo(base)
            os.environ["STORE_ETL_WORKDIR"] = "store-etl"

            previous_cwd = Path.cwd()
            os.chdir(base)
            try:
                resolved = self.module.resolve_store_etl_workdir()
            finally:
                os.chdir(previous_cwd)

        self.assertEqual(resolved, repo.resolve())

    def test_missing_workdir_returns_clear_error(self):
        missing = "/tmp/store-etl-ops-missing-workdir-test"
        os.environ["STORE_ETL_WORKDIR"] = missing

        with self.assertRaises(FileNotFoundError) as ctx:
            self.module.resolve_store_etl_workdir()

        message = str(ctx.exception)
        self.assertIn("STORE_ETL_WORKDIR", message)
        self.assertIn(missing, message)

    def test_workdir_without_repo_markers_returns_clear_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            empty = Path(tmp) / "empty-dir"
            empty.mkdir()
            os.environ["STORE_ETL_WORKDIR"] = str(empty)

            with self.assertRaises(ValueError) as ctx:
                self.module.resolve_store_etl_workdir()

            message = str(ctx.exception)
            self.assertIn("does not look like a store-etl repository", message)
            self.assertIn("Makefile", message)

    def test_allowed_targets_allowlist_is_unchanged(self):
        self.assertEqual(set(self.module._ALLOWED_TARGETS.keys()), EXPECTED_ALLOWED_TARGETS)

    def test_validate_target_rejects_unknown_target_without_running_make(self):
        with self.assertRaises(ValueError) as ctx:
            self.module._validate_target_and_args("not-allowed-target", None)

        self.assertIn("Unsupported target", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
