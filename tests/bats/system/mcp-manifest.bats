#!/usr/bin/env bats

setup() {
	load '../helpers/common'
	DOTFILES_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
	MANIFEST="${DOTFILES_DIR}/ai/assets/mcps/MANIFEST.yaml"
	VALIDATOR="${DOTFILES_DIR}/scripts/validate-mcp-manifest.py"
}

@test "MANIFEST.yaml exists" {
	[[ -f "${MANIFEST}" ]]
}

@test "validate-mcp-manifest.py exists" {
	[[ -f "${VALIDATOR}" ]]
}

@test "install.mk defines ai-mcp-validate target" {
	[[ -f "${DOTFILES_DIR}/install.mk" ]]
	run grep -q '^ai-mcp-validate:' "${DOTFILES_DIR}/install.mk"
	[[ "${status}" -eq 0 ]]
}

@test "make ai-mcp-validate invokes the validator" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run make -C "${DOTFILES_DIR}" ai-mcp-validate
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"MCP manifest validation: PASS"* ]] || [[ "${output}" == *"PASS_WITH_WARNINGS"* ]]
}

@test "validator passes on repo MANIFEST.yaml" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run python3 "${VALIDATOR}" "${MANIFEST}"
	[[ "${status}" -eq 0 ]]
}

@test "validator fails when a surface is disabled without reason" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run python3 - "${DOTFILES_DIR}" <<'PY'
import pathlib
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    sys.exit(3)

root = pathlib.Path(sys.argv[1])
src = root / "ai/assets/mcps/MANIFEST.yaml"
doc = yaml.safe_load(src.read_text(encoding="utf-8"))
doc["mcps"][0]["surfaces"]["cursor"] = {"enabled": False}
_, path = tempfile.mkstemp(suffix=".yaml")
pathlib.Path(path).write_text(yaml.dump(doc, sort_keys=False), encoding="utf-8")
validator = root / "scripts/validate-mcp-manifest.py"
r = subprocess.run([sys.executable, str(validator), path], capture_output=True, text=True)
sys.exit(0 if r.returncode == 1 else 1)
PY
	[[ "${status}" -eq 0 ]]
}

@test "validator fails on duplicate mcp ids" {
	if ! python3 -c "import yaml" 2>/dev/null; then
		skip "PyYAML not installed"
	fi
	run python3 - "${DOTFILES_DIR}" <<'PY'
import pathlib
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    sys.exit(3)

root = pathlib.Path(sys.argv[1])
src = root / "ai/assets/mcps/MANIFEST.yaml"
doc = yaml.safe_load(src.read_text(encoding="utf-8"))
first = doc["mcps"][0]
doc["mcps"] = [first, first] + doc["mcps"][1:]
_, path = tempfile.mkstemp(suffix=".yaml")
pathlib.Path(path).write_text(yaml.dump(doc, sort_keys=False), encoding="utf-8")
validator = root / "scripts/validate-mcp-manifest.py"
r = subprocess.run([sys.executable, str(validator), path], capture_output=True, text=True)
sys.exit(0 if r.returncode == 1 else 1)
PY
	[[ "${status}" -eq 0 ]]
}
