# Script conventions — preview, check, and mutating commands

Normative reference for agents and humans operating dotfiles scripts and wrappers.

Related: [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md), [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md), [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md).

---

## 1. Flag semantics

Not every command implements every flag. Use only what the command documents.

| Flag / variable | Meaning | Typical use |
|-----------------|---------|-------------|
| `--check` | Validate state or drift **without writing** | `dotfiles-apply --check`, `scripts/treegen.sh --check` |
| `--dry-run` | Simulate a **mutating** action without applying it | `scripts/install-system-packages.sh --dry-run` |
| `DRY_RUN=1` | Make-level or script env alias for dry-run (underscore only) | `make install DRY_RUN=1`, installer scripts |
| `--yes` | Confirm a mutating action **non-interactively** | `dotfiles-apply --apply --yes` (human/CI explicit only) |
| `--verbose` | More output; **does not** change behaviour | Docker MCP smoke, some CLIs |

### `--check` vs `--dry-run`

- **`--check`** — read-only validation: “is the repo/HOME/artifact already correct?” No simulation of writes.
- **`dry-run` / `DRY_RUN=1`** — the command would mutate something; show the plan without executing installs, apply, or destructive writes.

Read-only validators (`validate-skills-structure.sh`, `make agent-validate`, `make bats-docs`) do **not** need `--dry-run`.

Generators may use `--check` for drift and default/`--write` for output — follow each script’s help.

### Make `DRY_RUN` guard

Use **`DRY_RUN=1`** (underscore). Hyphenated variants (`DRY-RUN=1`, `dry-run=1`) are rejected at Make parse time. Install scripts also force dry-run if a hyphen variant slips through via env.

---

## 2. Agent policy

| Allowed without explicit human instruction | Requires explicit human instruction |
|--------------------------------------------|-------------------------------------|
| `--check`, preview/default modes | `--yes` on any mutating wrapper |
| `dotfiles-apply` / `dotfiles-apply --check` | `dotfiles-apply --apply` / `--apply --yes` |
| `make agent-validate`, `make agent-validate-changed` | `make update`, `dotfiles-update` |
| `make bats-*`, `make test-chezmoi` (no real apply) | `make install*` without `DRY_RUN=1` |
| `DRY_RUN=1` previews | `chezmoi apply`, package installs |
| `scripts/treegen.sh --check` | `scripts/treegen.sh` (writes `STRUCTURE.md`) |

Agents must prefer **fixtures and stubs** in tests; never mutate real HOME in Bats.

---

## 3. Command audit (agent-first ecosystem)

Representative commands only — not an exhaustive inventory.

### Read-only validators

| Command | Safe mode | Risk | Validation |
|---------|-----------|------|------------|
| `make agent-validate` | default | None (read-only gate) | `make agent-validate` |
| `make agent-validate-changed` | default | None | after small diffs |
| `scripts/validate-skills-structure.sh` | default | None | `make bats-skills` |
| `make chezmoi-drift-report` | default | None | `make test-chezmoi` |
| `make update-check` | default | None | in `agent-validate` |
| `make ai-mcp-governance` | default | None (render to `build/`) | MCP bats |

### Generators

| Command | Safe mode | Mutating default | Validation |
|---------|-----------|------------------|------------|
| `scripts/treegen.sh` | `--check` | writes `STRUCTURE.md` | `git-hooks/hooks.bats` |
| `make ai-mcp-render` | validate-only targets | writes `build/mcps/` | `mcp-render-drift.bats` |

### Installers / updaters

| Command | Safe mode | Risk | Validation |
|---------|-----------|------|------------|
| `make install` | `DRY_RUN=1`, `make -n` | APT, clones, downloads | `dry-run-guard.bats`, `install-*.bats` |
| `scripts/install-system-packages.sh` | `--dry-run`, `DRY_RUN=1` | system packages | `dry-run-guard.bats` |
| `scripts/install-agent-skills.sh` | `--dry-run` | network, skills dir | `install-agent-skills.bats` |
| `make update` / `dotfiles-update` | **no safe agent mode** | full system maintenance | human only |
| `make update-ai-skills` | `DRY_RUN=1` | network, external catalog | `operations-cheatsheet.bats` |

### Chezmoi / apply wrappers

| Command | Safe mode | Risk | Validation |
|---------|-----------|------|------------|
| `dotfiles-apply` | default, `--check` | HOME mutation on `--apply` | `dotfiles-apply.bats` |
| `scripts/install-dotfiles.sh` | `DRY_RUN=1` | chezmoi apply | `install-dotfiles.bats` |
| raw `chezmoi apply` | `chezmoi apply --dry-run` (temp HOME in tests only) | HOME mutation | docs contract |

### Linkers / materializers

| Command | Safe mode | Risk | Validation |
|---------|-----------|------|------------|
| `.chezmoiscripts/run_after_*` | inspect templates only | mutates HOME on apply | `make test-chezmoi` |
| `run_after_11_link_ai_assets` | rendered hook tests | symlinks in HOME | `canonical-skills.bats` |

### Git / GitNexus helpers

| Command | Safe mode | Risk | Validation |
|---------|-----------|------|------------|
| `make gitnexus-status` | default | none | `gitnexus-status.bats` |
| `gnx-analyze-here` | **human approval** | index + optional AGENTS blocks | policy docs |
| `scripts/hooks/pre-commit-treegen.sh` | runs on commit | writes `STRUCTURE.md` | `git-hooks/hooks.bats` |

---

## 4. Reference implementation

**`dotfiles-apply`** is the canonical mutating wrapper:

- Default and `--check` → `chezmoi diff` + `status` only.
- `--apply` → interactive `APPLY` confirmation.
- `--apply --yes` → non-interactive apply (human/CI).

See [CHEZMOI.md](CHEZMOI.md) § `dotfiles-apply`.

---

## 5. Tests

| Test file | Contract covered |
|-----------|------------------|
| `tests/bats/system/dry-run-guard.bats` | `DRY_RUN=1` vs hyphen variants; mutating command guards |
| `tests/bats/system/dotfiles-apply.bats` | Chezmoi safe preview/apply |
| `tests/bats/git-hooks/hooks.bats` | `treegen --check` drift without writes |
| `tests/bats/system/install-*.bats` | per-installer `DRY_RUN` / `--dry-run` |
