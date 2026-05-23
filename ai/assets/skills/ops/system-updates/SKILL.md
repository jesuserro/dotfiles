---
name: dotfiles-update-workflow
description: Guides development and operation of the `make update` maintenance workflow in dotfiles, including Windows/WSL coordination, Node/GitNexus, OpenCode, MCP images, and project separation.
---

# Dotfiles Update Workflow

Use this skill when working on or running the dotfiles maintenance flow.

## When to Use

Use this skill when changing or diagnosing the dotfiles `make update` workflow, its scripts, or its public Make targets.

## Public Interface

- `make update` — daily full flow from WSL, with Windows PowerShell tab plus WSL execution and consolidated summary
- `make update-windows` — WinGet plus safe `wsl --update`
- `make update-wsl` — APT, Node/AI tools, OpenCode, shell, uv, MCPs, services
- `make update-projects` — personal repositories such as `jesuserro` and RenderCV
- `make update-check` — non-mutating readiness check

Internal targets such as `update-apt`, `update-tools`, `update-shell`, `update-mcp`, and `update-services` delegate to scripts. Keep logic in `scripts/update/`, not in Make recipes.

## Rules

- Do not recreate the removed `ups` command or compatibility aliases.
- Do not run `wsl --shutdown` from the update flow.
- Keep partial failures non-fatal: record warnings/incidents and continue.
- Treat orchestration failures as fatal only when the flow cannot actually start.
- Keep the personal `jesuserro` project and RenderCV under `make update-projects`, never daily `make update`.
- Preserve OpenCode daily updates through the official installer.
- Validate Node `>=22` before GitNexus updates; NodeSource `24.x` is the workstation baseline.

## Windows/WSL Result Contract

Each full run creates a run directory with logs and TSV result files. PowerShell writes Windows results; WSL reads them before printing the final summary. WinGet package failures must appear as incidents even if the PowerShell tab launched successfully.

## Excalidraw

Excalidraw updates belong in the MCP block as Docker image pulls only. `make update` may run `make excalidraw-update`, but it must not start the canvas.

For Excalidraw operational details, use `ops/excalidraw-mcp-operations/`.
