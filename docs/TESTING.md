# Testing

## Stack

| Tool | Purpose |
|------|---------|
| **bats-core** | Shell testing framework |
| **shellcheck** | Static analysis for shell scripts |
| **shfmt** | Shell script formatter |
| **yamllint** | YAML validation |
| **gitleaks** | Working-tree secret scanning |
| **actionlint** | GitHub Actions workflow validation |
| **osv-scanner** | Dependency vulnerability scanning |

## Installation

```bash
make install SKIP_EXTERNAL=1
```

**Requirements:**
- Linux or WSL
- `apt-get` for the APT-backed validation baseline

**Installs:**
- `bats`, `shellcheck`, `shfmt`, `yamllint`, `gitleaks` — via the APT baseline used by `make install` / `make deps-install`
- `actionlint`, `osv-scanner`, `@ast-grep/cli` — via the opt-in `make install-agent-tools`

**Limitations:**
- On non-Debian systems, install APT-backed validation tools manually
- Assumes `~/.local/bin` is in PATH

## Running Tests

### All tests
```bash
make test
```

### Fast tests (excludes chezmoi bats; includes system and tmux)
```bash
make test-fast
```

### Lint only
```bash
make test-lint
```

### Agent quality and security checks
```bash
make ai-doctor
make quality-check
make security-check
make shell-audit-check
make agent-validate-changed
make agent-validate
make agent-validate-audit
make agent-validate-full
make agent-validate-report
```

### Bats tests only
```bash
make test-bats
```

### Chezmoi smoke tests only
```bash
make test-chezmoi
```

### Format shell scripts
```bash
make fmt-shell
```

## Targets

### Target matrix

| Target | Runs | Omits / notes | When to use |
|--------|------|---------------|-------------|
| `make test-ci` | `test-lint` + `test-bats-ci` + `chezmoi-templates` | Omits `bats-system` (install/update/zsh), `bats-tmux`, `bats-commands`, `bats-prompts`, `bats-git-ai`, `bats-agent` | **CI parity** — matches [`.github/workflows/test.yml`](../.github/workflows/test.yml) |
| `make test` | `test-deps-check` + `test-lint` + `test-bats` + `chezmoi-templates` | Omits `bats-gitnexus`, `bats-docs`, `bats-agent`, `bats-tmux` | Broad local regression (heavy) |
| `make test-fast` | `test-deps-check` + `test-lint` + `test-bats-fast` | Omits `bats-chezmoi`, `bats-gitnexus`, `bats-docs`, `bats-agent`; **not** a superset of CI | Quick local loop |
| `make test-bats` | Preflight + MCP, chezmoi, skills, commands, git-flow, git-hooks, prompts, system bats | Not all bats files — see orphan note below | Local bats debugging |
| `make agent-validate-changed` | Diff-focused lint + matrix bats + `gitleaks` | Not a full replacement for `test-ci` | **Default post-BUILD** check |
| `make agent-validate` | Broader handoff gate via `scripts/agent-validate-dotfiles.sh` (incl. `bats-docs`, `bats-agent` index) | Heavier than changed-only | Pre-handoff / pre-merge human review |

**Pre-PR recommendation:**

```bash
# Scoped changes
make agent-validate-changed

# Before pushing / CI parity
make test-ci

# Before handoff or larger changes
make agent-validate
```

Some Bats files exist under `tests/bats/` but are **not wired** into `test-bats`, `test-fast`, or `test-ci` (for example `github-identity-check.bats`, `clean-runtime-skills.bats`, `store-etl-ops-workdir.bats`). Wiring them is deferred; run individual `.bats` files manually when needed.

### Other targets

| Target | Description |
|--------|-------------|
| `make test-lint` | shellcheck + zsh -n + shfmt + yamllint |
| `make ai-doctor` | Read-only agent readiness: dependencies, update readiness, AI/MCPs, skills, commands and `gitleaks` |
| `make quality-check` | Full strict repository quality audit: shellcheck + shfmt check + yamllint + actionlint (`-shellcheck=`) when workflows exist |
| `make security-check` | gitleaks working-tree scan + osv-scanner when supported manifests/lockfiles exist (OSV best-effort unless `SECURITY_ONLINE=1`) |
| `make shell-audit-check` | Focused read-only shell audit for agent-maintained shell surfaces, without raw Chezmoi templates or historical drift noise |
| `make agent-validate-audit` | Full strict repository audit: `quality-check` + `security-check` (former `agent-validate` semantics) |
| `make agent-validate-full` | `agent-validate` + `agent-validate-audit` |
| `make agent-validate-report` | Runs validation (default: `make agent-validate`) and writes `build/agent-validation/latest.md`; propagates exit code |
| `make test-chezmoi` | Chezmoi bats + `chezmoi-templates` |
| `make test-install` | Install dependencies |
| `make fmt-shell` | Format shell scripts |

## Lint Policy

| Tool | Reports | Fails build |
|------|---------|-------------|
| shellcheck | `WARN` per file | No |
| shfmt | `DIFF` per file | No |
| yamllint | YAML diagnostics | Yes |
| actionlint | Workflow diagnostics | Yes |
| gitleaks | Secret findings | Yes |
| osv-scanner | Vulnerability findings | Yes (strict modes only) |

`make ai-doctor` is the read-only readiness check for agents before implementation. It does not replace targeted tests for the area being changed; it aggregates environment, AI/MCP, skills, commands and `gitleaks` checks so secret leaks are caught before handing off changes. Because it includes `make update-check`, it also surfaces Node runtime shadowing before long GitNexus re-indexing commands.

`make agent-validate` is the **canonical dotfiles gate** for agents after a BUILD. It orchestrates read-only checks and does not run `chezmoi apply`, `make update`, or package installs. It fails if `.claude/skills/` exists in the checkout (ADR 0004).

`make shell-audit-check` is the focused shell gate for agent changes that touch maintained shell surfaces. It runs `shellcheck -S warning` on tracked shell scripts in `bin/`, `scripts/**/*.sh`, and `tests/bats/**/*.bats`; `shfmt -d` on tracked shell scripts in `bin/` and `scripts/**/*.sh`; and `zsh -n` on `zsh/*.zsh`. It discovers files with `git ls-files`, is read-only, and intentionally excludes raw Chezmoi templates, `.githooks/`, `tmux/`, `termux/`, non-shell files, examples, and Bats shfmt drift.

`dotfiles-apply` is the safe Chezmoi wrapper (preview by default). Tests: `tests/bats/system/dotfiles-apply.bats` (stub `chezmoi`, no real HOME mutation).

Flag conventions (`--check`, `--dry-run`, `DRY_RUN=1`, `--yes`): [SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md). Contract tests: `tests/bats/system/dry-run-guard.bats`, `dotfiles-apply.bats`, `git-hooks/hooks.bats` (`treegen --check`).

Agent-first regression index (meta-tests, no HOME mutation): `make bats-agent` or `bats tests/bats/agent/regression.bats`. Scenario map: [tests/bats/agent/README.md](../tests/bats/agent/README.md). Included in `make agent-validate`.

`make bats-system` includes several system suites (`dotfiles-update.bats`, `playwright-docker.bats`, `update-node-runtime.bats`, and others). Some documented Bats files are still unwired — see the orphan note in the target matrix above. Checkout guard: `make agent-validate` fails early if `.claude/` exists (ADR 0004); remediation `rm -rf .claude/`.

`make agent-validate-changed` is a lighter, diff-focused gate (also invoked inside `make agent-validate`). By default it runs **local** checks only:

- shell scripts changed since `HEAD`: `shellcheck` + `shfmt`
- changed YAML: `yamllint`
- changed GitHub workflows: `actionlint`
- focused bats when paths match [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md) (docs, skills, handoffs, chezmoi, hooks, zsh, update, MCP, deps)
- **local security**: mandatory `gitleaks` working-tree scan

`make agent-validate-audit` (`quality-check` + `security-check`) is the full-repository strict audit. Use before large releases or when hunting repo-wide lint/security debt — not as the default post-BUILD gate.

`make agent-validate-report` wraps an allowlisted validation target and writes `build/agent-validation/latest.md`. Override with `AGENT_VALIDATE_TARGET` using one of: `agent-validate`, `agent-validate-changed`, `agent-validate-full`, `agent-validate-audit`, `test-fast`. The deprecated `AGENT_VALIDATE_CMD` compatibility variable only accepts exact values like `make agent-validate-changed`; arbitrary shell commands are rejected. The report is generated even on failure; the target exits non-zero when validation fails. Override report path in tests with `AGENT_VALIDATE_REPORT_PATH`.

**OSV online is not part of the default agent gate.** The default command does not call `osv-scanner` and does not depend on the OSV API. Agents should use `make agent-validate-changed` after small changes; `make agent-validate` for a full dotfiles handoff check.

To run a strict online dependency scan before closing a change (human or pre-merge), use:

```bash
SECURITY_ONLINE=1 make agent-validate-changed
```

`SECURITY_ONLINE=1` enables `osv-scanner scan source -r` when supported manifests or lockfiles exist. Outcomes:

| OSV result | Meaning | Blocks gate |
|------------|---------|-------------|
| Clean scan | No reported vulnerabilities | No |
| Vulnerability findings | Confirmed dependency issues | Yes |
| `service unavailable` / network errors with exit ≠ 0 | External infrastructure failure | Yes (`SECURITY_ONLINE=1` only) |
| `service unavailable` in output with exit 0 | Incomplete remote resolution; **not** a clean pass | No in default/best-effort; Yes with `SECURITY_ONLINE=1` |
| Tool missing with scan inputs present | Install `osv-scanner` via `make install-agent-tools` | Yes (online mode only) |
| No supported lockfiles | Scan skipped | No |

A failure with `External dependency failure: osv-scanner service unavailable` is **not** a secret leak and **not** a confirmed vulnerability; it means the online scanner could not reach its service. Retry later or validate offline findings separately.

`make security-check` (used by `make agent-validate-audit`) runs the same OSV helper in **best-effort** mode by default: remote outages warn with `not confirmed clean` and do not block the audit. Use `SECURITY_ONLINE=1 make security-check` (or `SECURITY_ONLINE=1 make agent-validate-full`) when a human pre-merge gate must fail on OSV API outages.

The script uses installed tools when present. On a partially bootstrapped machine it may use temporary verified fallbacks for `yamllint`, `actionlint`, `osv-scanner` (online mode only), and `gitleaks` so the gate remains useful without installing into `HOME`.

Chezmoi `.tmpl` files are not sent raw to shellcheck/shfmt because Go template syntax can confuse those tools. Template rendering/drift remains covered by `make test-chezmoi`, `make ai-mcp-render`, and `make ai-mcp-drift`.

Gitleaks uses the default rules plus the repo-local `.gitleaks.toml`. The only current path allowlist is `.gitnexus/`, a generated local code-index cache that is not a source-of-truth repo artifact.

## Output Modes

| Target | Output | Use case |
|--------|--------|----------|
| `make test` | Human-readable | Local development |
| `make test-bats` | Human-readable | Local debugging |
| `make test-ci` | Human-readable CI subset | GitHub Actions parity |

## Coverage

### Current
- **MCP Launchers**: `mcp-filesystem-launcher`, `mcp-git-launcher`
- **MCP governance (manifest + drift)**: `bin/validate-mcp-governance` / `make ai-mcp-governance` (see `tests/bats/mcp/validate-governance.bats`)
- **Chezmoi Scripts**: smoke tests for run_after_* scripts
- **MCP Templates**: syntax validation

### Not yet covered
- Other scripts in `scripts/`
- Full chezmoi apply/dry-run
- Integration with actual MCP servers
- Platform-specific tests

## Adding Tests

1. Create `.bats` file in appropriate category:
   - `tests/bats/mcp/` — MCP-related tests
   - `tests/bats/chezmoi/` — Chezmoi tests

2. Use helpers from `tests/bats/helpers/common.bash`:
   ```bash
   load '../helpers/common'
   
   setup() {
       setup_temp_dir
       # your setup
   }
   
   teardown() {
       teardown_temp_dir
   }
   ```

3. Keep tests:
   - Deterministic
   - Without side effects on real HOME
   - Self-contained

## Principles

1. **No network dependency** — tests should work offline
2. **No HOME pollution** — use temp directories
3. **Fast by default** — expensive tests are optional
4. **Clear failures** — actionable error messages

## CI

Pull requests run [`.github/workflows/test.yml`](../.github/workflows/test.yml): `make ai-mcp-governance`, `make security-gitleaks` (gitleaks-only secret scan — not full `make security-check`), and `make test-ci`. That target is the CI subset (lint, MCP/chezmoi/skills/gitnexus/docs bats, chezmoi-templates). It does **not** run `bats-system` install/update suites or `osv-scanner`. For broader local regression use `make test` or `make test-fast` — neither is equivalent to CI; see the target matrix above.

## Next candidates

- Tests for `scripts/*.sh` (git workflow, install scripts)
- Deeper chezmoi tests (`chezmoi apply --dry-run` in temp HOME)
- Integration tests with actual MCP servers
