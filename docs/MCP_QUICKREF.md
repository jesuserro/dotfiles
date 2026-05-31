# MCP Quick Reference

**For AI agents working with this dotfiles repository**

## Canonical intent (SSOT)

- **`ai/assets/mcps/MANIFEST.yaml`** — single source of truth for **which** MCPs exist and **how** they are intended on **cursor**, **codex**, and **opencode** (all compatible servers **enabled by default** unless a surface has a documented `enabled: false` + `reason`).
- **`make ai-mcp-validate`** — validates that manifest (schema, ids, surfaces, secrets shape). Requires **PyYAML**. Non-mutating.
- **`make ai-mcp-render`** — dry-run: writes `build/mcps/dot_cursor/mcp.json.tmpl`, `build/mcps/dot_codex/mcp_servers.toml.tmpl` (MCP fragment only), `build/mcps/dot_config/opencode/opencode.json.tmpl` from `MANIFEST.yaml` plus **Python recipes** in `scripts/generate-mcp-configs.py`. Does **not** overwrite Chezmoi templates. `build/mcps/` is gitignored.
- **`make ai-mcp-drift`** — runs render, compares intent + recipes vs current templates, prints a human drift report and `build/mcps/drift-report.json`. **`exit 0`** when differences are only **`INTENTIONAL_PENDING_PARITY`**. **`exit 1`** on **`UNEXPECTED_DRIFT`** (e.g. extra MCP in template, or command/env/cwd mismatch when both sides are active). **`exit 2`** if PyYAML is missing.
- **`make ai-mcp-governance`** / **`bin/validate-mcp-governance`** — non-mutating orchestration of **`ai-mcp-validate`**, **`ai-mcp-render`**, and **`ai-mcp-drift`** (same Make contract). Ends with **`MCP governance validation: PASS`** or **`FAIL`**. This is **governance** (repo coherence), not **readiness** (local HOME / Cursor / secrets); use **`make ai-cursor-check`** for the latter.
- **`make ai-mcp-generate`** — **Plan only** by default: prints targets and **`Re-run with APPLY=1`**; writes **nothing** (not even `build/mcps/`). **`make ai-mcp-generate APPLY=1`**: invokes **`scripts/validate-mcp-manifest.py`**, then **`render`**, writes productive templates from `build/mcps/` with temp-file + parse validation + timestamped backups under **`build/mcps/backups/`**, then runs **`drift`** — aborts if validation/render fails, write fails, or **`UNEXPECTED_DRIFT`** remains after write (productive templates must match MANIFEST + recipes). Codex: replaces only **`[mcp_servers.*]`** content; keeps preamble and **`[plugins.*]`**. Then run **`chezmoi apply`** / **`make install-dotfiles DOTFILES_APPLY=1`** to publish HOME, then **`make ai-cursor-check`**.
- **Chezmoi templates** (`dot_cursor/mcp.json.tmpl`, `dot_codex/private_config.toml.tmpl`, `dot_config/opencode/opencode.json.tmpl`) are the **productive** copies in-repo; keep them aligned with **`MANIFEST.yaml`** using **validate → render → drift** (or **`make ai-mcp-governance`**), then **`make ai-mcp-generate APPLY=1`** when you intend to refresh templates from the generator.
- **`make mcp-launcher-contract-check`** — read-only: `bin/` ↔ `dot_local/.../executable_mcp-*-launcher.tmpl` (strict for git/gitnexus/postgres; filesystem dual OK), agent templates must use `~/.local/share/chezmoi/bin/mcp-*-launcher`. HOME drift is WARN only. See [CHEZMOI.md](./CHEZMOI.md) — Launchers MCP materializados.

**Suggested flow:** `make ai-mcp-validate` → `make ai-mcp-render` → `make ai-mcp-drift` → (or **`make ai-mcp-governance`**) → review → **`make ai-mcp-generate APPLY=1`** (only when regenerating templates) → `make ai-mcp-drift` (sanity) → **`chezmoi apply`** (or `make install-dotfiles DOTFILES_APPLY=1`) → `make ai-cursor-check`.

## Classification (layers)

Layers describe *purpose*; default **activation** for global agents follows the manifest policy above (compatible = enabled). Readiness checks surface missing services, secrets, or binaries as WARN/MISSING/FAIL (`STRICT=1`), not by hiding MCPs from a surface.

| Layer | Scope | Examples |
|-------|-------|----------|
| Core | All projects | docker, github, fetch, context7, excalidraw_canvas, playwright, filesystem, git, sequential-thinking |
| Knowledge/Semantic | All projects | gitnexus |
| Domain | Optional vault path | obsidian |
| Platform | Local services | dagster, loki, minio, prometheus, tempo, store_etl_ops |
| Connection | DB / engines | postgres, trino |

## GitNexus

| Aspect | Value |
|--------|-------|
| **Type** | Knowledge/Semantic MCP |
| **Scope** | Global (multi-repo) |
| **Config Pattern** | `mcp-gitnexus-launcher` → binario local `gitnexus mcp` (sin npx en runtime) |
| **Index Location** | `~/.gitnexus/` |
| **CLI** | Installed via npm in `~/.local` |
| **Wiki Output** | `docs/wiki/` (per project) |
| **LLM Required** | Yes (OpenAI API key for wiki) |

### GitNexus Helpers

```bash
make gitnexus-status  # Read-only index/lock/Node status (see GITNEXUS_OPERATIONAL_POLICY.md)
make update-check       # Read-only Node/runtime precheck before re-indexing
gnx-serve               # Start local server (human)
gnx-analyze-here        # Analyze current repo (human only; managed Node)
gnx-map                 # Analyze + serve (human)
gnx-wiki-here           # Generate wiki (human; requires OPENAI_API_KEY)
```

**Agent policy:** [`docs/GITNEXUS_OPERATIONAL_POLICY.md`](./GITNEXUS_OPERATIONAL_POLICY.md) — agents use `make gitnexus-status` and MCP read-only; never auto-run analyze/wiki/clean/npx.

### GitNexus Node precheck

Before re-indexing a stale repo from Cursor, Codex, OpenCode, or another agent-launched shell, run:

```bash
make update-check
```

If it reports an effective Node below `>=22` from an IDE path such as `.cursor-server`, but also reports a managed compatible runtime, prefer the managed helper:

```bash
gnx-analyze-here
```

`gnx-analyze-here` loads the shared Node runtime policy, respects `DOTFILES_MANAGED_NODE_BIN`, and uses a temporary PATH overlay when the shell was launched with an incompatible IDE Node first in `PATH`.

If no compatible managed runtime is available, install or repair the Node stack first (`make install-node-stack`). `make ai-doctor` includes `make update-check`, so it surfaces this warning before agents start a longer GitNexus analyze run.

## Filesystem MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (filesystem access) |
| **Scope** | Global with whitelist policy |
| **Config Pattern** | Launcher wrapper |
| **Allowed Roots** | `/home/jesus/dotfiles`, `/home/jesus/proyectos`, `/home/jesus/.config`, plus vault path from Chezmoi **`ai.obsidian_vault_path`** (rendered in `dot_local/.../executable_mcp-filesystem-launcher.tmpl`; repo `bin/mcp-filesystem-launcher` keeps the same default path for local use) |
| **Launcher** | `~/.local/share/chezmoi/bin/mcp-filesystem-launcher` |

### Policy

- Fixed whitelist: Only directories explicitly listed are accessible
- No dynamic cwd-based access as primary policy
- Additional paths can be passed but must be within allowed roots

## Git MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (Git operations) |
| **Scope** | Global (dynamic repo detection) |
| **Config Pattern** | Launcher wrapper |
| **Detection** | `git rev-parse --show-toplevel` from cwd |
| **Override** | `MCP_GIT_REPO` environment variable |
| **Launcher** | `~/.local/share/chezmoi/bin/mcp-git-launcher` |

### Behavior

- Detects repo from current working directory
- Fails clearly if not inside a Git repository
- Allows explicit override via `MCP_GIT_REPO`

## Sequential Thinking MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (cognitive support) |
| **Scope** | Global |
| **Config Pattern** | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| **Purpose** | Structured reasoning tool for complex problem solving |

### Note

This MCP is from the official MCP repository. It provides cognitive support for reasoning but does not have direct system access.

## Obsidian MCP (mcpvault)

| Aspect | Value |
|--------|-------|
| **Type** | Domain-specific MCP (Obsidian operations) |
| **Scope** | Global optional |
| **Config Pattern** | `npx -y @bitbonsai/mcpvault` + last arg = **`{{ .ai.obsidian_vault_path }}`** (rendered by Chezmoi from `.chezmoi.toml` `[data.ai]`) |
| **Enabled (manifest intent)** | true on all surfaces (vault path must exist for usefulness) |
| **Vault** | Default in repo: `/mnt/c/Users/jesus/Documents/vault_trabajo`; override per machine in `~/.config/chezmoi/chezmoi.toml` — see [CHEZMOI.md](./CHEZMOI.md). Readiness: `make ai-cursor-check` (path from `~/.cursor/mcp.json`). |

### Relationship with Filesystem MCP

- **Filesystem MCP**: Provides raw file access to vault directory
- **mcpvault**: Provides semantic operations (notes, frontmatter, tags, search)

These are complementary, not interchangeable. Enable both for full Obsidian integration.

## Docker MCP (WSL)

- **Requires:** Docker Desktop **running** on Windows; invoke via `docker.exe mcp gateway run` from WSL.
- **`make update` does not fix** a closed Desktop — open Docker Desktop first.
- Smoke: `docker.exe mcp version` · `docker.exe mcp gateway run --dry-run --verbose`

## Postgres MCP

- **Requires:** non-empty `mcp.postgres_dsn` in `secrets.sops.yaml` → `export POSTGRES_DSN=...` in `~/.config/mcp-secrets.env` (generated; do not edit by hand).
- **`POSTGRES_DSN not set` in Cursor** usually means empty/missing secret, not a stopped container.
- Verify without printing value: `grep -E '^export POSTGRES_DSN=.' ~/.config/mcp-secrets.env`
- Fix: `sops secrets.sops.yaml` → `chezmoi apply -i scripts`

## Anti-Patterns

- ❌ Hardcoded production secrets in repo files or in `MANIFEST.yaml` (only paths / `keys_hint`)
- ❌ Editing `~/.config/mcp-secrets.env` manually
- ❌ `sops -d` to stdout
- ❌ Silently omitting an MCP from a surface without a documented `reason`
- ❌ Client-named secrets for new work (prefer neutral `mcp-secrets.env` / documented paths)

## Verificar readiness para Cursor

Comprueba **sin mutar el sistema** si el entorno está alineado con lo que publican los dotfiles para Cursor (MCP global, skills, comandos). No instala dependencias, no ejecuta Cursor ni los servidores MCP, no imprime secretos.

```bash
cd ~/dotfiles
make ai-cursor-check
STRICT=1 make ai-cursor-check
```

- **Paridad plantillas vs manifiesto**: `make ai-mcp-drift` / `make ai-mcp-governance` detectan divergencias; `ai-cursor-check` informa del estado materializado en HOME. La intención canónica vive en `ai/assets/mcps/MANIFEST.yaml` (`make ai-mcp-validate`).
- Si falta `~/.cursor/mcp.json`, lo más probable es que no se haya aplicado Chezmoi con la fuente del repo: `make install-dotfiles DOTFILES_APPLY=1` o `chezmoi --source=$HOME/dotfiles apply`.

## Key Files

- `ai/assets/mcps/MANIFEST.yaml` — Canonical MCP intent (per surface)
- `scripts/validate-mcp-manifest.py` — Manifest validator
- `scripts/generate-mcp-configs.py` — Dry-run render + drift (`render` / `drift` subcommands)
- `bin/validate-mcp-governance` — Wrapper: validate + render + drift (`make ai-mcp-governance`)
- `docs/MCP_TAXONOMY.md` — Taxonomy and evolution notes
- `docs/adr/0001-mcp-governance.md` — ADR (includes supersession notes)
- `docs/OPENCODE.md` — Operational guide
- `ai/assets/skills/ops/mcp-governance/SKILL.md` — Skill for agents

## Runtime vs Connection

```
Runtime (shared) ──▶ Connection (project-specific)
npx/python/wrapper     DSN/credentials/env
```

## Adding MCPs

1. Classify layer (core / knowledge / domain / platform / connection).
2. Add an entry to `ai/assets/mcps/MANIFEST.yaml` with `surfaces.cursor|codex|opencode` and `enabled: false` + `reason` only for real incompatibilities.
3. Use shared runtime paths; keep secret **values** out of the repo (paths and `keys_hint` only).
4. Run `make ai-mcp-validate`.
5. Regenerate Chezmoi MCP templates when needed: `make ai-mcp-generate APPLY=1` (after governance passes).
6. Run `make ai-mcp-governance` or `bin/validate-mcp-governance` before commit when touching MCP intent or templates.
