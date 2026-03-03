# Token de GitHub: prioridad para `gh` CLI

## Problema

- El token **fine-grained** (`github_pat_`) no tiene permisos de Projects y falla con la API de Projects.
- El token **classic** (`ghp_`) en `~/.config/gh/hosts.yml` tiene scope `project`.
- Cuando `GH_TOKEN` o `GITHUB_TOKEN` están definidos en el entorno, `gh` los usa **antes** que `hosts.yml`.

## Solución implementada

**Opción B**: No exportar `GH_TOKEN`/`GITHUB_TOKEN` en el shell interactivo para que `gh` use `hosts.yml`.

- **zsh/90-local.zsh**: Tras `source ~/.secrets/codex.env`, hace `unset GH_TOKEN GITHUB_TOKEN`.
- **gh** (en terminal): Usa el token de `~/.config/gh/hosts.yml` (classic con scope project).
- **MCPs** (GitHub, Codex, Cursor): Siguen usando `GH_TOKEN` desde `~/.secrets/codex.env` (se cargan en su propio proceso con `source codex.env`).

## Qué token usa cada contexto

| Contexto | Token | Origen |
|----------|-------|--------|
| `gh` CLI (terminal) | Classic (`ghp_`) | `~/.config/gh/hosts.yml` (gh auth login) |
| MCP GitHub (Cursor/Codex) | El de SOPS | `~/.secrets/codex.env` → `secrets.sops.yaml` |
| CI (GitHub Actions) | `secrets.GITHUB_TOKEN` | Token automático del workflow |

## Requisitos

1. **gh auth login** con token classic (scope `project`):
   ```bash
   gh auth login
   # Elegir token classic con scope project
   ```

2. **SOPS** puede tener fine-grained o classic para MCPs. Si los MCPs necesitan Projects, usa classic en `secrets.sops.yaml`.

## Verificación

```bash
# Debe mostrar el token de hosts.yml (classic)
gh auth status

# Debe devolver el proyecto Store-ETL sin error
gh api graphql -f query='query { user(login: "jesuserro") { projectV2(number: 7) { id title } } }'
```

## Alternativa (Opción A)

Si prefieres un solo token (classic) para todo: pon el classic en `secrets.sops.yaml` y **no** hagas unset en zsh. Entonces tanto `gh` como MCPs usarán el classic. En ese caso, comenta o elimina las líneas `unset` en `zsh/90-local.zsh`.
