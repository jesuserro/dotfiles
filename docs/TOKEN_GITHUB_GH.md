# Token de GitHub: un solo token (classic)

## Política actual

**Un solo token**: classic (`ghp_`) en `secrets.sops.yaml`. El fine-grained (`github_pat_`) está deprecado porque no tiene permisos de Projects.

## Flujo

1. **secrets.sops.yaml** → `mcp.github_personal_access_token` (classic, scope `project`)
2. **chezmoi apply** → genera `~/.config/store-etl/secrets.env` con `GITHUB_TOKEN`, `GH_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN`
3. **~/.secrets/codex.env** (symlink) → usado por MCPs, zsh, Cursor, Codex

## Qué token usa cada contexto

| Contexto | Token | Origen |
|----------|-------|--------|
| `gh` CLI (terminal) | Classic | `~/.secrets/codex.env` → SOPS |
| MCP GitHub (Cursor/Codex) | Classic | `~/.secrets/codex.env` → SOPS |
| CI (GitHub Actions) | `secrets.GITHUB_TOKEN` | Token automático del workflow |

## Requisitos

- Token classic en `secrets.sops.yaml` con scope `project` (ver [CAMBIAR_TOKEN_GITHUB.md](CAMBIAR_TOKEN_GITHUB.md)).

## Verificación

```bash
gh auth status
gh api graphql -f query='query { user(login: "jesuserro") { projectV2(number: 7) { id title } } }'
```
