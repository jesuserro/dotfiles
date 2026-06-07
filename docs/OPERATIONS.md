# Operaciones diarias (dotfiles)

Guía humana principal para operar este repositorio en Ubuntu/WSL2.

> **Operación diaria (chuleta):** [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) — flujos casa/oficina, drift Chezmoi, apply acotado, MCP, GitNexus y límites para agentes.

Para instalación inicial paso a paso, ver [INSTALL.md](INSTALL.md). Para Chezmoi y secretos en profundidad, ver [CHEZMOI.md](CHEZMOI.md) y [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md).

> **Legacy:** RCM (`rcup`) fue el gestor histórico de symlinks. **No es operativo.** El flujo canónico es **Chezmoi** + **SOPS/age**.

---

## Modelo mental: tres capas

| Capa | Herramientas | Qué materializa |
|------|--------------|-----------------|
| **1. Bootstrap** | `make install*`, `make deps-*` | Paquetes APT, diagnóstico, opt-in (chezmoi, sops, zsh stack runtime) |
| **2. Materialización** | `chezmoi status` / `diff` / `apply` | MCPs, symlinks RC, secretos generados, launchers, AI runtime |
| **3. Mantenimiento** | `make update`, checks | Windows/WSL, APT, npm, OMZ, MCPs Docker, venv Python — **no** plantillas Chezmoi |

### Regla de oro: `source` vs `chezmoi apply`

| Cambiaste… | Acción |
|------------|--------|
| `~/dotfiles/zshrc`, `aliases`, módulos en `zsh/` | Editar en el repo → **`source ~/.zshrc`** (symlinks ya apuntan al repo) |
| Plantillas `dot_*`, `secrets.sops.yaml`, skills/commands en repo gestionados por Chezmoi | Revisar drift → **`chezmoi apply` acotado** a los paths indicados (ver [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md)); apply global solo bootstrap o intervención humana consciente |
| Secretos cifrados | **`sops secrets.sops.yaml`** → regenerar env (apply o `apply -i scripts`) |
| Herramientas del sistema (Windows/WSL, APT, npm global, OMZ, MCPs) | **`make update`** (no sustituye Chezmoi) |

**No edites a mano:** `~/.config/mcp-secrets.env` (se regenera). **No uses** `sops -d` a stdout.

---

## Máquina nueva (flujo recomendado)

```bash
git clone https://github.com/jesuserro/dotfiles.git ~/dotfiles
cd ~/dotfiles

make install-check
make install DRY_RUN=1
make install SKIP_EXTERNAL=1

make install-chezmoi
make install-sops
make install-zsh-stack          # OMZ + p10k runtime; no toca RC files

# Clave age: restaurar/importar ~/.config/sops/age/keys.txt (ver INSTALL.md)
sops secrets.sops.yaml        # rellenar mcp.* (GitHub, postgres_dsn, MinIO…)

# Si la ruta del vault Obsidian difiere del repo:
#   ~/.config/chezmoi/chezmoi.toml → [data.ai] obsidian_vault_path

make install-dotfiles DOTFILES_APPLY=1

make install-verify
make ai-cursor-check
make ai-mcp-governance
make test-fast
source ~/.zshrc
```

Detalle de bootstrap: [INSTALL.md](INSTALL.md).

---

## Máquina existente (actualizar dotfiles)

Flujo diario canónico: **[OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md)** (casa/oficina, apply acotado).

```bash
cd ~/dotfiles
git pull

make chezmoi-drift-report
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" diff

# Apply acotado solo si el reporte o diff lo indican (MCP, Codex, launchers…)
# Ver OPERATIONS_CHEATSHEET.md §5–6

source ~/.zshrc
make ai-cursor-check
make ai-mcp-governance    # si tocaste MANIFEST o plantillas MCP en el repo
```

**`chezmoi apply` global no es el flujo normal** tras `git pull`. Reservado para:

- **Bootstrap inicial:** `make install-dotfiles DOTFILES_APPLY=1`
- **Recuperación controlada:** humano que revisó `chezmoi diff` completo y acepta el blast radius

`make update` es opcional y separado: actualiza sistema/herramientas, no aplica cambios de plantillas en HOME.

---

## Cambios de zsh / aliases

Los RC files en HOME son **symlinks** al repo:

| HOME | Repo |
|------|------|
| `~/.zshrc` | `~/dotfiles/zshrc` |
| `~/.aliases` | `~/dotfiles/aliases` |
| `~/.p10k.zsh` | `~/dotfiles/powerlevel10k/p10k.zsh` |

- **Editar:** ficheros bajo `~/dotfiles/`, no `~/.zshrc` directamente.
- **Recargar sesión:** `source ~/.zshrc` o `exec zsh -l`.
- **No usar `rcup`.**

Si `chezmoi apply` encuentra un RC que no es symlink (contenido custom), el hook `run_before_00_backup_rc_files` **aborta** salvo que aceptes reemplazo con backup:

```bash
ZSH_RC_APPLY=1 chezmoi --source="$HOME/dotfiles" apply ~/.zshrc ~/.aliases ~/.p10k.zsh
```

---

## Cambios de secretos

1. Editar canónico: `sops ~/dotfiles/secrets.sops.yaml`
2. Regenerar (no editar el env a mano):

   ```bash
   chezmoi --source="$HOME/dotfiles" apply -i scripts
   # o: make install-dotfiles DOTFILES_APPLY=1
   ```

3. Validar sin imprimir valores:

   ```bash
   grep -E '^export POSTGRES_DSN=.' ~/.config/mcp-secrets.env && echo OK
   cut -d= -f1 ~/.config/mcp-secrets.env | sort
   ```

**Postgres MCP:** si `postgres_dsn` está vacío en YAML, el env tendrá `export POSTGRES_DSN=""` y Cursor mostrará `POSTGRES_DSN not set` — no es el contenedor apagado; es secreto vacío. Ver [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md).

---

## Cambios de MCPs

Flujo en el **repo** (plantillas):

```bash
cd ~/dotfiles
# 1. Editar ai/assets/mcps/MANIFEST.yaml (+ recetas si aplica)
make ai-mcp-governance
make ai-mcp-generate APPLY=1    # escribe dot_cursor/, dot_codex/, dot_config/
```

Flujo en **HOME** (Cursor/Codex/OpenCode):

```bash
make chezmoi-drift-report
chezmoi --source="$HOME/dotfiles" diff \
  ~/.cursor/mcp.json ~/.codex/config.toml ~/.config/opencode/opencode.json

chezmoi --source="$HOME/dotfiles" apply \
  ~/.cursor/mcp.json ~/.codex/config.toml ~/.config/opencode/opencode.json

make ai-cursor-check
```

Reinicia Cursor/Codex tras cambios en `mcp.json`.

### Docker MCP

- Config: `docker.exe` + `mcp gateway run` (Docker Desktop MCP Gateway).
- **Docker Desktop debe estar abierto** en Windows; desde WSL usa `docker.exe`.
- Si falla con `Docker Desktop is not running`, abre Docker Desktop — `make update` no lo arregla.

```bash
docker.exe mcp version
docker.exe mcp gateway run --dry-run --verbose
```

### Playwright Docker

`bin/playwright-docker` ejecuta Playwright dentro de Docker desde cualquier
proyecto externo, sin instalar browsers ni Playwright en Ubuntu. Tras
`chezmoi apply`, queda publicado como symlink gestionado
`~/.local/bin/playwright-docker`, que la zsh stack ya deja en `PATH`. Para
aplicar solo este launcher:

```bash
chezmoi --source="$HOME/dotfiles" apply ~/.local/bin/playwright-docker
```

Es útil para automatizaciones de navegador, sesiones y descargas de PDFs
cuando las dependencias locales de Ubuntu/WSL sean problemáticas.

Contrato por defecto:

- Imagen: `mcr.microsoft.com/playwright:v1.60.0-noble`.
- Proyecto: el directorio actual se monta como `/workspace/project`.
- Descargas: `./downloads` se crea y monta como `/workspace/downloads`.
- Usuario: `--user "$(id -u):$(id -g)"`, para no escribir como root.
- Variables: `HOME=/tmp/playwright-home` y
  `PLAYWRIGHT_DOWNLOADS_PATH=/workspace/downloads`.
- Docker: `--rm`, `--init`, `--ipc=host`; no publica puertos.

Ejemplos:

```bash
playwright-docker npx playwright --version
playwright-docker node scripts/download-pdfs.js
PLAYWRIGHT_DOCKER_IMAGE=mcr.microsoft.com/playwright/python:<version>-noble \
  playwright-docker python scripts/download_pdfs.py
```

Para Python, usa la etiqueta publicada en la documentación oficial de
Playwright Python Docker para tu versión de proyecto.

Para guardar PDFs fuera de `./downloads`:

```bash
PLAYWRIGHT_DOCKER_DOWNLOADS="$PWD/pdf-output" \
  playwright-docker node scripts/download-pdfs.js
```

Para pasar opciones extra a `docker run`:

```bash
PLAYWRIGHT_DOCKER_EXTRA_ARGS="--add-host=hostmachine:host-gateway" \
  playwright-docker node scripts/download-pdfs.js
```

Los scripts deben usar el directorio de descargas del contenedor, por ejemplo
`process.env.PLAYWRIGHT_DOWNLOADS_PATH` en Node o
`os.environ["PLAYWRIGHT_DOWNLOADS_PATH"]` en Python. No montes `$HOME`, vaults,
secretos ni rutas amplias salvo que el proyecto lo decida explícitamente.
Credenciales, cookies, CAPTCHA, 2FA, `robots.txt` y términos de uso de webs
externas siguen siendo responsabilidad del proyecto; los tests de dotfiles no
ejecutan scraping real ni hacen smoke tests contra internet.

### Postgres MCP

- Lee `POSTGRES_DSN` de `~/.config/mcp-secrets.env` (generado desde SOPS).
- Requiere `mcp.postgres_dsn` **no vacío** en `secrets.sops.yaml`.
- El launcher es `~/.local/share/chezmoi/bin/mcp-postgres-launcher`.

---

## Uso de `dotfiles-update` y `make update`

**Uso diario:** `dotfiles-update` (desde cualquier directorio; vive en `~/.local/bin` vía Chezmoi).

**Uso interno:** `cd ~/dotfiles && make update`.

Ambos ejecutan el mismo flujo: WinGet en PowerShell, WSL con `wsl --update`, APT, npm global, OpenCode, OMZ, uv, imágenes Docker Excalidraw y runtime MCP.

**No hace:**

- `chezmoi apply`
- Aplicar plantillas MCP a HOME
- Regenerar `mcp-secrets.env`
- Instalar o actualizar Matt Pocock Skills; usa `make update-ai-skills` manualmente
- Arreglar Docker MCP con Desktop cerrado
- Rellenar `POSTGRES_DSN` vacío

Tras `dotfiles-update` (o `make update`), recarga la shell si cambió PATH: `source ~/.zshrc`. Si cambiaste plantillas o secretos en el repo, revisa drift y usa **apply acotado** (ver [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md)), no apply global por defecto.

Ver [UPDATE.md](UPDATE.md).

---

## Chezmoi: comandos y configuración local

```bash
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" diff
make chezmoi-drift-report
# apply acotado a paths concretos — ver OPERATIONS_CHEATSHEET.md
```

Apply global consciente (bootstrap / recuperación): `make install-dotfiles DOTFILES_APPLY=1` o `chezmoi --source="$HOME/dotfiles" apply` **solo** tras revisar el diff completo.

**Config local** (`~/.config/chezmoi/chezmoi.toml`, no versionada): fusiona datos como `obsidian_vault_path`. Opcionalmente, para ocultar en `status`/`diff` las líneas `R` de hooks (comodidad local, no obligatorio):

```toml
[status]
    exclude = ["scripts"]

[diff]
    exclude = ["scripts"]
```

Los `R` de `.chezmoiscripts` son entradas **Run**: hooks `run_before_*` / `run_after_*` que Chezmoi ejecutaría en un `apply`. No son ficheros borrados. Interprétalos con `make chezmoi-drift-report`; no uses `chezmoi apply` global solo para limpiarlos.

Auditar scripts explícitamente: `chezmoi status -i scripts -x ''`.

Detalle: [CHEZMOI.md](CHEZMOI.md).

---

## Validaciones habituales

| Comando | Mutación | Uso |
|---------|----------|-----|
| `make install-check` | No | Diagnóstico bootstrap |
| `make deps-check` | No | Inventario APT |
| `make ai-cursor-check` | No | Readiness HOME / Cursor |
| `make ai-mcp-governance` | No | Coherencia MANIFEST ↔ plantillas |
| `make test-fast` | No | Lint + bats |
| `chezmoi diff` | No | Ver drift HOME |

---

## Riesgos y comandos que requieren cuidado

| Comando | Riesgo |
|---------|--------|
| `make install` / `make install-apt` | sudo + APT |
| `chezmoi apply` | Sobrescribe MCPs, RC, regenera secretos |
| `ZSH_RC_APPLY=1 chezmoi apply` | Backup y reemplazo de RC custom |
| `make ai-mcp-generate APPLY=1` | Reescribe plantillas MCP en el repo |
| `make update` | PowerShell/WinGet, sudo, upgrade APT, npm global |
| `make install-mattpocock-skills` / `make update-ai-skills` | Instala o actualiza el catálogo Matt completo en `~/.agents/skills/` y limpia symlinks accidentales bajo `ai/assets/skills/` |
| `sops -d secrets.sops.yaml` | Imprime secretos en stdout — evitar |

---

## Chuleta rápida

La chuleta operativa canónica (casa/oficina, apply acotado, agentes) está en **[OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md)**.

Comandos de referencia rápida (sin sustituir la chuleta):

```bash
cd ~/dotfiles && git pull
make chezmoi-drift-report
chezmoi --source="$HOME/dotfiles" status
make update-check && make update          # humano
make ai-cursor-check
make ai-mcp-governance
make test-fast
```
