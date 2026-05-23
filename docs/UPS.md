# Comando `ups`

Actualización integral del sistema: Windows/winget en WSL, paquetes APT, npm, OpenCode, Oh My Zsh, repositorios auxiliares, servidores MCP y servicios.

**Definición:** `aliases` (cargado por `~/.aliases`, symlink gestionado por Chezmoi).

## Qué hace y qué no hace

| `ups` sí | `ups` no |
|----------|----------|
| APT, npm global, OMZ, builds excalidraw, pip en venv AI | `chezmoi apply` |
| Actualizar paquetes npm en `~/.config/mcp/servers/*` | Regenerar `~/.config/mcp-secrets.env` |
| `uv tool install mcp-server-fetch` | Aplicar plantillas MCP del repo a HOME |

Tras cambiar **plantillas Chezmoi**, **secretos SOPS** o **MANIFEST MCP** en el repo, usa **`chezmoi --source=$HOME/dotfiles apply`** (o `make install-dotfiles DOTFILES_APPLY=1`), no solo `ups`.

**Troubleshooting MCP (no se arregla con `ups`):**

- **Docker MCP:** Docker Desktop debe estar **abierto** en Windows; el gateway usa `docker.exe mcp gateway run`. Si Desktop está cerrado, `npm update` no ayuda.
- **Postgres MCP:** error `POSTGRES_DSN not set` → `mcp.postgres_dsn` vacío en `secrets.sops.yaml`; edita con `sops` y `chezmoi apply -i scripts`. Ver [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md).

Guía operativa completa: [OPERATIONS.md](OPERATIONS.md).

---

## Uso

```bash
ups
source ~/.zshrc   # Aplicar cambios en la sesión actual
```

---

## Secciones que ejecuta

| Sección | Qué hace |
|--------|----------|
| 🪟 **Windows** | En WSL, abre una nueva pestaña de PowerShell y ejecuta `winget source update` + `winget upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements` |
| 🔐 **Autenticación sudo** | Verifica credenciales |
| 📦 **APT** | `apt-get update`, `apt-get upgrade`, `apt-get autoremove` |
| 🧹 **Limpieza** | Elimina paquetes no utilizados |
| 📚 **NPM** | `npm install -g --prefix=~/.npm-global @openai/codex@latest` + `corepack prepare pnpm@latest --activate` |
| 📦 **GitNexus** | `npm install -g --prefix=~/.npm-global gitnexus@latest` |
| 🤖 **OpenCode** | `curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path` |
| ⚡ **Oh My Zsh** | `omz update`, `upgrade_oh_my_zsh_custom` |
| 🐍 **uv (Python)** | `uv self update` solo si `uv` existe en `$HOME/.local/bin/uv`. Si falta, info y skip (instalar con `make install-uv`). Si vive en otra ruta (apt/brew), info: actualizar con su gestor. |
| 📄 **RenderCV (jesuserro)** | `~/proyectos/jesuserro` — `git pull --rebase --autostash` + `uv pip install --python .venv/bin/python -U "rendercv[full]==2.7"` |
| 🔌 **MCP** | excalidraw, docker/postgres, fetch, Python MCPs |
| 🔄 **Servicios** | Reinicio Apache y MySQL (si están instalados) |

---

## Servidores MCP actualizados

| MCP / Origen | Acción |
|--------------|--------|
| **gitnexus** | `npm install -g --prefix=~/.npm-global gitnexus@latest` (CLI, separado del MCP) |
| **excalidraw** | `~/mcp-servers/excalidraw-mcp` — si el repo fija un `packageManager` antiguo, `ups` lo sincroniza con el `pnpm` activo; después ejecuta `git pull --rebase --autostash` + `pnpm install` + `pnpm run build` |
| **docker** | Docker Desktop MCP Gateway oficial: `docker.exe mcp gateway run` desde WSL; se actualiza con Docker Desktop |
| **postgres** (npm) | `~/.config/mcp/servers/*/` — `npm update` en cada directorio con `package.json` (solo si existe) |
| **fetch** | `uv tool install mcp-server-fetch` |
| **dagster, minio, tempo, loki, prometheus, store_etl_ops** | Runtime Python en `~/.config/ai/runtime/.venv` (sincronizado por Chezmoi con `uv`; ver [CHEZMOI.md](CHEZMOI.md)) |

### MCPs que se resuelven en runtime (no requieren actualización explícita)

Estos MCPs usan `npx -y` o `uvx` y obtienen la última versión automáticamente al ejecutarse:

| MCP | Patrón |
|-----|--------|
| **context7** | `npx -y @upstash/context7-mcp` |
| **github** | `npx -y @modelcontextprotocol/server-github` |
| **sequential-thinking** | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| **filesystem** | Launcher local (no requiere actualización) |
| **git** | `uvx mcp-server-git` (se actualiza al ejecutarse) |
| **obsidian** | `npx -y @bitbonsai/mcpvault` |

### gitnexus: CLI vs MCP

- **CLI** (`gitnexus`): Se actualiza con `npm install -g --prefix=~/.npm-global gitnexus@latest`
- **MCP** (`npx -y gitnexus@latest mcp`): Se resuelve en runtime, no necesita actualización

---

## Notas

- **uv (Python):** `ups` solo intenta `uv self update` cuando `uv` ya está instalado en la ruta canónica del instalador oficial (`$HOME/.local/bin/uv`). Si `uv` falta, no lo instala (eso lo hace `make install-uv`). Si está gestionado por `apt`/`brew`/etc., `ups` lo informa pero deja la actualización a su gestor. El venv runtime AI (`~/.config/ai/runtime/.venv`) lo sincroniza Chezmoi con `uv` y hash de `ai/runtime/mcp/requirements.txt`.
- **WSL:** Detecta Ubuntu WSL y lo indica al inicio.
- **winget en WSL:** Si `wt.exe` y `powershell.exe` están disponibles, `ups` abre una nueva pestaña de Windows Terminal y lanza la actualización de paquetes de Windows en paralelo.
- **Errores e incidencias:** Si una sección falla, el proceso continúa. El resumen final ya distingue entre errores y warnings/incidencias, para no vender un éxito limpio cuando hubo fallos parciales.
- **npm global canónico:** Los CLIs npm globales del repo usan `~/.npm-global` mediante `NPM_CONFIG_PREFIX` publicado desde `zsh/00-env.zsh`; `ups` respeta ese prefijo sin usar `sudo`.
- **Codex CLI:** `ups` actualiza Codex con `npm install -g --prefix=~/.npm-global @openai/codex@latest`, retira de forma explícita el paquete legacy `codex` solo si detecta ese conflicto en el mismo prefijo, y deja evidencia con `codex --version` cuando la actualización termina bien.
- **GitNexus CLI:** Si la actualización directa falla sobre una instalación existente en el mismo prefijo, `ups` intenta una reinstalación limpia del paquete `gitnexus` y reporta con honestidad si quedó la versión previa o si no quedó binario usable.
- **GitNexus CLI — incidencia conocida para agentes IA:** Por ahora no hay evidencia de corrupción general del prefijo npm global; la causa más probable es fragilidad del update incremental in-place de npm sobre el árbol de `gitnexus`, especialmente por dependencias nativas/vendorizadas como `tree-sitter-proto` y `node-addon-api`. La mitigación aceptada es intentar `npm install -g` y, si falla, hacer `npm uninstall -g` + reinstalación limpia del paquete. No hace falta rediseñar `ups` ni sacar GitNexus del flujo global salvo que empiece a afectar a otros paquetes npm, falle también tras reinstalación limpia, o deje binario/versionado inconsistente.
- **opencode.ai:** `ups` ejecuta el instalador oficial por `curl` con `--no-modify-path`, para cubrir instalación inicial y actualización sin depender de permisos de `npm -g` en `/usr`.
- **pnpm:** Si `corepack` está disponible, `ups` intenta activar la última versión estable de `pnpm`. En proyectos que fijan `packageManager` con `pnpm`, `ups` sincroniza ese pin antes de construirlos para evitar quedarse en una versión antigua.
- **jesuserro:** Si existe `~/proyectos/jesuserro`, `ups` actualiza el repo y refresca la instalación de `rendercv[full]==2.7` dentro de `./.venv`, manteniendo deliberadamente ese pin para no desalinearlo del schema `v2.7` usado en la plantilla. No regenera el CV.
- **Versiones futuras de RenderCV:** El salto a `2.8` o superior debe hacerse manualmente cuando se revise la compatibilidad del YAML y del schema del proyecto.
- **excalidraw:** Puede mostrar un warning de pnpm sobre "Ignored build scripts"; el build completa correctamente.
- **Termux:** Usa `alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"` (ver `termux/install.sh`).

---

## Relacionado

| Doc | Contenido |
|-----|-----------|
| [MCP_TAXONOMY.md](MCP_TAXONOMY.md) | Taxonomía de MCPs (capas y políticas) |
| [GUIA_MCP_AI.md](GUIA_MCP_AI.md#7-actualización-de-mcps-con-ups) | Actualización MCP con ups |
| [INSTALL.md](INSTALL.md) | Instalación inicial |
| [OPERATIONS.md](OPERATIONS.md) | Guía operativa (Chezmoi vs ups) |
| [README.md](README.md) | Índice de documentación |
| Skill `dotfiles-ups-workflow` | Guía para extender ups (`ai/assets/skills/ops/system-updates/`) |
