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

## What gets checked vs installed

- Installed by `deps-install`: `common.yaml` and `ubuntu.yaml` entries with manager `apt`.
- Checked but not installed by `deps-install`: `tooling.yaml` and `wsl.yaml`.
- Windows-side commands such as `wt.exe` and `powershell.exe` are declared for visibility from WSL, not for Linux-side installation.
- Recommended but not auto-run: `show-system-deps-actions.sh` explains how to reconcile missing `external:*` and `environment:*` entries.

## Current operational examples

- APT baseline: `git`, `zsh`, `tmux`, `python3`, `python3-pip`, `bubblewrap`, `ripgrep`, `fd-find`, `age`, `bats`.
- Non-APT tooling: `chezmoi`, `sops`, `uv`, `node`, `npm`, `corepack`, `pnpm`, `codex`, `gitnexus`, `opencode`, `docker`.
- WSL/Windows-side: `wslpath`, `powershell.exe`, `wt.exe`.

`bats` is the Bats test runner used by `make test-fast` / `make test-bats`. It is intentionally part of the required APT baseline so a fresh machine can validate the repo without extra steps. On Ubuntu/Debian it pulls `parallel` and `sysstat` as transitive APT deps.

## Canonical external guidance

- `chezmoi`: install from the official release flow or `go install github.com/twpayne/chezmoi/v2@latest`
- `sops`: `make install-sops` (preferred, idempotent, no sudo, sha256-verified, pinned version). Direct fallback: download the matching `sops-vX.Y.Z.linux.<arch>` binary from https://github.com/getsops/sops/releases and drop it at `~/.local/bin/sops`. Not in Ubuntu APT repos.
- `uv`: `make install-uv` (preferred, idempotent, never edits rc files). Direct fallback: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `node` / `npm`: install together through your preferred WSL/Ubuntu Node distribution
- `corepack`: `corepack enable`
- `pnpm`: `corepack prepare pnpm@latest --activate`
- `codex`: `npm install -g --prefix="$HOME/.npm-global" @openai/codex@latest`
- `gitnexus`: `npm install -g --prefix="$HOME/.npm-global" gitnexus@latest`
- `opencode`: `curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path`
- `docker`: manual workstation decision on WSL; the repo does not enforce one installer path
- `wt.exe` / `powershell.exe`: Windows-host capabilities used from WSL, not Linux install targets

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

- **Runtime AI** (`~/.config/ai/runtime/.venv`): se mantiene intencionalmente con `python3 -m venv` + `pip install -r requirements.txt` por compatibilidad con `.chezmoiscripts/run_after_10_setup_ai_runtime.sh.tmpl` y la sección correspondiente de `ups`. Migrarlo a `uv` queda como tarea separada.
- **`zsh/30-python.zsh`** (alias `pip='pip3'`, `pyreq()`): no se toca en esta fase para evitar regresiones en sesiones interactivas.

### Cómo lo trata `ups`

`ups` actualiza `uv` con `uv self update` **solo si ya existe** y vive en `$HOME/.local/bin/uv` (instalación oficial). Si falta, sólo informa y sugiere `make install-uv`. Si está en otra ruta (`apt`, `brew`...), informa para que lo actualice su gestor. Nunca lo instala desde `ups`.
