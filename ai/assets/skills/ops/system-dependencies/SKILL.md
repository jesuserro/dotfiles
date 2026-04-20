---
name: dotfiles-system-dependencies
description: Guía operativa para verificar, instalar y mantener la capa declarativa de dependencias del sistema en dotfiles. Úsala cuando falten comandos del sistema, aparezcan warnings por binarios ausentes, se prepare una máquina nueva o se añada tooling que requiera nuevas dependencias intencionales.
---

# Dotfiles System Dependencies

## Purpose

Provide a short operational guide for working with the declarative system dependency layer in `dotfiles`.

This layer answers what a machine needs for the repo to work in practice, without exporting the full host package set.

## When to Use

- When a command such as `rg`, `fdfind`, `sops`, `bwrap`, or `pipx` is missing.
- When an agent sees a warning caused by an unavailable system binary.
- When preparing a new Ubuntu/Debian or WSL machine for this repo.
- When adding new tooling to `dotfiles` that depends on an intentional system package.

## Source of Truth

- `system/packages/common.yaml`
- `system/packages/ubuntu.yaml`
- Operational doc: [docs/SYSTEM_DEPENDENCIES.md](../../../docs/SYSTEM_DEPENDENCIES.md)

Read the inventory before proposing changes. `package` is the concrete install name and `command` is the binary expected in `PATH`.

## Operational Commands

Verify required dependencies:

- `scripts/check-system-deps.sh`
- `make deps-check`

Verify required and optional dependencies:

- `scripts/check-system-deps.sh --include-optional`
- `make deps-check DEPS_CHECK_ARGS=--include-optional`

Install required packages on Ubuntu/Debian:

- `scripts/install-system-packages.sh`
- `make deps-install`

Preview installation first:

- `scripts/install-system-packages.sh --dry-run`
- `make deps-install DEPS_INSTALL_ARGS=--dry-run`

## Recommended Agent Pattern

1. Run the dependency check first.
2. Interpret missing required packages as actionable setup gaps.
3. Treat optional packages as useful but non-blocking unless the user task specifically needs them.
4. If installation is appropriate, prefer a dry run before invoking the real Ubuntu/Debian installer.
5. If a new dependency is truly intentional, add it to the smallest correct inventory file and keep the note brief and specific.

## Interpretation Rules

- `OK`: required dependency present.
- `MISS`: required dependency missing and should block a clean setup.
- `INFO`: optional dependency present.
- `SKIP`: optional dependency missing; report it without treating it as a hard failure.
- When `package` and `command` differ, read the output as `package -> command`, for example `fd-find -> fdfind` or `bubblewrap -> bwrap`.

## Rules

- Do not add packages to the inventory without clear repo-level justification.
- Do not export or freeze the full host package list.
- Prefer intentional dependencies over convenience noise.
- Keep `required` vs `optional` honest.
- Use concrete Ubuntu/Debian package names in the apt-backed inventory.
- Treat `bubblewrap` as the canonical example of a real dependency discovered from an operational warning rather than from package mining.

## What Not to Do

- Do not add multi-distro abstraction unless the repo genuinely needs it.
- Do not bypass the declarative inventory with ad hoc package lists in docs or aliases.
- Do not treat optional absences as setup failures by default.
- Do not change `system/packages/*.yaml` just to mirror one workstation.

## Example Flow

If Codex warns that `bubblewrap` is missing:

1. Check whether `bubblewrap` is already declared in `system/packages/ubuntu.yaml`.
2. Run `scripts/check-system-deps.sh --include-optional`.
3. If `bubblewrap -> bwrap` is missing and the machine is Ubuntu/Debian, propose `scripts/install-system-packages.sh --dry-run`.
4. Install if appropriate with `scripts/install-system-packages.sh`.
5. Re-run the check to confirm the environment is healthy.
