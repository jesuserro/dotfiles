# Testing

## Stack

| Tool | Purpose |
|------|---------|
| **bats-core** | Shell testing framework |
| **shellcheck** | Static analysis for shell scripts |
| **shfmt** | Shell script formatter |

## Installation

```bash
make test-install
```

**Requirements:**
- Linux or WSL
- `git` (to clone bats-core)
- `apt-get` **OR** `go` (for shfmt)

**Installs:**
- `bats-core` — cloned to `/tmp`, installed to `~/.local`
- `shellcheck` — via apt-get if available
- `shfmt` — via apt-get if available, otherwise via `go install`

**Limitations:**
- Does not install Go automatically (needs system Go or manual install)
- On non-Debian systems, install `shellcheck` and `shfmt` manually
- Assumes `~/.local/bin` is in PATH

## Running Tests

### All tests
```bash
make test
```

### Fast tests (excludes chezmoi smoke tests)
```bash
make test-fast
```

### Lint only
```bash
make test-lint
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
| `make test` | Full test suite |
| `make test-fast` | Lint + bats (no chezmoi) |
| `make test-lint` | shellcheck + shfmt |
| `make test-bats` | All bats tests |
| `make test-chezmoi` | Chezmoi smoke tests |
| `make test-install` | Install dependencies |
| `make fmt-shell` | Format shell scripts |

## Coverage

### Current
- **MCP Launchers**: `mcp-filesystem-launcher`, `mcp-git-launcher`
- **MCP Governance**: `validate-mcp-governance`
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

## Next candidates

- Tests for `scripts/*.sh` (git workflow, install scripts)
- CI integration (GitHub Actions or similar)
- Deeper chezmoi tests (`chezmoi apply --dry-run` in temp HOME)
- Integration tests with actual MCP servers
