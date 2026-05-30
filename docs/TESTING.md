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
make install
```

**Requirements:**
- Linux or WSL
- `git` (to clone bats-core)
- `apt-get` **OR** `go` (for shfmt)

**Installs:**
- `bats-core` — cloned to `/tmp`, installed to `~/.local`
- `shellcheck`, `shfmt`, `yamllint`, `gitleaks` — via `make deps-install`
- `actionlint`, `osv-scanner`, `@ast-grep/cli` — via `make install-agent-tools`, which is also part of `make install`

**Limitations:**
- Does not install Go automatically (needs system Go or manual install)
- On non-Debian systems, install APT-backed validation tools manually
- Assumes `~/.local/bin` is in PATH

## Running Tests

### All tests
```bash
make test
```

### Fast tests (excludes chezmoi/* bats and MCP template JSON checks)
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
make agent-validate-changed
make agent-validate
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

| Target | Description |
|--------|-------------|
| `make test` | Preflight + lint + all bats + MCP template JSON validation |
| `make test-fast` | Preflight + lint + bats without `chezmoi/*` tests |
| `make test-lint` | shellcheck + shfmt + yamllint |
| `make ai-doctor` | Read-only agent readiness: dependencies, update readiness, AI/MCPs, skills, commands and `gitleaks` |
| `make quality-check` | Full strict repository quality audit: shellcheck + shfmt check + yamllint + actionlint (`-shellcheck=`) when workflows exist |
| `make security-check` | gitleaks working-tree scan + osv-scanner when supported manifests/lockfiles exist |
| `make agent-validate-changed` | Practical agent gate: changed shell/YAML/workflow files + relevant focused tests + full security scan |
| `make agent-validate` | Full repository validation: quality-check + security-check |
| `make test-bats` | All bats tests (includes chezmoi hooks) |
| `make test-chezmoi` | Chezmoi bats + `chezmoi-templates` |
| `make test-ci` | Lint + CI bats subset + chezmoi (GitHub Actions) |
| `make test-install` | Install dependencies |
| `make fmt-shell` | Format shell scripts |
| `make test-ci` | Full suite with JUnit/XML output (for CI) |

## Lint Policy

| Tool | Reports | Fails build |
|------|---------|-------------|
| shellcheck | `WARN` per file | No |
| shfmt | `DIFF` per file | No |
| yamllint | YAML diagnostics | Yes |
| actionlint | Workflow diagnostics | Yes |
| gitleaks | Secret findings | Yes |
| osv-scanner | Vulnerability findings | Yes |

`make ai-doctor` is the read-only readiness check for agents before implementation. It does not replace targeted tests for the area being changed; it aggregates environment, AI/MCP, skills, commands and `gitleaks` checks so secret leaks are caught before handing off changes.

`make quality-check` and `make agent-validate` are full-repository audits. They are intentionally strict, and can surface existing shellcheck/shfmt debt until that cleanup is handled separately.

`make agent-validate-changed` is the practical post-change gate for agents: it checks only shell scripts changed since `HEAD` with shellcheck/shfmt, checks changed YAML/workflows, runs focused dependency/MCP tests when relevant paths changed, and still runs the full security scan. It uses installed tools when present; on a partially bootstrapped machine it may use temporary verified fallbacks for `yamllint`, `actionlint`, `osv-scanner`, and `gitleaks` so the gate remains useful without installing into `HOME`.

Chezmoi `.tmpl` files are not sent raw to shellcheck/shfmt because Go template syntax can confuse those tools. Template rendering/drift remains covered by `make test-chezmoi`, `make ai-mcp-render`, and `make ai-mcp-drift`.

Gitleaks uses the default rules plus the repo-local `.gitleaks.toml`. The only current path allowlist is `.gitnexus/`, a generated local code-index cache that is not a source-of-truth repo artifact.

## Output Modes

| Target | Output | Use case |
|--------|--------|----------|
| `make test` | Human-readable | Local development |
| `make test-bats` | Human-readable | Local debugging |
| `make test-ci` | JUnit/XML | CI/CD pipelines |

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

Pull requests ejecutan [`.github/workflows/test.yml`](../.github/workflows/test.yml): `make ai-mcp-governance` y `make test-ci` (lint, MCP/launchers, chezmoi hooks, skills canónicos).

## Next candidates

- Tests for `scripts/*.sh` (git workflow, install scripts)
- Deeper chezmoi tests (`chezmoi apply --dry-run` in temp HOME)
- Integration tests with actual MCP servers
