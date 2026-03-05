# Chezmoi + SOPS + Age

**Referencia principal** para la gestión de dotfiles con Chezmoi, secretos cifrados con SOPS y Age.

## Estado actual

- **Chezmoi** gestiona: MCPs (Cursor/Codex), secretos, config Codex.
- **RCM (rcup)** gestiona: zsh, tmux, vim, git, aliases, etc.
- **Roadmap:** Chezmoi sustituirá a rcup como único gestor de dotfiles.

---

## Qué gestiona Chezmoi hoy

| Target en HOME | Origen en repo |
|----------------|----------------|
| `~/.cursor/mcp.json` | `dot_cursor/mcp.json.tmpl` |
| `~/.codex/config.toml` | `dot_codex/config.toml.tmpl` |
| `~/.config/store-etl/secrets.env` | Generado desde `secrets.sops.yaml` (SOPS) |
| `~/.secrets/codex.env` | Symlink → `~/.config/store-etl/secrets.env` |
| `~/.config/ai/runtime/` | Runtime (venv) — ver `ai/README.md` |

---

## Requisitos

- **Chezmoi:** [releases](https://github.com/twpayne/chezmoi/releases) o `~/dotfiles/bin/chezmoi`
- **Age:** `sudo apt install age` o [releases](https://github.com/FiloSottile/age/releases)
- **SOPS:** [releases](https://github.com/getsops/sops/releases)
- **yq** o **python3 + PyYAML** para el script de generación de secretos

---

## Uso básico

```bash
# Siempre usar el repo como source
chezmoi --source=$HOME/dotfiles status
chezmoi --source=$HOME/dotfiles apply
```

O configurar el source por defecto en `~/.config/chezmoi/chezmoi.toml`:

```toml
[source]
    path = "/home/jesus/dotfiles"
```

Luego:

```bash
chezmoi status
chezmoi apply
```

---

## Configuración de Age + SOPS (una vez)

### 1. Generar clave Age

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
grep "public key:" ~/.config/sops/age/keys.txt
```

### 2. Editar `.sops.yaml` en el repo

Reemplazar `AGE_PUBLIC_KEY_AQUI` por la public key obtenida. El archivo define qué rutas cifrar:

```yaml
creation_rules:
  - path_regex: secrets\.sops\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Cifrar secretos

```bash
cd ~/dotfiles
sops secrets.sops.yaml
```

Rellenar los valores reales en el YAML y guardar (SOPS cifra al salir).

### 4. Aplicar

```bash
chezmoi --source=$HOME/dotfiles apply
```

Se genera `~/.config/store-etl/secrets.env` desde `secrets.sops.yaml` y el symlink `~/.secrets/codex.env` apunta a ese archivo.

---

## Estructura de secretos

| Archivo | Descripción |
|---------|-------------|
| `secrets.sops.yaml` | En repo, cifrado. Contiene `mcp.github_personal_access_token`, `mcp.postgres_dsn`, `mcp.minio_access_key`, `mcp.minio_secret_key`. |
| `~/.config/store-etl/secrets.env` | Generado por Chezmoi al hacer `apply`. No versionar. |
| `~/.secrets/codex.env` | Symlink a `~/.config/store-etl/secrets.env` para compatibilidad Codex/Cursor. |

---

## Script post-apply

El script `.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl` se ejecuta tras `apply`:

1. Desencripta `secrets.sops.yaml` con SOPS.
2. Genera `~/.config/store-etl/secrets.env` (variables export).
3. Crea symlink `~/.secrets/codex.env`.
4. Crea archivos de compatibilidad para docker-compose en `~/.secrets/store-etl/`.

Requiere: `sops`, `yq` o `python3` con PyYAML.

---

## MCPs globales vs proyecto Store ETL

- **Global** (`~/.cursor/mcp.json`): excalidraw, context7, docker, github, fetch. Cualquier repo solo ve estos.
- **Store ETL** (`~/.config/store-etl/` o `.cursor/mcp.json`): postgres, trino, dagster, minio, tempo, loki, prometheus, store_etl_ops. Solo al abrir Cursor en ese proyecto.

---

## Validación

1. `chezmoi --source=$HOME/dotfiles apply`
2. Abrir Cursor en otro repo → solo MCP global.
3. Abrir Cursor en store-etl → MCPs específicos del proyecto.
4. Comprobar: GitHub MCP, Postgres MCP, MinIO MCP, Dagster.

---

## No hacer

- No eliminar rcup (aún gestiona el resto de dotfiles).
- No tocar zsh, tmux, vim por ahora.
- Postgres: npx. Trino: `~/.config/ai/runtime/.venv` (trino-mcp). Docker: aún en `~/.codex/mcp/docker` si existe.

---

## Documentación relacionada

- [GUIA_MCP_AI.md](GUIA_MCP_AI.md) — guía práctica con comandos (añadir MCP, skills, verificar)
- [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md) — ejemplos prácticos para dar de alta secretos (GitHub, Postgres, MinIO)
- [TOKEN_GITHUB_GH.md](TOKEN_GITHUB_GH.md) — prioridad del token classic para `gh` CLI (Projects API)
- [MIGRATION_MCP_CHEZMOI.md](MIGRATION_MCP_CHEZMOI.md) — detalles de la migración MCP
- [MIGRATION_MCP_ITER3.md](MIGRATION_MCP_ITER3.md) — layout de servidores MCP
- [codex/README-mcp.md](../codex/README-mcp.md) — MCPs locales y smoke tests
- [ai/README.md](../ai/README.md) — arquitectura AI Workstation
- [STRUCTURE.md](../STRUCTURE.md) — árbol del repo
