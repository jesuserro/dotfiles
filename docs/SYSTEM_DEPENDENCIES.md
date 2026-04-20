# System Dependencies

This repository now keeps a small declarative inventory of intentional system dependencies under `system/packages/`.

The goal is simple: document the packages a fresh machine needs for these dotfiles to work well, without turning the repo into a full configuration-management framework.

## What counts as a dependency here

This layer tracks intentional packages that the repo expects or benefits from directly.

It does not try to export every package installed on a machine, and it avoids capturing transitive OS noise.

## Inventories

- `system/packages/common.yaml`: base packages that are part of the expected workstation/tooling baseline.
- `system/packages/ubuntu.yaml`: Ubuntu/Debian package names and additions that matter on apt-based systems.

Each entry is intentionally small:

- `package`: concrete package-manager name to install, for example `fd-find`
- `command`: binary expected in `PATH`, for example `fdfind`
- `required`: whether missing it should fail the dependency check
- `capability`: short grouping label for future growth
- `note`: brief human context

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

## Install on Ubuntu/Debian

Install required packages from the declarative inventory:

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

## How to extend the inventory

When adding a dependency:

1. Put it in the smallest inventory file that makes sense.
2. Add only intentional packages that the repo or its documented workflows really use.
3. Prefer a short note that explains why the package exists.
4. Mark it optional unless the repo genuinely depends on it for normal use.

If the package name is distro-specific, keep that detail in the distro inventory instead of polluting the common one.

## Bubblewrap note

`bubblewrap` is tracked explicitly because Codex on Linux/WSL may rely on `bwrap` for sandboxing. If it is missing, agent workflows can degrade or warn even when the rest of the shell environment looks healthy.

Optional packages are still reported by the checker, but they do not make the command fail.
