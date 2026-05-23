# System Dependencies

This repository keeps a small declarative inventory of intentional system dependencies under `system/packages/`.

The goal is simple: document the packages a fresh machine needs for these dotfiles to work well, without turning the repo into a full configuration-management framework.

## What counts as a dependency here

This layer tracks intentional packages that the repo expects or benefits from directly.

It does not try to export every package installed on a machine, and it avoids capturing transitive OS noise.

## Inventories

- `system/packages/common.yaml`: base Ubuntu/WSL packages installed through `apt`.
- `system/packages/ubuntu.yaml`: Ubuntu/Debian-specific `apt` additions.
- `system/packages/tooling.yaml`: important non-APT CLIs used by the repo or by `ups()`.
- `system/packages/wsl.yaml`: WSL-specific interop and Windows-side commands invoked from WSL.

Each entry is intentionally small:

- `package`: concrete package-manager name to install, for example `fd-find`
- `command`: binary expected in `PATH`, for example `fdfind`
- `required`: whether missing it should fail the dependency check
- `capability`: short grouping label for future growth
- `install_method`: optional hint for non-APT or environment-scoped tooling
- `note`: brief human context

## Classification

- `apt`: packages that `deps-install` can install on Ubuntu/Debian.
- `external:*`: user tooling that matters operationally but is not installed by the APT bootstrap, for example `npm`, `curl`, `uv`, `corepack` or a manual installer.
- `environment:*`: commands provided by the runtime environment itself, such as WSL interop or Windows-side binaries exposed inside WSL.

This separation is intentional:

- `deps-install` answers “what APT packages does this Ubuntu/WSL machine need?”
- `deps-check --include-optional` answers “what other CLIs and interop pieces does this workstation use?”
- `deps-actions --include-optional` answers “what is the canonical next step to reconcile what is missing?”

## Verify

Check required dependencies:

```bash
scripts/check-system-deps.sh
```

Include optional packages too:

```bash
scripts/check-system-deps.sh --include-optional
```

From `make`:

```bash
make deps-check
make deps-check DEPS_CHECK_ARGS=--include-optional
```

On WSL, the default check also loads `system/packages/wsl.yaml`. Outside WSL it is ignored.

## Reconcile missing tooling

Show recommended actions for missing dependencies:

```bash
scripts/show-system-deps-actions.sh
scripts/show-system-deps-actions.sh --include-optional
```

From `make`:

```bash
make deps-actions
make deps-actions DEPS_ACTION_ARGS=--include-optional
```

This surface does not install anything. It only gives the canonic next step:

- `apt` entries point back to `scripts/install-system-packages.sh`
- `external:*` entries show the repo-preferred installer or reconciliation command when one exists
- `environment:*` entries explain whether the capability is builtin or host-side

## Install on Ubuntu/Debian

Install required APT packages from the declarative inventory:

```bash
scripts/install-system-packages.sh
```

Preview without changing the system:

```bash
scripts/install-system-packages.sh --dry-run
```

Include optional packages too:

```bash
scripts/install-system-packages.sh --include-optional
```

From `make`:

```bash
make deps-install
make deps-install DEPS_INSTALL_ARGS="--dry-run --include-optional"
```

`deps-install` only installs `apt` inventories. It ignores non-APT tooling and Windows-side/WSL environment entries even if those files are present.

For a full workstation bootstrap, use `make install`: it runs the APT baseline,
the Node.js stack needed by npm-based CLIs, and `make install-agent-tools` so
`@ast-grep/cli`, `actionlint` and `osv-scanner` are installed without a second
manual command.

## What gets checked vs installed

- Installed by `deps-install`: `common.yaml` and `ubuntu.yaml` entries with manager `apt`.
- Checked but not installed by `deps-install`: `tooling.yaml` and `wsl.yaml`.
- Windows-side commands such as `wt.exe` and `powershell.exe` are declared for visibility from WSL, not for Linux-side installation.
- Recommended but not auto-run: `show-system-deps-actions.sh` explains how to reconcile missing `external:*` and `environment:*` entries.

## Current operational examples

- APT baseline: `git`, `zsh`, `tmux`, `python3`, `python3-pip`, `bubblewrap`, `ripgrep`, `fd-find`, `age`.
- APT test/lint/security tooling: `bats`, `shellcheck`, `shfmt`, `yamllint`, `gitleaks` (required: true, see "Test/lint dependencies" below).
- Non-APT tooling: `chezmoi`, `sops`, `uv`, `node`, `npm`, `corepack`, `pnpm`, `codex`, `gitnexus`, `@ast-grep/cli`, `actionlint`, `osv-scanner`, `opencode`, `docker`.
- WSL/Windows-side: `wslpath`, `powershell.exe`, `wt.exe`.

## Test/lint dependencies (APT)

`make test-fast` and `make test-lint` rely on small CLIs that are intentionally part of the required APT baseline so a fresh machine can validate the repo without extra steps:

- `bats` — Bats test runner (Ubuntu APT pulls `parallel` and `sysstat` as transitive deps).
- `shellcheck` — shell linter used by `lint-shellcheck`.
- `shfmt` — shell formatter used by `lint-shfmt` / `fmt-shell`.
- `yamllint` — YAML validator for inventories, workflows and visible YAML config.
- `gitleaks` — working-tree secret scanner used by `make security-check`.

A fail-fast preflight (`make test-deps-check`, also wired into `test-fast` / `test-bats` / `test`) verifies the core shell test tools are in `PATH` before running anything, and prints `Run: make install SKIP_EXTERNAL=1` if any is missing. This avoids silent hangs or partial runs on fresh machines.

## Agent validation and security tooling

Agents can run the repo checks without guessing tool commands:

```bash
make quality-check
make security-check
make agent-validate
```

What these cover:

- `make quality-check`: `shellcheck`, `shfmt` in check mode, `yamllint`, and `actionlint -shellcheck=` when `.github/workflows/*.yml|*.yaml` exists. Inline workflow shell is not delegated to actionlint's ShellCheck integration because the repo already has a separate shell lint target and the release workflow embeds changelog text patterns that ShellCheck misparses.
- `make security-check`: `gitleaks detect --no-git --redact` over the working tree and `osv-scanner scan source -r` when supported manifests/lockfiles exist.
- `make agent-validate`: quality + security.

Chezmoi templates are not passed raw to `shellcheck` or `shfmt`; those tools do not reliably parse Go template delimiters. The current shell validation covers real shell scripts, launchers and Bats tests. MCP/Chezmoi template syntax remains covered by the existing `chezmoi-templates`, `ai-mcp-render`, and `ai-mcp-drift` paths.

## Canonical external guidance

- `chezmoi`: `make install-chezmoi` (preferred, idempotent, no sudo, drops the binary at `~/.local/bin/chezmoi`). Direct fallback: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"` or download from https://github.com/twpayne/chezmoi/releases.
- `sops`: `make install-sops` (preferred, idempotent, no sudo, sha256-verified, pinned version). Direct fallback: download the matching `sops-vX.Y.Z.linux.<arch>` binary from https://github.com/getsops/sops/releases and drop it at `~/.local/bin/sops`. Not in Ubuntu APT repos.
- `uv`: `make install-uv` (preferred, idempotent, never edits rc files). Direct fallback: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `node` / `npm`: install together through your preferred WSL/Ubuntu Node distribution
- `azure-cli`: `make install-azure-cli` (opt-in, Debian/Ubuntu/WSL via Microsoft's official Azure CLI repository). It is not part of `make install`; `az login` remains manual.
- `corepack`: `corepack enable`
- `pnpm`: `corepack prepare pnpm@latest --activate`
- `codex`: `npm install -g --prefix="$HOME/.npm-global" @openai/codex@latest`
- `gitnexus`: `npm install -g --prefix="$HOME/.npm-global" gitnexus@latest`
- `@ast-grep/cli`: `make install-agent-tools` or `npm install -g --prefix="$HOME/.npm-global" @ast-grep/cli@latest`
- `actionlint`: `make install-agent-tools` (official `rhysd/actionlint` GitHub release, checksum verified)
- `osv-scanner`: `make install-agent-tools` (official `google/osv-scanner` GitHub release, checksum verified)
- `opencode`: `curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path`
- `docker`: manual workstation decision on WSL; the repo does not enforce one installer path
- `wt.exe` / `powershell.exe`: Windows-host capabilities used from WSL, not Linux install targets

## External version policy

Agent tools that are outside APT follow the repo's existing floating-tooling
policy:

- npm tools use `@latest` in the user npm prefix (`@ast-grep/cli@latest`).
- GitHub Release tools resolve the latest official release at install/update
  time and verify the release checksum before installing (`actionlint`,
  `osv-scanner`).
- `ups` uses the same policy to refresh them.

The inventory records the install channel, not a pinned version. A fully pinned
external-tool lock would require a broader inventory schema change, so it stays
out of this small dependency-layer extension.

## How to extend the inventory

When adding a dependency:

1. Put it in the smallest inventory file that makes sense.
2. Add only intentional packages that the repo or its documented workflows really use.
3. Prefer a short note that explains why the package exists.
4. Mark it optional unless the repo genuinely depends on it for normal use.

If the package name is distro-specific, keep that detail in the distro inventory instead of polluting the common one.

If the dependency is operational but not APT-managed, add it to `tooling.yaml` instead of forcing it into the Linux package bootstrap.

If the dependency only makes sense from WSL because it bridges into Windows, keep it in `wsl.yaml`.

## Bubblewrap note

`bubblewrap` is tracked explicitly because Codex on Linux/WSL may rely on `bwrap` for sandboxing. If it is missing, agent workflows can degrade or warn even when the rest of the shell environment looks healthy.

Optional packages are still reported by the checker, but they do not make the command fail.

## Política Python: uv first, pip fallback

Política transversal del repo para entornos y herramientas Python:

- **`uv` preferido** (Astral) para venvs, lockfiles, herramientas y ejecución de scripts puntuales.
- **`pip`/`pipx`** se conservan instalados como base del sistema (`python3-pip`, `pipx` siguen como APT requeridos) y como **fallback / legado vivo**: ningún script existente que use `pip` se modifica para evitar regresiones.
- **`uv` se queda `required: false`** en el inventario para no romper `STRICT=1 make install-check` en máquinas mínimas. Para instalarlo de forma explícita: `make install-uv`.

## Azure CLI opt-in

`azure-cli` / `az` vive en `system/packages/tooling.yaml` como `external` y
`required: false`. Esto permite verlo con `deps-check --include-optional` y
recibir la recomendación `make install-azure-cli` con `deps-actions
--include-optional`, sin convertir Azure en dependencia base.

Reglas de la Fase 1C:

- `make install`, `make install-check`, `make install-verify`, `make deps-check`
  y `scripts/check-system-deps.sh` no deben fallar porque falte `az`.
- `make install-azure-cli` y `scripts/install-azure-cli.sh` son manuales y
  opt-in; soportan `DRY_RUN=1` y validan que el canal Microsoft exista para el
  codename antes de configurar APT, sin fallback automático.
- `bash scripts/check-azure-tools.sh` puede fallar si falta `az`, porque es el
  check explícito de readiness Azure.
- `az login`, selección de suscripción, extensiones como `containerapp` y
  recursos Azure siguen siendo acciones manuales fuera del bootstrap base.
- `yq` es herramienta recomendada general; su ausencia no bloquea Azure CLI ni
  la instalación de Dotfiles.

### Equivalencias canónicas

| Mundo `pip`/`pipx` | Equivalente `uv` |
|---|---|
| `python -m venv .venv` | `uv venv` |
| `pip install -r requirements.txt` | `uv pip install -r requirements.txt` |
| `pip install <pkg>` (en venv ya activo) | `uv pip install <pkg>` |
| `pipx install <tool>` | `uv tool install <tool>` |
| `pipx run <tool>` | `uvx <tool>` |
| `python script.py` (con proyecto `uv`) | `uv run python script.py` |

### Excepciones explícitas

- **Runtime AI** (`~/.config/ai/runtime/.venv`): se sincroniza con `uv` desde `.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl` usando `uv venv` y `uv pip install -r` solo cuando cambia el hash de `ai/runtime/mcp/requirements.txt` o el venv falta/está incompleto. Si `uv` no está en `PATH`, el hook avisa y no modifica el entorno.
- **`zsh/30-python.zsh`** (alias `pip='pip3'`, `pyreq()`): no se toca en esta fase para evitar regresiones en sesiones interactivas.

### Cómo lo trata `ups`

`ups` actualiza `uv` con `uv self update` **solo si ya existe** y vive en `$HOME/.local/bin/uv` (instalación oficial). Si falta, sólo informa y sugiere `make install-uv`. Si está en otra ruta (`apt`, `brew`...), informa para que lo actualice su gestor. Nunca lo instala desde `ups`.
