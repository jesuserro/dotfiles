# Token de GitHub: MCP vs `gh` CLI

## Política actual

- **MCP GitHub (Cursor/Codex/OpenCode):** token classic (`ghp_`) en `secrets.sops.yaml`, materializado como `GITHUB_PERSONAL_ACCESS_TOKEN` en `~/.config/mcp-secrets.env`. Los wrappers lo cargan en su propio proceso.
- **`gh` CLI (terminal):** usa `~/.config/gh/hosts.yml` y `gh auth login` / `gh auth switch`. **No** debe haber `GH_TOKEN` ni `GITHUB_TOKEN` en shells interactivas — esas variables tienen prioridad sobre `hosts.yml` y fuerzan la cuenta equivocada.
- **Fine-grained (`github_pat_`):** deprecado en dotfiles (sin permisos de Projects).

## Identidad por máquina

| Máquina | Usuario GitHub | Comando habitual |
|---------|----------------|------------------|
| Casa | `jesuserro` | `gh auth switch --user jesuserro` |
| Oficina | `jesus-ixatu` | `gh auth switch --user jesus-ixatu` |

Tras cambiar de máquina o aplicar Chezmoi, abre una shell nueva y verifica con `gh auth status`.

## Flujo de secretos MCP

1. **secrets.sops.yaml** → `mcp.github_personal_access_token` (classic, scope `project`)
2. **make install-dotfiles DOTFILES_APPLY=1** → genera `~/.config/mcp-secrets.env` con `GITHUB_PERSONAL_ACCESS_TOKEN` (y DSN/MinIO)
3. **~/.secrets/codex.env** → symlink adaptador hacia `~/.config/mcp-secrets.env` (solo para wrappers MCP)

## Qué token usa cada contexto

| Contexto | Token / auth | Origen |
|----------|--------------|--------|
| `gh` CLI (terminal) | Cuenta activa en `hosts.yml` | `gh auth login` / `gh auth switch` |
| MCP GitHub (Cursor/Codex) | Classic PAT | Wrapper sourcea `mcp-secrets.env` → `GITHUB_PERSONAL_ACCESS_TOKEN` |
| CI (GitHub Actions) | `secrets.GITHUB_TOKEN` | Token automático del workflow |

## Requisitos

- Token classic en `secrets.sops.yaml` con scope `project` (ver [CAMBIAR_TOKEN_GITHUB.md](CAMBIAR_TOKEN_GITHUB.md)).
- No exportar `GH_TOKEN` / `GITHUB_TOKEN` en `~/.zshrc`, `90-local.zsh` ni en el generador de secretos.

## Verificación

```bash
# Shell limpia: no debe haber leak de env
env | grep -E '^(GH_TOKEN|GITHUB_TOKEN)=' && echo LEAK || echo OK

# Identidad gh (sin GH_TOKEN en env)
gh auth status
gh repo view jesuserro/dotfiles --json nameWithOwner,viewerPermission

# MCP: token presente sin mostrar valor
grep -q '^export GITHUB_PERSONAL_ACCESS_TOKEN=' ~/.config/mcp-secrets.env && echo "MCP token configurado"
```

## Codex shell snapshots

Codex puede persistir dumps del entorno shell en `~/.codex/shell_snapshots/*.sh` (caché local regenerable, **no** configuración canónica). Si el entorno tenía secretos exportados (p. ej. antes de BUILD 1), esos archivos pueden contener tokens en claro.

**Política:**

- No exportar `GH_TOKEN` / `GITHUB_TOKEN` en shells interactivas (evita regenerar snapshots contaminados).
- Tras rotar secretos o corregir el entorno, auditar y limpiar snapshots locales.
- **No** versionar ni commitear snapshots; son solo HOME local.

**Diagnóstico read-only:**

```bash
scripts/diagnose-secret-surfaces.sh
# o rutas explícitas:
scripts/diagnose-secret-surfaces.sh ~/.codex/shell_snapshots
```

El script lista archivos afectados y muestra contexto **redactado** (`<redacted>`). Nunca imprime valores completos.

**Limpieza local (manual):**

```bash
rm -f ~/.codex/shell_snapshots/*.sh
scripts/diagnose-secret-surfaces.sh   # debe salir 0
```

No borrar `~/.codex/config.toml`, `auth.json`, `prompts/`, `rules/`, `sessions/` ni bases SQLite.
