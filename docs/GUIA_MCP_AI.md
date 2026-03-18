# Guía práctica: MCP y AI Workstation

Comandos de terminal para trabajar con MCPs y el hub AI en dotfiles.

---

## 1. Aplicar cambios (después de pull o editar dotfiles)

```bash
cd ~/dotfiles
chezmoi --source=$HOME/dotfiles apply
```

Crea/actualiza: `~/.cursor/mcp.json`, `~/.codex/config.toml`, `~/.config/ai/`, venv, skills.

---

## 2. Verificar que MCPs funcionan

```bash
# Trino MCP
~/.config/ai/runtime/.venv/bin/python -m trino_mcp --help

# Dagster MCP (smoke test)
~/.config/ai/runtime/.venv/bin/python ~/dotfiles/ai/runtime/mcp/servers/dagster/server.py --smoke-test

# MinIO MCP (smoke test)
~/.config/ai/runtime/.venv/bin/python ~/dotfiles/ai/runtime/mcp/servers/minio/server.py --smoke-test
```

---

## 3. Añadir un nuevo MCP servidor Python

### Paso 1: Crear el servidor

```bash
cd ~/dotfiles
mkdir -p ai/runtime/mcp/servers/mi_mcp
```

Crear `ai/runtime/mcp/servers/mi_mcp/server.py` siguiendo el patrón de `dagster/server.py` o `minio/server.py`.

### Paso 2: Añadir dependencias (si hace falta)

```bash
# Editar ai/runtime/mcp/requirements.txt
vim ai/runtime/mcp/requirements.txt
```

### Paso 3: Registrar en la config

**MCP global (Cursor):** editar `dot_cursor/mcp.json.tmpl`

**MCP store-etl (Cursor):** editar `private_dot_config/store-etl/store-etl.mcp.json.tmpl`

**Codex:** editar `dot_codex/config.toml.tmpl`

Ejemplo para Cursor (`dot_cursor/mcp.json.tmpl`):

```json
"mi_mcp": {
  "command": "{{ .chezmoi.homeDir }}/.config/ai/runtime/.venv/bin/python",
  "args": ["{{ .chezmoi.sourceDir }}/ai/runtime/mcp/servers/mi_mcp/server.py"],
  "env": {}
}
```

Ejemplo para Codex (`dot_codex/config.toml.tmpl`):

```toml
[mcp_servers.mi_mcp]
command = "{{ .chezmoi.homeDir }}/.config/ai/runtime/.venv/bin/python"
args = ["{{ .chezmoi.sourceDir }}/ai/runtime/mcp/servers/mi_mcp/server.py"]
enabled = true
```

### Paso 4: Aplicar

```bash
chezmoi --source=$HOME/dotfiles apply
```

---

## 4. Añadir un skill

```bash
cd ~/dotfiles
git clone https://github.com/owner/skill-repo.git ai/assets/skills/nombre-skill
rm -rf ai/assets/skills/nombre-skill/.git
chezmoi --source=$HOME/dotfiles apply
```

El script `run_after_11_link_ai_assets` symlinkea cada skill en `~/.cursor/skills-cursor/`, `~/.codex/skills/` y `~/.config/opencode/skills/`.

---

## 5. Reinstalar venv (si se corrompe)

```bash
rm -rf ~/.config/ai/runtime/.venv
chezmoi --source=$HOME/dotfiles apply
```

---

## 6. Estructura de rutas (referencia rápida)

| Concepto        | Ruta en dotfiles           | Ruta en ~/                    |
|-----------------|----------------------------|-------------------------------|
| MCP servers     | `ai/runtime/mcp/servers/`  | —                             |
| Requirements    | `ai/runtime/mcp/requirements.txt` | —                    |
| Venv            | —                          | `~/.config/ai/runtime/.venv`  |
| Hub skills      | `ai/assets/skills/`       | `~/.config/ai/skills` (symlink) |
| Config Cursor   | `dot_cursor/mcp.json.tmpl` | `~/.cursor/mcp.json`          |
| Config Codex    | `dot_codex/config.toml.tmpl` | `~/.codex/config.toml`     |
| Config OpenCode | `dot_config/opencode/`     | `~/.config/opencode/` (XDG)   |

> **Nota arquitectónica:** Cada tool usa su convención nativa (Cursor/Codex → `~/.`, OpenCode → XDG). No forces simetría visual. Ver [docs/OPENCODE.md](./OPENCODE.md) para detalles.

---

## 7. Actualización de MCPs con `ups`

El alias `ups` incluye una sección que actualiza los servidores MCP:

| MCP / Origen | Qué hace `ups` |
|--------------|----------------|
| **excalidraw** | `~/mcp-servers/excalidraw-mcp` — `git pull` + `pnpm install` + `pnpm run build` |
| **docker, postgres** (npm) | `~/.config/mcp/servers/*/` — `npm update` en cada directorio con `package.json` |
| **fetch** | `uv tool install mcp-server-fetch` (instala o actualiza) |
| **filesystem** | Launcher local — no requiere actualización |
| **git** | `uvx mcp-server-git` — se actualiza al ejecutarse |
| **sequential-thinking** | `npx -y @modelcontextprotocol/server-sequential-thinking` (obtiene latest al ejecutar) |
| **obsidian** | `npx -y @bitbonsai/mcpvault` (obtiene latest al ejecutar) |
| **dagster, minio, tempo, loki, prometheus, store_etl_ops** | `pip install -r requirements.txt -U` en `~/.config/ai/runtime/.venv` |
| **context7, github, gitnexus (MCP)** | Usan `npx` — obtienen la última versión al ejecutarse |

**gitnexus CLI** se actualiza por separado: `npm install -g --prefix=~/.local gitnexus@latest`

Tras ejecutar `ups`, aplica los cambios del shell con: `source ~/.zshrc`
