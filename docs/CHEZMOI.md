# Chezmoi + SOPS + Age

**Referencia principal** para la gestión de dotfiles con Chezmoi, secretos cifrados con SOPS y Age.

## Estado actual

- **Chezmoi** gestiona: MCPs (Cursor/Codex), secretos, config Codex.
- **RCM (rcup)** gestiona: zsh, tmux, vim, git, aliases, etc.
- **Roadmap:** Chezmoi sustituirá a rcup como único gestor de dotfiles.

---

## Cuándo usar rcup, source y chezmoi

En este proyecto conviven tres mecanismos para aplicar cambios. Resumen:

| Mecanismo | Qué hace | Cuándo usarlo |
|-----------|----------|----------------|
| **`rcup -v`** | Crea o actualiza symlinks desde el repo hacia `$HOME` para los archivos que RCM gestiona (zsh, tmux, vim, aliases, etc.). | Cuando has modificado en el repo esos archivos (p. ej. `aliases`, `zshrc`, `tmux.conf`) y quieres que tu HOME refleje los cambios. |
| **`source ~/.zshrc`** | Recarga en la **sesión actual** de la terminal el contenido de `~/.zshrc`: aliases, funciones (como `ups`), PATH, etc. No escribe archivos. | Después de `rcup` para que la shell use los nuevos aliases/funciones. También después de `ups`: con eso basta para que la sesión vea binarios actualizados (pnpm, etc.); **no** hace falta chezmoi solo por haber ejecutado `ups`. |
| **`chezmoi --source=$HOME/dotfiles apply`** | Aplica las plantillas y archivos que Chezmoi gestiona desde el repo a tu HOME: `~/.cursor/mcp.json`, `~/.codex/config.toml`, `~/.config/ai/`, secretos generados, etc. | Cuando **tú** has editado en el repo lo que Chezmoi controla (p. ej. `dot_cursor/mcp.json.tmpl`, `dot_codex/config.toml.tmpl`, `ai/runtime/mcp/`, secretos). No es necesario ejecutarlo solo por haber corrido `ups` (que solo actualiza código/deps de los servidores MCP). |
| **`chezmoi --source=$HOME/dotfiles apply ~/.cursor/mcp.json ~/.config/opencode/opencode.json ~/.codex/config.toml`** | Propaga solo las configs MCP renderizadas de Cursor, OpenCode y Codex. | Úsalo tras cambios de plantillas MCP como el launcher de GitNexus. Mantiene el arranque estable con binarios/launchers locales en vez de `npx ...@latest` en runtime. |

Flujo típico tras un `git pull`: `chezmoi --source=$HOME/dotfiles apply` (si hay cambios en lo que Chezmoi gestiona), `rcup -v` (si hay cambios en lo que RCM gestiona), y `source ~/.zshrc` para la sesión actual.

---

## Qué gestiona Chezmoi hoy

| Target en HOME | Origen en repo |
|----------------|----------------|
| `~/.cursor/mcp.json` | `dot_cursor/mcp.json.tmpl` |
| `~/.codex/config.toml` | `dot_codex/config.toml.tmpl` |
| `~/.config/mcp-secrets.env` | Generado desde `secrets.sops.yaml` (SOPS) — nombre neutro |
| `~/.secrets/codex.env` | Symlink → `~/.config/mcp-secrets.env` (legacy, mantener por compatibilidad) |
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

Se genera `~/.config/mcp-secrets.env` desde `secrets.sops.yaml` y el symlink `~/.secrets/codex.env` apunta a ese archivo (compatibilidad).

---

## Estructura de secretos

| Archivo | Descripción |
|---------|-------------|
| `secrets.sops.yaml` | En repo, cifrado. Contiene `mcp.github_personal_access_token`, `mcp.postgres_dsn`, `mcp.minio_access_key`, `mcp.minio_secret_key`. |
| `~/.config/mcp-secrets.env` | Generado por Chezmoi al hacer `apply`. Nombre neutro para MCPs. No versionar. |
| `~/.secrets/codex.env` | Symlink legacy a `~/.config/mcp-secrets.env` (mantener por compatibilidad). |

---

## Script post-apply

El script `.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl` se ejecuta tras `apply`:

1. Desencripta `secrets.sops.yaml` con SOPS.
2. Genera `~/.config/mcp-secrets.env` (variables export, nombre neutro).
3. Copia a `~/.config/mcp-secrets.env` y crea symlink legacy `~/.secrets/codex.env`.
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
