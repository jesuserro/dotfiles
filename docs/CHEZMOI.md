# Chezmoi + SOPS + Age

**Referencia principal** para la gestión de dotfiles con Chezmoi, secretos cifrados con SOPS y Age.

## Estado actual

- **Chezmoi** es el único gestor activo de dotfiles relevantes: MCPs (Cursor/Codex), secretos, config Codex, AI runtime y los RC files de la **zsh stack** (`~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`).
- **`make install-zsh-stack`** instala únicamente runtime: Oh My Zsh + Powerlevel10k + plugins. No toca ningún RC file.
- **RCM (`rcup`)** queda fuera del flujo activo. Sus referencias históricas se conservan solo como contexto. No hay paso `rcup` en el bootstrap; tampoco se requiere instalar `rcm`.

---

## Cuándo usar source y chezmoi

En este proyecto conviven dos mecanismos para aplicar cambios. Resumen:

| Mecanismo | Qué hace | Cuándo usarlo |
|-----------|----------|----------------|
| **`chezmoi --source=$HOME/dotfiles apply`** (alias: `make install-dotfiles DOTFILES_APPLY=1`) | Aplica las plantillas, archivos y symlinks que Chezmoi gestiona desde el repo a tu HOME: `~/.cursor/mcp.json`, `~/.codex/config.toml`, `~/.config/ai/`, secretos generados, y los symlinks `~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`. | Cuando has editado en el repo lo que Chezmoi controla. No hace falta ejecutarlo solo por haber corrido `ups` (que solo actualiza código/deps de los servidores MCP). |
| **`source ~/.zshrc`** | Recarga en la **sesión actual** de la terminal el contenido de `~/.zshrc`: aliases, funciones (como `ups`), PATH, etc. No escribe archivos. | Después de `chezmoi apply` o de `ups` para que la shell use los nuevos aliases/funciones. |
| **`chezmoi --source=$HOME/dotfiles apply ~/.cursor/mcp.json ~/.config/opencode/opencode.json ~/.codex/config.toml`** | Propaga solo las configs MCP renderizadas de Cursor, OpenCode y Codex. | Úsalo tras cambios de plantillas MCP como el launcher de GitNexus. Mantiene el arranque estable con binarios/launchers locales en vez de `npx ...@latest` en runtime. |

Flujo típico tras un `git pull`: `chezmoi --source=$HOME/dotfiles apply` (si hay cambios en lo que Chezmoi gestiona) y `source ~/.zshrc` para la sesión actual.

---

## Qué gestiona Chezmoi hoy

| Target en HOME | Origen en repo |
|----------------|----------------|
| `~/.cursor/mcp.json` | `dot_cursor/mcp.json.tmpl` |
| `~/.codex/config.toml` | `dot_codex/config.toml.tmpl` |
| `~/.config/mcp-secrets.env` | Generado desde `secrets.sops.yaml` (SOPS) — nombre neutro |
| `~/.secrets/codex.env` | Symlink → `~/.config/mcp-secrets.env` (legacy, mantener por compatibilidad) |
| `~/.config/ai/runtime/` | Runtime (venv) — ver `ai/README.md` |
| `~/.local/share/chezmoi/bin/mcp-*-launcher` | `dot_local/share/chezmoi/bin/executable_mcp-*-launcher.tmpl` (`filesystem`, `git`, `gitnexus`, `postgres`) |
| `~/.zshrc` | `symlink_dot_zshrc.tmpl` → `$HOME/dotfiles/zshrc` |
| `~/.p10k.zsh` | `symlink_dot_p10k.zsh.tmpl` → `$HOME/dotfiles/powerlevel10k/p10k.zsh` |
| `~/.aliases` | `symlink_dot_aliases.tmpl` → `$HOME/dotfiles/aliases` (carga la función `ups`) |

### Backup seguro de RC files

El hook `.chezmoiscripts/run_before_00_backup_rc_files.sh.tmpl` se ejecuta antes de `chezmoi apply` y aplica esta política sobre `~/.zshrc`, `~/.p10k.zsh` y `~/.aliases`:

- Si el target no existe o ya es un symlink correcto: no-op (idempotente).
- Si es un symlink al destino equivocado o un fichero **trivial** (vacío, solo whitespace, o exactamente `. "$HOME/.local/bin/env"` — el stub que escribe el instalador oficial de `uv`): se mueve a `~/<name>.backup.YYYYMMDD-HHMMSS` y Chezmoi crea el symlink limpio.
- Si es un fichero regular con **contenido custom**: el hook aborta con mensaje accionable, salvo que se pase `ZSH_RC_APPLY=1`. Con el flag, se hace backup con timestamp y se reemplaza.

Nunca se borra sin backup; nunca se usa `sudo`.

---

## Dato Chezmoi: ruta del vault Obsidian (`ai.obsidian_vault_path`)

El MCP **Obsidian (mcpvault)** y el whitelist del **Filesystem MCP** usan la misma ruta lógica del vault, definida en **`.chezmoi.toml`** del repo bajo **`[data.ai]`** → **`obsidian_vault_path`**. En las plantillas aparece como **`{{ .ai.obsidian_vault_path }}`** (no edites a mano las plantillas MCP productivas: regenera con `make ai-mcp-generate APPLY=1`).

- **Valor por defecto en repo (casa / WSL):** `/mnt/c/Users/jesus/Documents/vault_trabajo`.
- **Otra máquina (p. ej. oficina):** no versiones rutas corporativas en el repo; sobrescribe en **`~/.config/chezmoi/chezmoi.toml`** (Chezmoi fusiona este archivo con el del source):

```toml
[data.ai]
    obsidian_vault_path = "/ruta/real/del/vault"
```

Tras cambiar el dato: **`chezmoi apply`** (o `make install-dotfiles DOTFILES_APPLY=1`) y comprueba con **`make ai-cursor-check`** (lee la ruta efectiva en `~/.cursor/mcp.json`).

---

## Requisitos

- **Chezmoi:** `make install-chezmoi` (preferido, opt-in, idempotente, sin sudo, deja el binario en `~/.local/bin/chezmoi`). Fallback: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"` o [releases](https://github.com/twpayne/chezmoi/releases).
- **Age:** `sudo apt install age` o [releases](https://github.com/FiloSottile/age/releases)
- **SOPS:** `make install-sops` (opt-in, idempotente, sin sudo) o [releases](https://github.com/getsops/sops/releases)
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

- No reintroducir RCM/rcup en el flujo activo (ni en docs de máquina nueva, ni en targets, ni en inventario APT). Chezmoi es el único gestor activo.
- No depender de `rcup` para que `~/.zshrc`, Powerlevel10k o `ups` funcionen.
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
