---
name: dotfiles-operations
description: Guía operativa canónica para dotfiles en Ubuntu/WSL2. Úsala para máquina nueva o existente, Chezmoi apply, secretos SOPS, MCPs, make update vs apply, y validaciones. No uses rcup/RCM (legacy).
---

# Dotfiles operations

## When to Use

- Operar el repo `~/dotfiles` fuera de un bootstrap puntual (día a día).
- Decidir entre `source ~/.zshrc`, `chezmoi apply`, `make update` o `sops`.
- Tras `git pull` con cambios en plantillas, secretos o MCPs.
- Troubleshooting Docker/Postgres MCP o `mcp-secrets.env`.
- **No** uses para el primer bootstrap completo sin contexto → combina con **`dotfiles-install`**.

> **Legacy:** RCM (`rcup`, `.rcrc`) no es operativo. Chezmoi + SOPS/age es el flujo canónico.

## Three layers

| Layer | Tools | Agent recommends |
|-------|-------|------------------|
| Bootstrap | `make install*`, `make deps-*` | `dotfiles-install` skill |
| Materialize HOME | `chezmoi status` / `diff` / `apply` | `chezmoi --source=$HOME/dotfiles apply` |
| Maintain system/tools | `make update`, checks | `make update` then `source ~/.zshrc` if PATH changed; **not** instead of Chezmoi |

## `source` vs `apply`

| Changed in repo | Action |
|-----------------|--------|
| `zshrc`, `aliases`, `zsh/*` | Edit under `~/dotfiles/` → **`source ~/.zshrc`** (HOME files are symlinks) |
| `dot_*`, `secrets.sops.yaml`, Chezmoi-managed skills/commands | **`chezmoi --source=$HOME/dotfiles apply`** |
| Encrypted secrets | **`sops secrets.sops.yaml`** → **`chezmoi apply -i scripts`** (regenerates env) |
| Windows/WSL, APT, npm global, OMZ, MCP images | **`make update`** |

**Never:** edit `~/.config/mcp-secrets.env` by hand; **`sops -d` to stdout**; recommend **`rcup`**.

## Existing machine (default)

```bash
cd ~/dotfiles && git pull
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" apply
source ~/.zshrc
make ai-cursor-check
# if MANIFEST/templates changed: make ai-mcp-governance
```

Wrapper: `make install-dotfiles DOTFILES_APPLY=1`.

## New machine

Use **`dotfiles-install`**: `make install-check` → opt-in `install-chezmoi`, `install-sops`, `install-zsh-stack` → restore **`~/.config/sops/age/keys.txt` manually** → `sops secrets.sops.yaml` → `make install-dotfiles DOTFILES_APPLY=1` → `make ai-cursor-check`.

RC custom blocked: `ZSH_RC_APPLY=1 chezmoi apply ~/.zshrc ~/.aliases ~/.p10k.zsh`.

## Secrets (SOPS + age)

1. `sops ~/dotfiles/secrets.sops.yaml`
2. `chezmoi --source="$HOME/dotfiles" apply -i scripts`
3. Verify without printing values: `grep -E '^export POSTGRES_DSN=.' ~/.config/mcp-secrets.env`

Empty `mcp.postgres_dsn` → `export POSTGRES_DSN=""` → Postgres MCP reports **`POSTGRES_DSN not set`** (empty secret, not necessarily DB down).

## MCPs (repo → HOME)

```text
MANIFEST.yaml → make ai-mcp-governance → make ai-mcp-generate APPLY=1 → chezmoi apply → make ai-cursor-check
```

Skill detail: **`mcp-governance`**.

| MCP | Agent note |
|-----|------------|
| Docker | Docker Desktop on Windows must be **running**; WSL uses `docker.exe mcp gateway run`. `make update` does not fix a closed Desktop. |
| Postgres | Non-empty `mcp.postgres_dsn` in SOPS; launcher reads generated env. `npm update` does not fix empty DSN. |

## Agent prohibitions

- Do not run `chezmoi apply` unless the user asked to mutate HOME (or task explicitly requires it).
- Do not decrypt/print secrets (`sops -d`, `cat` mcp-secrets.env).
- Do not edit HOME-managed files that should come from Chezmoi templates.
- Do not suggest `rcup` / RCM as operational steps.

## Validations

| Command | When |
|---------|------|
| `make ai-cursor-check` | After apply or MCP/skill changes affecting HOME |
| `make ai-mcp-governance` | After `MANIFEST.yaml` or MCP templates |
| `make test-fast` | After touching scripts/Makefile (not doc-only) |
| `chezmoi diff` | Before apply when impact is unclear |

## References

- [docs/OPERATIONS.md](../../../../docs/OPERATIONS.md) — human SSOT (long form)
- [docs/CHEZMOI.md](../../../../docs/CHEZMOI.md)
- [docs/SECRETS_EXAMPLES.md](../../../../docs/SECRETS_EXAMPLES.md)
- [docs/UPDATE.md](../../../../docs/UPDATE.md)
- Skill: [dotfiles-install](../dotfiles-install/SKILL.md) — bootstrap only
