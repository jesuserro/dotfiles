# Comando `ups`

Actualización integral del sistema: Windows/winget en WSL, paquetes APT, npm, Oh My Zsh, repositorios auxiliares, servidores MCP y servicios.

**Definición:** `aliases` (gestionado por RCM/rcup)

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
| 📚 **NPM** | `npm update -g codex` + `corepack prepare pnpm@latest --activate` |
| ⚡ **Oh My Zsh** | `omz update`, `upgrade_oh_my_zsh_custom` |
| 📄 **RenderCV (jesuserro)** | `~/proyectos/jesuserro` — `git pull --rebase --autostash` + `uv pip install --python .venv/bin/python -U "rendercv[full]==2.7"` |
| 🔌 **MCP** | excalidraw, docker/postgres, fetch, Python MCPs |
| 🔄 **Servicios** | Reinicio Apache y MySQL (si están instalados) |

---

## Servidores MCP actualizados

| MCP / Origen | Acción |
|--------------|--------|
| **excalidraw** | `~/mcp-servers/excalidraw-mcp` — `git pull --rebase --autostash` + `pnpm install` + `pnpm run build` |
| **docker, postgres** (npm) | `~/.config/mcp/servers/*/` — `npm update` en cada directorio con `package.json` |
| **fetch** | `uv tool install mcp-server-fetch` |
| **dagster, minio, tempo, loki, prometheus, store_etl_ops** | `pip install -r requirements.txt -U` en `~/.config/ai/runtime/.venv` |
| **context7, github** | Usan `npx` — obtienen la última versión al ejecutarse |

---

## Notas

- **WSL:** Detecta Ubuntu WSL y lo indica al inicio.
- **winget en WSL:** Si `wt.exe` y `powershell.exe` están disponibles, `ups` abre una nueva pestaña de Windows Terminal y lanza la actualización de paquetes de Windows en paralelo.
- **Errores:** Si una sección falla, el proceso continúa. El resumen final muestra el total de errores.
- **pnpm:** Si `corepack` está disponible, `ups` intenta activar la última versión estable de `pnpm`.
- **jesuserro:** Si existe `~/proyectos/jesuserro`, `ups` actualiza el repo y refresca la instalación de `rendercv[full]==2.7` dentro de `./.venv`, manteniendo deliberadamente ese pin para no desalinearlo del schema `v2.7` usado en la plantilla. No regenera el CV.
- **Versiones futuras de RenderCV:** El salto a `2.8` o superior debe hacerse manualmente cuando se revise la compatibilidad del YAML y del schema del proyecto.
- **excalidraw:** Puede mostrar un warning de pnpm sobre "Ignored build scripts"; el build completa correctamente.
- **Termux:** Usa `alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"` (ver `termux/install.sh`).

---

## Relacionado

| Doc | Contenido |
|-----|-----------|
| [GUIA_MCP_AI.md](GUIA_MCP_AI.md#7-actualización-de-mcps-con-ups) | Actualización MCP con ups |
| [INSTALL.md](INSTALL.md) | Instalación inicial |
| [README.md](README.md) | Índice de documentación |
| Skill `ups-workflow` | Guía para extender ups (ai/assets/skills/ups-workflow/) |
