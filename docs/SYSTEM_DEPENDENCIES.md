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

## Current operational examples

- APT baseline: `git`, `zsh`, `tmux`, `python3`, `python3-pip`, `bubblewrap`, `ripgrep`, `fd-find`.
- Non-APT tooling: `chezmoi`, `uv`, `node`, `npm`, `corepack`, `pnpm`, `codex`, `gitnexus`, `opencode`, `docker`.
- WSL/Windows-side: `wslpath`, `powershell.exe`, `wt.exe`.

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
