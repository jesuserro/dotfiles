# Chezmoi + SOPS + Age

**Referencia principal** para la gestión de dotfiles con Chezmoi, secretos cifrados con SOPS y Age.

## Estado actual

- **Chezmoi** es el único gestor activo de dotfiles relevantes: MCPs (Cursor/Codex), secretos, config Codex, AI runtime, los RC files de la **zsh stack** (`~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`) y **tmux** (`~/.tmux.conf`, launcher `tmux-dotfiles` en `~/.local/bin`).
- **`make install-zsh-stack`** instala únicamente runtime: Oh My Zsh + Powerlevel10k + plugins custom (`zsh-autosuggestions`, `zsh-completions`, etc.). No toca ningún RC file.
- **Lista de plugins OMZ:** fuente de verdad en `zsh/20-omz.zsh` (cargado vía `dotfiles/zshrc`). No activar gestores de runtime vía OMZ (`nvm`, `pyenv`, `asdf`, `conda`, `autoenv`). El salto de directorios usa **zoxide** (`zsh/25-zoxide.zsh`, paquete APT opcional en `system/packages/ubuntu.yaml`): sustituye al plugin OMZ `z`, no cargar ambos; si falta el binario el shell arranca igual; con zoxide instalado se conserva `z <patrón>` vía `zoxide init zsh`. Migración de historial manual: `zoxide import --from=z "$HOME/.z"`. FastAPI, Vite, React, TypeScript, PostgreSQL, PowerShell, Cursor y Codex no van como plugins OMZ; si hace falta, conviene aliases o funciones en `aliases` / `zsh/`.
- **RCM (`rcup`)** queda fuera del flujo activo. Sus referencias históricas se conservan solo como contexto. No hay paso `rcup` en el bootstrap; tampoco se requiere instalar `rcm`.

---

## Cuándo usar source y chezmoi

En este proyecto conviven dos mecanismos para aplicar cambios. Resumen:

| Mecanismo | Qué hace | Cuándo usarlo |
|-----------|----------|----------------|
| **`chezmoi --source=$HOME/dotfiles apply`** (alias: `make install-dotfiles DOTFILES_APPLY=1`) | Aplica las plantillas, archivos y symlinks que Chezmoi gestiona desde el repo a tu HOME: `~/.cursor/mcp.json`, `~/.codex/config.toml`, `~/.config/ai/`, secretos generados, los symlinks `~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`, `~/.tmux.conf`, y el launcher `~/.local/bin/tmux-dotfiles`. | Cuando has editado en el repo lo que Chezmoi controla. No hace falta ejecutarlo solo por haber corrido `make update` (que actualiza sistema/deps/imágenes). |
| **`source ~/.zshrc`** | Recarga en la **sesión actual** de la terminal el contenido de `~/.zshrc`: aliases, PATH, etc. No escribe archivos. | Después de `chezmoi apply` o de `make update` si cambió PATH. |
| **`chezmoi --source=$HOME/dotfiles apply ~/.cursor/mcp.json ~/.config/opencode/opencode.json ~/.codex/config.toml`** | Propaga solo las configs MCP renderizadas de Cursor, OpenCode y Codex. | Úsalo tras cambios de plantillas MCP como el launcher de GitNexus. Mantiene el arranque estable con binarios/launchers locales en vez de `npx ...@latest` en runtime. |

Flujo típico tras un `git pull`: `chezmoi --source=$HOME/dotfiles apply` (si hay cambios en lo que Chezmoi gestiona) y `source ~/.zshrc` para la sesión actual.

---

## Qué gestiona Chezmoi hoy

| Target en HOME | Origen en repo |
|----------------|----------------|
| `~/.cursor/mcp.json` | `dot_cursor/mcp.json.tmpl` |
| `~/.codex/config.toml` | `dot_codex/private_config.toml.tmpl` |
| `~/.config/mcp-secrets.env` | Generado desde `secrets.sops.yaml` (SOPS) — nombre neutro |
| `~/.secrets/codex.env` | Symlink → `~/.config/mcp-secrets.env` (legacy, mantener por compatibilidad) |
| `~/.config/ai/runtime/` | Runtime (venv) — ver `ai/README.md` |
| `~/.local/share/chezmoi/bin/mcp-*-launcher` | `dot_local/share/chezmoi/bin/executable_mcp-*-launcher.tmpl` (`filesystem`, `git`, `gitnexus`, `postgres`) |
| `~/.zshrc` | `symlink_dot_zshrc.tmpl` → `$HOME/dotfiles/zshrc` |
| `~/.p10k.zsh` | `symlink_dot_p10k.zsh.tmpl` → `$HOME/dotfiles/powerlevel10k/p10k.zsh` |
| `~/.aliases` | `symlink_dot_aliases.tmpl` → `$HOME/dotfiles/aliases` |
| `~/.tmux.conf` | `symlink_dot_tmux.conf.tmpl` → `$HOME/dotfiles/tmux.conf` |
| `~/.local/bin/tmux-dotfiles` | `run_after_15_link_tmux_dotfiles` → `$HOME/dotfiles/bin/tmux-dotfiles` |

### Backup seguro de symlinks gestionados (RC + tmux)

El hook `.chezmoiscripts/run_before_00_backup_rc_files.sh.tmpl` se ejecuta antes de `chezmoi apply` y aplica esta política sobre `~/.zshrc`, `~/.p10k.zsh`, `~/.aliases` y `~/.tmux.conf`:

- Si el target no existe o ya es un symlink correcto: no-op (idempotente).
- Si es un symlink al destino equivocado o un fichero **trivial** (vacío, solo whitespace, o exactamente `. "$HOME/.local/bin/env"` — el stub que escribe el instalador oficial de `uv`): se mueve a `~/<name>.backup.YYYYMMDD-HHMMSS` y Chezmoi crea el symlink limpio.
- Si es un fichero regular con **contenido custom**: el hook aborta con mensaje accionable, salvo que se pase `ZSH_RC_APPLY=1`. Con el flag, se hace backup con timestamp y se reemplaza. El nombre del flag es histórico (zsh stack); **también autoriza el reemplazo de un `~/.tmux.conf` custom**.

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
- **`[status] exclude` / `[diff] exclude`** — opcional; por ejemplo `exclude = ["scripts"]` oculta en `chezmoi status` las líneas `R` de hooks (ver § Scripts y columna `R`). **No es requisito global del repo**; es comodidad por máquina si el ruido molesta.

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

## Drift aceptado y auditoría

`chezmoi status` **no tiene por qué estar vacío**. Parte del drift es esperado o requiere decisión manual antes de un `apply` global.

### Cómo leer `chezmoi status`

Cada línea usa dos columnas de estado (`xy path`): estado en **source** (repo/plantilla) y en **destino** (HOME).

| Símbolo | Significado habitual |
|---------|----------------------|
| `M` | Modificado respecto al último estado aplicado |
| `R` | **Scripts** (p. ej. bajo `.chezmoiscripts/`): **Run** — se ejecutarán en el próximo `apply`. No significa “removed”. |
| `MM` | Source y destino divergen (revisar diff antes de apply) |

Comandos de **solo lectura** (seguros para auditar):

```bash
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" diff
chezmoi --source="$HOME/dotfiles" diff \
  ~/.local/share/chezmoi/bin/mcp-git-launcher \
  ~/.local/share/chezmoi/bin/mcp-postgres-launcher
chezmoi --source="$HOME/dotfiles" status -i scripts -x ''
```

Reporte resumido en el repo (no muta HOME, no ejecuta `apply`):

```bash
make chezmoi-drift-report
```

### Scripts `.chezmoiscripts` y columna `R` (`Run`)

En Chezmoi, **`R` significa Run**: el hook se ejecutará en el próximo `chezmoi apply`. No es “removed” como en `git status`.

Los hooks del repo usan prefijos `run_before_*` / `run_after_*` y sufijo `.tmpl`, por ejemplo:

- `run_before_00_backup_rc_files.sh.tmpl`
- `run_after_00_gen_secrets.sh.tmpl`, `run_after_10_*`, … `run_after_15_*`

En `chezmoi status` aparecen con **nombre normalizado** (sin prefijo `run_before_` / `run_after_` ni `.tmpl`), por ejemplo:

| Línea en `status` | Plantilla en el repo |
|-------------------|----------------------|
| `R .chezmoiscripts/00_backup_rc_files.sh` | `run_before_00_backup_rc_files.sh.tmpl` |
| `R .chezmoiscripts/00_gen_secrets.sh` | `run_after_00_gen_secrets.sh.tmpl` |
| `R .chezmoiscripts/10_setup_ai_runtime.sh` | `run_after_10_setup_ai_runtime.sh.tmpl` |
| … | `run_after_11_*` … `run_after_15_*` |

Esas rutas **no tienen por qué existir como ficheros en `~/.chezmoiscripts/`**; Chezmoi las lista como scripts a ejecutar, no como dotfiles materializados en HOME.

- **No uses `chezmoi apply` global** solo para “quitar” esas líneas: un apply global **ejecutaría** los hooks (backup RC, SOPS, runtime AI, symlinks, etc.).
- **No uses `chezmoi forget`** para silenciarlas; no corrige la semántica y puede provocar re-ejecuciones no deseadas.
- **No confundas** `.chezmoiscripts/00_gen_secrets.sh` en status con drift de secretos: el artefacto canónico en HOME es `~/.config/mcp-secrets.env` (SOPS). Un `R` en el script no indica por sí solo que `secrets.sops.yaml` esté mal.
- Para auditar solo scripts: `chezmoi status -i scripts -x ''`.
- Resumen legible: `make chezmoi-drift-report` (marca entradas esperadas como aceptadas).
- Comodidad local (opcional, **no versionado**) si el ruido en `status` molesta:

```toml
[status]
    exclude = ["scripts"]

[diff]
    exclude = ["scripts"]
```

Tras `exclude`, sigue pudiendo auditar con `chezmoi status -i scripts -x ''`.

### Codex — gobernanza versionada (apply acotado)

Política vigente: **preferencias HOME + parametrización Chezmoi mínima**. Los bloques MCP ya están alineados vía plantilla; el drift histórico estaba en la cabecera (modelo, reasoning, `trust_level`, permisos).

| Clave | Default versionado (`.chezmoi.toml` → `[data.codex]`) | Override local |
|-------|------------------------------------------------------|----------------|
| `model` | `"gpt-5.5"` | `[data.codex]` en `~/.config/chezmoi/chezmoi.toml` |
| `model_reasoning_effort` | `"high"` | idem |
| `dotfiles_trust_level` | `"trusted"` para `{{ .chezmoi.sourceDir }}` | omitir clave o vaciar para no emitir `[projects."…"]` |

Plantilla: [`dot_codex/private_config.toml.tmpl`](../dot_codex/private_config.toml.tmpl). Permisos destino: **`600`** vía prefijo Chezmoi `private_` en el nombre de source (convención canónica; no usar `.chezmoiattributes` para este fichero).

**No usar `chezmoi apply` global a ciegas** para Codex. Tras cambios en repo o en datos Chezmoi, aplicar **solo** esa ruta:

```bash
chezmoi --source="$HOME/dotfiles" diff ~/.codex/config.toml
chezmoi --source="$HOME/dotfiles" apply ~/.codex/config.toml
stat -c '%a %n' ~/.codex/config.toml   # esperado: 600
```

Ejemplo override en otra máquina (p. ej. oficina con otro modelo):

```toml
[data.codex]
    model = "gpt-5.4"
    model_reasoning_effort = "medium"
    dotfiles_trust_level = "trusted"
```

Los defaults versionados viven en [`.chezmoi.toml`](../.chezmoi.toml) (`[data.codex]`). Chezmoi fusiona ese bloque con tu config local cuando ambos existen; si solo tienes `~/.config/chezmoi/chezmoi.toml`, añade `[data.codex]` allí o confía en los defaults embebidos en la plantilla (`gpt-5.5`, `high`, `trust_level = trusted` salvo que definas `dotfiles_trust_level = ""` para omitir el bloque `[projects]`).

`make chezmoi-drift-report` señala drift Codex pero **no aplica**; el apply acotado lo ejecuta Jesús manualmente.

### Launchers MCP materializados

Contrato entre tres capas:

| Capa | Ruta |
|------|------|
| Edición lógica (git / gitnexus / postgres) | `bin/mcp-*-launcher` |
| Plantilla Chezmoi | `dot_local/share/chezmoi/bin/executable_mcp-*-launcher.tmpl` |
| Materializado en HOME | `~/.local/share/chezmoi/bin/mcp-*-launcher` |

**Matriz de canonicalidad**

| Launcher | Repo (`bin/` vs plantilla) | HOME | Tests / uso local |
|----------|----------------------------|------|-------------------|
| **git** | `bin/` == plantilla (byte-a-byte) | Sigue plantilla tras `chezmoi apply` | `bin/` para bats de comportamiento |
| **gitnexus** | `bin/` == plantilla | Sigue plantilla tras apply | `bin/` para bats |
| **postgres** | `bin/` == plantilla | Sigue plantilla tras apply | `bin/` para bats |
| **filesystem** | Diseño **dual**: plantilla con `{{ .chezmoi.sourceDir }}` y `{{ .ai.obsidian_vault_path }}` | Plantilla renderizada manda | `bin/` resuelve rutas en runtime (`MCP_DOTFILES_ROOT`, etc.) |

**Validación read-only (repo + CI):**

```bash
make mcp-launcher-contract-check
```

Comprueba igualdad estricta `bin/` ↔ plantilla para git/gitnexus/postgres, excepción documentada para filesystem, rutas productivas en `dot_cursor` / `dot_codex` / `opencode` hacia `~/.local/share/chezmoi/bin/mcp-*` (nunca `~/dotfiles/bin/mcp-*`). El drift en HOME se reporta como **WARN** y no falla el target.

También: `make bats-chezmoi-mcp-launchers` (tests bats del contrato en plantillas).

**Drift HOME (manual):** `M` en `mcp-git-launcher` o `mcp-postgres-launcher` suele ser materialización antigua (tabs vs espacios). Tras sincronizar `bin/` + plantilla en el repo:

```bash
make chezmoi-drift-report   # read-only
chezmoi --source="$HOME/dotfiles" apply \
  ~/.local/share/chezmoi/bin/mcp-git-launcher \
  ~/.local/share/chezmoi/bin/mcp-postgres-launcher
```

Esto **no** sustituye un `chezmoi apply` global y **no** toca Codex ni secretos.

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
