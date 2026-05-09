# MCP Quick Reference

**For AI agents working with this dotfiles repository**

## Canonical intent (SSOT)

- **`ai/assets/mcps/MANIFEST.yaml`** — single source of truth for **which** MCPs exist and **how** they are intended on **cursor**, **codex**, and **opencode** (all compatible servers **enabled by default** unless a surface has a documented `enabled: false` + `reason`).
- **`make ai-mcp-validate`** — validates that manifest (schema, ids, surfaces, secrets shape). Requires **PyYAML**. Non-mutating.
- **`make ai-mcp-render`** — dry-run: writes `build/mcps/dot_cursor/mcp.json.tmpl`, `build/mcps/dot_codex/mcp_servers.toml.tmpl` (MCP fragment only), `build/mcps/dot_config/opencode/opencode.json.tmpl` from `MANIFEST.yaml` plus **Python recipes** in `scripts/generate-mcp-configs.py`. Does **not** overwrite Chezmoi templates. `build/mcps/` is gitignored.
- **`make ai-mcp-drift`** — runs render, compares intent + recipes vs current templates, prints a human drift report and `build/mcps/drift-report.json`. **`exit 0`** when differences are only **`INTENTIONAL_PENDING_PARITY`** (expected until real template parity). **`exit 1`** on **`UNEXPECTED_DRIFT`** (e.g. extra MCP in template, or command/env/cwd mismatch when both sides are active). **`exit 2`** if PyYAML is missing.
- **Chezmoi templates** (`dot_cursor/mcp.json.tmpl`, `dot_codex/config.toml.tmpl`, `dot_config/opencode/opencode.json.tmpl`) are **not yet overwritten** by the generator; use **validate → render → drift** to review evidence before any future apply phase. Readiness for a live machine remains **`make ai-cursor-check`** (Cursor HOME + templates).

**Suggested flow:** `make ai-mcp-validate` → `make ai-mcp-render` → `make ai-mcp-drift` → read stdout / `drift-report.json` → later, human-approved parity updates templates (not automated in this phase).

## Classification (layers)

Layers describe *purpose*; default **activation** for global agents follows the manifest policy above (compatible = enabled). Readiness checks surface missing services, secrets, or binaries as WARN/MISSING/FAIL (`STRICT=1`), not by hiding MCPs from a surface.

| Layer | Scope | Examples |
|-------|-------|----------|
| Core | All projects | docker, github, fetch, context7, excalidraw, playwright, filesystem, git, sequential-thinking |
| Knowledge/Semantic | All projects | gitnexus |
| Domain | Optional vault path | obsidian |
| Platform | Local services | dagster, loki, minio, prometheus, tempo, store_etl_ops |
| Connection | DB / engines | postgres, trino |

## GitNexus

| Aspect | Value |
|--------|-------|
| **Type** | Knowledge/Semantic MCP |
| **Scope** | Global (multi-repo) |
| **Config Pattern** | `npx -y gitnexus@latest mcp` |
| **Index Location** | `~/.gitnexus/` |
| **CLI** | Installed via npm in `~/.local` |
| **Wiki Output** | `docs/wiki/` (per project) |
| **LLM Required** | Yes (OpenAI API key for wiki) |

### GitNexus Helpers

```bash
ups              # Updates GitNexus CLI
gnx-serve        # Start local server
gnx-analyze-here # Analyze current repo
gnx-map          # Analyze + serve
gnx-wiki-here    # Generate wiki (requires OPENAI_API_KEY)
```

## Filesystem MCP

| Aspect | Value |
|--------|-------|
| **Type** | Core MCP (filesystem access) |
| **Scope** | Global with whitelist policy |
| **Config Pattern** | Launcher wrapper |
| **Allowed Roots** | `/home/jesus/dotfiles`, `/home/jesus/proyectos`, `/home/jesus/.config`, `/mnt/c/Users/jesus/Documents/vault` |
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
| **Config Pattern** | `npx -y @bitbonsai/mcpvault /mnt/c/Users/jesus/Documents/vault` |
| **Enabled (manifest intent)** | true on all surfaces (vault path must exist for usefulness) |
| **Vault** | `/mnt/c/Users/jesus/Documents/vault` (readiness WARN if missing under WSL) |

### Relationship with Filesystem MCP

- **Filesystem MCP**: Provides raw file access to vault directory
- **mcpvault**: Provides semantic operations (notes, frontmatter, tags, search)

These are complementary, not interchangeable. Enable both for full Obsidian integration.

## Anti-Patterns

- ❌ Hardcoded production secrets in repo files or in `MANIFEST.yaml` (only paths / `keys_hint`)
- ❌ Silently omitting an MCP from a surface without a documented `reason`
- ❌ Client-named secrets for new work (prefer neutral `mcp-secrets.env` / documented paths)

## Verificar readiness para Cursor

Comprueba **sin mutar el sistema** si el entorno está alineado con lo que publican los dotfiles para Cursor (MCP global, skills, comandos). No instala dependencias, no ejecuta Cursor ni los servidores MCP, no imprime secretos.

```bash
cd ~/dotfiles
make ai-cursor-check
STRICT=1 make ai-cursor-check
```

- **Paridad real vs manifiesto**: hasta que exista el generador, las plantillas pueden seguir con menos MCPs que el manifiesto; `ai-cursor-check` sigue informando recuentos como `INFO`. La intención canónica vive en `ai/assets/mcps/MANIFEST.yaml` (`make ai-mcp-validate`).
- Si falta `~/.cursor/mcp.json`, lo más probable es que no se haya aplicado Chezmoi con la fuente del repo: `make install-dotfiles DOTFILES_APPLY=1` o `chezmoi --source=$HOME/dotfiles apply`.

## Key Files

- `ai/assets/mcps/MANIFEST.yaml` — Canonical MCP intent (per surface)
- `scripts/validate-mcp-manifest.py` — Manifest validator
- `scripts/generate-mcp-configs.py` — Dry-run render + drift (`render` / `drift` subcommands)
- `docs/MCP_TAXONOMY.md` — Taxonomy and evolution notes
- `docs/adr/0001-mcp-governance.md` — ADR (includes supersession notes)
- `docs/OPENCODE.md` — Operational guide
- `ai/assets/skills/mcp-governance/SKILL.md` — Skill for agents

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
5. Later: regenerate Chezmoi templates from the manifest (planned phase).
6. Legacy: `bin/validate-mcp-governance` still exists and will be reconciled with the manifest.
