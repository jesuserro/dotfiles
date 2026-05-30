# Chezmoi + SOPS + Age

**Referencia principal** para la gestión de dotfiles con Chezmoi, secretos cifrados con SOPS y Age.

## Estado actual

- **Chezmoi** es el único gestor activo de dotfiles relevantes: MCPs (Cursor/Codex), secretos, config Codex, AI runtime y los RC files de la **zsh stack** (`~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`).
- **`make install-zsh-stack`** instala únicamente runtime: Oh My Zsh + Powerlevel10k + plugins custom (`zsh-autosuggestions`, `zsh-completions`, etc.). No toca ningún RC file.
- **Lista de plugins OMZ:** fuente de verdad en `zsh/20-omz.zsh` (cargado vía `dotfiles/zshrc`). No activar gestores de runtime vía OMZ (`nvm`, `pyenv`, `asdf`, `conda`, `autoenv`). El plugin `z` se mantiene por simplicidad; `zoxide` sería una mejora futura separada. FastAPI, Vite, React, TypeScript, PostgreSQL, PowerShell, Cursor y Codex no van como plugins OMZ; si hace falta, conviene aliases o funciones en `aliases` / `zsh/`.
- **RCM (`rcup`)** queda fuera del flujo activo. Sus referencias históricas se conservan solo como contexto. No hay paso `rcup` en el bootstrap; tampoco se requiere instalar `rcm`.

---

## Cuándo usar source y chezmoi

En este proyecto conviven dos mecanismos para aplicar cambios. Resumen:

| Mecanismo | Qué hace | Cuándo usarlo |
|-----------|----------|----------------|
| **`chezmoi --source=$HOME/dotfiles apply`** (alias: `make install-dotfiles DOTFILES_APPLY=1`) | Aplica las plantillas, archivos y symlinks que Chezmoi gestiona desde el repo a tu HOME: `~/.cursor/mcp.json`, `~/.codex/config.toml`, `~/.config/ai/`, secretos generados, y los symlinks `~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`. | Cuando has editado en el repo lo que Chezmoi controla. No hace falta ejecutarlo solo por haber corrido `make update` (que actualiza sistema/deps/imágenes). |
| **`source ~/.zshrc`** | Recarga en la **sesión actual** de la terminal el contenido de `~/.zshrc`: aliases, PATH, etc. No escribe archivos. | Después de `chezmoi apply` o de `make update` si cambió PATH. |
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
| `~/.aliases` | `symlink_dot_aliases.tmpl` → `$HOME/dotfiles/aliases` |

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
- **Excalidraw bind mount (MCP):** `data.ai.excalidraw_workspace_host` cuando está definido; si falta en la config fusionada (p. ej. solo tienes `obsidian_vault_path` en `~/.config/chezmoi/chezmoi.toml`), las plantillas usan **`obsidian_vault_path`/excalidraw** sin fallar.
- **Otra máquina (p. ej. oficina):** no versiones rutas corporativas en el repo; sobrescribe en **`~/.config/chezmoi/chezmoi.toml`** (Chezmoi fusiona este archivo con el del source):

```toml
[data.ai]
    obsidian_vault_path = "/ruta/real/del/vault"
    excalidraw_workspace_host = "/ruta/real/excalidraw"
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

El repo **no** fija `[source].path` en `.chezmoi.toml` (portabilidad). Configura el clone en `~/.config/chezmoi/chezmoi.toml` si quieres omitir `--source`:

```toml
[source]
    path = "/home/TU_USUARIO/dotfiles"
```

Luego:

```bash
chezmoi status
chezmoi apply
```

Equivalente explícito del Makefile:

```bash
make install-dotfiles              # solo plan
make install-dotfiles DOTFILES_APPLY=1   # ejecuta apply
```

Variable de entorno equivalente: `DOTFILES_APPLY=1`.

---

## Scripts `run_before` / `run_after`

Chezmoi ejecuta hooks bajo `.chezmoiscripts/` en el repo:

| Script | Momento | Rol |
|--------|---------|-----|
| `run_before_00_backup_rc_files.sh.tmpl` | Antes de apply | Backup / política sobre `~/.zshrc`, `~/.aliases`, `~/.p10k.zsh` |
| `run_after_00_gen_secrets.sh.tmpl` | Tras apply | Genera `~/.config/mcp-secrets.env` desde `secrets.sops.yaml` |
| `run_after_10`–`14` | Tras apply | Runtime AI, launchers MCP, etc. |

Regenerar solo secretos sin apply completo:

```bash
chezmoi --source="$HOME/dotfiles" apply -i scripts
```

---

## Configuración local (`~/.config/chezmoi/chezmoi.toml`)

Archivo **no versionado** que Chezmoi fusiona con `.chezmoi.toml` del repo. Usos habituales:

- `[source] path` — ruta del repo si no quieres pasar `--source` cada vez.
- `[data.ai] obsidian_vault_path` — ruta del vault en esta máquina.
- **`[status] exclude` / `[diff] exclude`** — opcional; por ejemplo `exclude = ["scripts"]` oculta en `chezmoi status` entradas fantasma de scripts renombrados en el estado local (nombres viejos `00_*` / `10_*`). **No es requisito global del repo**; es comodidad por máquina.

Para auditar scripts de verdad:

```bash
chezmoi status -i scripts -x ''
```

---

## Configuración de Age + SOPS (una vez)

### 1. Validar o restaurar la clave Age

```bash
mkdir -p ~/.config/sops/age
test -f ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Si `secrets.sops.yaml` ya existe cifrado, no generes una clave nueva a ciegas: restaura/importa primero la clave privada que corresponde al recipient de `.sops.yaml`. La clave privada vive en `~/.config/sops/age/keys.txt` y nunca se versiona.

Para rotar a una clave nueva:

```bash
age-keygen -o ~/.config/sops/age/keys.txt.new
age-keygen -y ~/.config/sops/age/keys.txt.new
# Actualiza .sops.yaml con la nueva public key y re-encripta:
sops updatekeys secrets.sops.yaml
```

### 2. Revisar `.sops.yaml` en el repo

El archivo define qué rutas cifrar y qué recipient Age puede descifrarlas:

```yaml
creation_rules:
  - path_regex: secrets\.sops\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Editar secretos

```bash
cd ~/dotfiles
sops secrets.sops.yaml
```

Rellenar los valores reales en el editor abierto por SOPS y guardar. No pegues tokens en chat ni uses `sops -d` en terminal como flujo normal.

### 4. Aplicar

```bash
make install-dotfiles DOTFILES_APPLY=1
```

Se genera `~/.config/mcp-secrets.env` desde `secrets.sops.yaml`; `~/.secrets/codex.env` queda como compatibilidad apuntando a ese archivo.

---

## Estructura de secretos

| Archivo | Descripción |
|---------|-------------|
| `secrets.sops.yaml` | En repo, cifrado. Contiene `mcp.github_personal_access_token`, `mcp.postgres_dsn`, `mcp.minio_access_key`, `mcp.minio_secret_key`. |
| `~/.config/mcp-secrets.env` | Canonico generado por Chezmoi al hacer `apply`. Nombre neutro para MCPs. No versionar. |
| `~/.secrets/codex.env` | Adaptador de compatibilidad a `~/.config/mcp-secrets.env`. No versionar. |
| `~/.config/store-etl/secrets.env` | Copia legacy para consumidores antiguos. No usar como fuente principal ni versionar. |

---

## Script post-apply

El script `.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl` se ejecuta tras `apply`:

1. Desencripta `secrets.sops.yaml` con SOPS.
2. Genera `~/.config/mcp-secrets.env` (variables export, nombre neutro).
3. Crea `~/.secrets/codex.env` como adaptador legacy hacia `~/.config/mcp-secrets.env`.
4. Mantiene `~/.config/store-etl/secrets.env` y archivos de MinIO solo como compatibilidad legacy.

Requiere: `sops`, `yq` o `python3` con PyYAML.

**Modo estricto (opt-in):** `MCP_SECRETS_STRICT=1 chezmoi apply` falla si existe `secrets.sops.yaml` cifrado pero no se puede generar `~/.config/mcp-secrets.env` (sin `sops`, descifrado fallido o sin `yq`/PyYAML). Por defecto el hook es permisivo para máquinas sin Age/SOPS aún configurados.

**Artefactos SOPS temporales:** no versionar `secrets.sops.yaml.new` ni `*.sops.yaml.bak` (ver `.gitignore`).

---

## Runtime Python MCP (`uv`)

El hook `run_after_10_setup_ai_runtime.sh.tmpl` sincroniza `~/.config/ai/runtime/.venv` con **`uv`** (no `pip install -r` en cada apply). Requiere `uv` en PATH (`make install-uv`). Solo reinstala cuando cambia el hash de `ai/runtime/mcp/requirements.txt`.

---

## PostgreSQL MCP y DSN en argv

El launcher `mcp-postgres-launcher` usa `@modelcontextprotocol/server-postgres` **v0.6.x**, que solo acepta la URL de conexión como **argumento CLI** (sin variable de entorno oficial). El DSN puede aparecer en listados de procesos (`ps`). No hay alternativa soportada sin cambiar de servidor MCP.

---

## MCPs globales vs proyecto Store ETL

- **Global (dotfiles):** `~/.cursor/mcp.json` incluye todos los MCP del `MANIFEST.yaml` (incl. `store_etl_ops` como wrapper operativo del repo dotfiles).
- **Proyecto store-etl:** la configuración Cursor **`.cursor/mcp.json` del repositorio `store-etl`** es responsabilidad de ese proyecto (no se materializa desde dotfiles; el hook `run_after_10_link_store_etl_mcp` fue retirado). Los secretos legacy `~/.config/store-etl/secrets.env` siguen generándose solo como compatibilidad desde SOPS.

---

## Validación

1. `chezmoi --source=$HOME/dotfiles apply`
2. `make ai-cursor-check` (y `MCP_SECRETS_STRICT=1` tras rotación de secretos).
3. Abrir Cursor en un repo genérico → MCPs globales.
4. Para stack store-etl: usar el `mcp.json` del proyecto `store-etl`.

---

## No hacer

- No reintroducir RCM/rcup en el flujo activo (ni en docs de máquina nueva, ni en targets, ni en inventario APT). Chezmoi es el único gestor activo.
- No depender de `rcup` para que `~/.zshrc` o Powerlevel10k funcionen.
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
