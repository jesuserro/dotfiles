# ADR: MCP Runtime-Managed vs Installed

**Date:** 2026-06-07  
**Status:** Accepted  
**Author:** jesus

---

## Context

MCP servers are integrated via multiple execution models: persistent installs (`uv tool install`, npm global), local Python runtimes under `ai/runtime/mcp/`, Chezmoi-managed launchers, and ephemeral invocation (`uvx`, `npx`). Mixing models causes drift between `MANIFEST.yaml`, update scripts, and agent configs.

`mcp-server-fetch` was a recurring case: treating it as a persistent `uv tool` conflicted with the runtime-managed contract.

---

## Decision

### 1. MANIFEST as SSOT

`ai/assets/mcps/MANIFEST.yaml` defines each MCP's `runtime`, `layer`, `category`, and surfaces. Taxonomy rules live in `docs/MCP_TAXONOMY.md`; generated configs must match manifest intent.

### 2. Runtime-managed MCPs

MCPs classified as **runtime-managed** (e.g. `fetch` via `uvx`) are invoked on demand. `make update` must **not** install them as persistent global tools.

### 3. Installed vs local vs launcher

| Model | Example | Update responsibility |
|-------|---------|----------------------|
| Runtime-managed (`uvx`/`npx`) | `fetch` | None persistent; version pinned in manifest/launcher |
| Local Python runtime | `store_etl_ops` | `ai/runtime/mcp/` + Chezmoi apply |
| Chezmoi launcher | `postgres`, `git` | Template sync + apply acotado |

---

## Consequences

### Positive

- Consistent docs, manifest, and `update-wsl` behavior
- Fewer orphaned global tool installs

### Negative

- Each new MCP needs explicit runtime classification in manifest

### Neutral

- Complements ADR 0001 (layer governance); does not replace it

---

## References

- MCP governance ADR: `docs/adr/0001-mcp-governance.md`
- Manifest: `ai/assets/mcps/MANIFEST.yaml`
- Taxonomy: `docs/MCP_TAXONOMY.md`, `docs/MCP_QUICKREF.md`
- Tests: `tests/bats/docs/mcp-taxonomy-consistency.bats`, `tests/bats/system/update-workflow.bats`
