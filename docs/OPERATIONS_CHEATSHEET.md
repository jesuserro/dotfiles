# Chuleta operativa (dotfiles)

Referencia corta por escenario. Detalle en [OPERATIONS.md](OPERATIONS.md), [CHEZMOI.md](CHEZMOI.md), [UPDATE.md](UPDATE.md), [INSTALL.md](INSTALL.md).

---

## 1. Cómo usar esta chuleta

| Capa | Herramientas | Qué hace |
|------|--------------|----------|
| **Descubrimiento** | `make help` | Índice CLI de targets por riesgo (read-only vs humano/mutante) |
| **Bootstrap** | `make install*`, `make deps-*` | Paquetes y opt-ins en máquina nueva |
| **Materialización** | `chezmoi status` / `diff` / apply acotado | Publica plantillas y secretos en HOME |
| **Mantenimiento** | `dotfiles-update`, checks read-only | Sistema, npm, imágenes MCP — **no** sustituye Chezmoi |

**Regla principal:** tras `git pull` o merge, revisa drift (`make chezmoi-drift-report`, `chezmoi status`/`diff`) y aplica **solo los paths que el reporte indique**. **`chezmoi apply` global no es el flujo normal** del día a día.

---

## 2. Instalación inicial (humano)

Secuencia mínima — paso a paso en [INSTALL.md](INSTALL.md):

```bash
cd ~/dotfiles
make install-check
make install DRY_RUN=1          # opcional: simular
make install SKIP_EXTERNAL=1    # APT + plan
make install-chezmoi && make install-sops && make install-zsh-stack
# Restaurar ~/.config/sops/age/keys.txt (manual)
sops secrets.sops.yaml
make install-dotfiles DOTFILES_APPLY=1   # bootstrap consciente: apply completo
make install-verify
make ai-cursor-check
make ai-doctor                  # opcional: readiness agregado
source ~/.zshrc
```

- **`make update` no es el primer paso** de bootstrap.
- **`DOTFILES_APPLY=1` / apply completo:** solo bootstrap o humano que acepta el blast radius (MCPs, RC, secretos).

---

## 3. Día normal — casa

```bash
cd ~/dotfiles && git pull
make chezmoi-drift-report
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" diff
# apply acotado solo si el reporte o diff lo indican (ver §5–6)
source ~/.zshrc                 # si cambió PATH tras apply
make update-check
dotfiles-update                 # humano: muta sistema, puede usar red
```

- Si materializaste MCP/Codex/launchers: **`make ai-cursor-check`**.
- **`dotfiles-update`:** humano; APT/sudo, npm, Docker pull, WinGet en otra pestaña. Desde el repo: `make update`.

---

## 4. Día normal — oficina / fork

Ajusta remotes y rama a tu fork (placeholders):

```bash
cd ~/dotfiles
git fetch upstream
git merge upstream/dev          # o tu rama de integración
make chezmoi-drift-report
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" diff
# apply acotado solo paths necesarios (§6)
```

- Revisa **`~/.config/chezmoi/chezmoi.toml`**: `obsidian_vault_path`, `[data.codex]`, rutas corporativas.
- **No versiones** paths de oficina en el repo; overrides solo en config local Chezmoi.
- Mismo criterio: sin `chezmoi apply` global salvo decisión explícita.

---

## 5. Drift Chezmoi

| Herramienta | Mutación | Uso |
|-------------|----------|-----|
| `make chezmoi-drift-report` | No | Resumen read-only + hints de apply acotado |
| `chezmoi --source="$HOME/dotfiles" status` | No | Qué diverge en HOME |
| `chezmoi --source="$HOME/dotfiles" diff` | No | Detalle antes de aplicar |

| Tipo de drift | Acción |
|---------------|--------|
| **Codex** (`~/.codex/config.toml`) | Apply acotado (§6); ver [CHEZMOI.md](CHEZMOI.md) — Codex |
| **Launchers MCP** (`~/.local/share/chezmoi/bin/mcp-*`) | Apply acotado de esos launchers |
| **Configs MCP** (Cursor/OpenCode/Codex) | Apply acotado de `mcp.json` / `opencode.json` / `config.toml` |
| **Scripts `R` en status** | Hooks que se ejecutarían en apply (`R` = Run); ruido esperado. Ver `make chezmoi-drift-report` y [CHEZMOI.md](CHEZMOI.md). No apply global para “limpiar”; no implica secretos rotos |
| **Secretos** (`mcp-secrets.env`) | Solo con decisión explícita: `sops secrets.sops.yaml` → `chezmoi apply -i scripts` |

---

## 6. Apply acotado — copiar/pegar

Estos bloques **no sustituyen** un `chezmoi apply` global.

**Codex:**

```bash
chezmoi --source="$HOME/dotfiles" diff ~/.codex/config.toml
chezmoi --source="$HOME/dotfiles" apply ~/.codex/config.toml
stat -c '%a %n' ~/.codex/config.toml   # esperado: 600
```

**Launchers MCP:**

```bash
chezmoi --source="$HOME/dotfiles" apply \
  ~/.local/share/chezmoi/bin/mcp-git-launcher \
  ~/.local/share/chezmoi/bin/mcp-postgres-launcher
```

**Superficies MCP globales:**

```bash
chezmoi --source="$HOME/dotfiles" apply \
  ~/.cursor/mcp.json \
  ~/.config/opencode/opencode.json \
  ~/.codex/config.toml
```

Tras apply: `make ai-cursor-check` y reiniciar Cursor/Codex si cambió `mcp.json`.

---

## 7. MCP y agentes

| Comando | Mutación | Cuándo |
|---------|----------|--------|
| `make mcp-launcher-contract-check` | No | Tras editar `bin/mcp-*` o plantillas launcher |
| `make ai-mcp-governance` | No | Tras `MANIFEST.yaml` o plantillas MCP en repo |
| `make ai-cursor-check` | No | Tras materializar en HOME |

- Runtime productivo: **`~/.local/share/chezmoi/bin/mcp-*-launcher`** (no `~/dotfiles/bin/` en configs de agente).
- No edites `~/.cursor/mcp.json` a mano si viene de Chezmoi.
- **`make ai-mcp-generate APPLY=1`:** solo humano / petición explícita (reescribe plantillas en repo).

Referencia agentes: [MCP_QUICKREF.md](MCP_QUICKREF.md).

---

## 8. GitNexus

| Quién | Permitido |
|-------|-----------|
| **Agentes** | `make gitnexus-status`; MCP GitNexus read-only (`gitnexus_query`, `gitnexus_context`, `gitnexus_impact`, …) |
| **Humanos** | `gnx-analyze-here`, `gnx-wiki-here`, `gnx-serve`, `gnx-map` — solo con decisión explícita |

**Prohibido para agentes (salvo petición explícita de Jesús):**

- `npx gitnexus` / `npx gitnexus analyze`
- `gitnexus analyze` / `gitnexus wiki` / `gitnexus clean`
- Borrar `.gitnexus/` o `.gitnexus/lbug`
- Editar bloques `<!-- gitnexus:* -->` en `AGENTS.md` / `CLAUDE.md`

Política completa: [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md).

### Hooks locales del repo

```bash
make install-git-hooks
```

Configura `core.hooksPath=.githooks` solo para este checkout. El pre-commit
ejecuta `treegen` antes de cada commit; si regenera `STRUCTURE.md`, stagea
automáticamente solo ese fichero y deja continuar el commit. No stagea otros
cambios del workspace. El post-commit refresca GitNexus con `--force --skip-agents-md` de forma síncrona,
best-effort y no fatal. Si detecta MCP/lock activo o permisos no escribibles en
`~/.gitnexus` / `registry.json`, omite el refresh con `WARN` (el índice puede
quedar STALE). Si no hay contención y el analyze falla o expira tras 30 segundos,
refresca manualmente con `make gitnexus-status` y
`gnx-analyze-here --force --skip-agents-md`. Si hay varios procesos
`gitnexus mcp`, cierra sesiones duplicadas de Cursor antes de refrescar.

Escapes: `DOTFILES_SKIP_HOOKS=1`, `DOTFILES_SKIP_TREEGEN=1`,
`DOTFILES_SKIP_GITNEXUS=1`.

### Refresh humano del índice

Solo **humano**; los agentes no ejecutan analyze ni refresh por `STALE`. Sin `npx gitnexus` (ver prohibiciones §8). Con `--skip-agents-md` no se tocan los bloques `<!-- gitnexus:* -->` en `AGENTS.md` / `CLAUDE.md`.

```bash
make gitnexus-status
# cerrar Cursor/MCP si hay procesos vivos o lock activo
gnx-analyze-here --skip-agents-md
make gitnexus-status
git status --short -- .gitnexus AGENTS.md CLAUDE.md docs/wiki
make bats-docs
```

---

## 9. Skills

```bash
make validate-skills-structure              # read-only: árbol ai/assets/skills/
make install-mattpocock-skills DRY_RUN=1  # agente: solo simulación
make update-ai-skills DRY_RUN=1             # agente: previsualizar refresh del catálogo externo
```

- Instalación Matt real (`make install-mattpocock-skills` sin `DRY_RUN`): **humano**; usa red (`npx skills add`).
- Refresh Matt (`make update-ai-skills` sin `DRY_RUN`): **humano**; usa red; **no** forma parte de `make update`.
- Skill **local** bajo `ai/assets/skills/` gana sobre catálogo externo Matt.

---

## 10. Cierre de implementación

| Tipo de cambio | Validaciones |
|----------------|--------------|
| Shell / scripts | `make test-bats-fast` |
| Chezmoi | `make test-chezmoi` |
| MCP | `make mcp-launcher-contract-check`, `make ai-mcp-governance` |
| GitNexus docs/aliases | `bats tests/bats/zsh/gitnexus_aliases.bats`, `make gitnexus-status` |
| Skills | `make validate-skills-structure` |
| General | `make agent-validate` (gate dotfiles); `make agent-validate-changed` (solo cambios); `SECURITY_ONLINE=1` para OSV estricto |

Readiness agregado (no sustituye tests focalizados): `make ai-doctor`.

Detalle: [TESTING.md](TESTING.md).

---

## 11. Política para agentes

- **No** ejecutar `make update` (muta sistema, red).
- **No** `chezmoi apply` global ni apply acotado **sin** petición explícita de mutar HOME.
- **No** `make ai-mcp-generate APPLY=1`.
- **No** `make install-mattpocock-skills` sin `DRY_RUN=1`.
- **No** GitNexus mutante (analyze, wiki, clean, `npx gitnexus`).
- **No** borrar `.gitnexus/lbug`.
- **No** tocar secretos: `sops -d`, editar `~/.config/mcp-secrets.env`, `.sops.yaml`, `secrets.sops.yaml`, claves Age.
- **No** modificar `AGENTS.md` / `CLAUDE.md` por bloques GitNexus en este repo.

---

## 12. Tabla rápida: comando → escenario

| Comando | Mutación | Red | Escenario |
|---------|----------|-----|-----------|
| `make update-check` | No | No | Antes de `make update` o trabajo GitNexus largo |
| `make update` | Sí | Sí | Mantenimiento diario (humano) |
| `make update-ai-skills DRY_RUN=1` | No | No | Previsualizar actualización del catálogo externo Matt Pocock Skills |
| `make update-ai-skills` | Sí | Sí | Refresh explícito del catálogo externo Matt; humano; no forma parte de `make update` |
| `make chezmoi-drift-report` | No | No | Tras `git pull` / merge |
| `make mcp-launcher-contract-check` | No | No | Cambios launchers / plantillas MCP |
| `make gitnexus-status` | No | No | Estado índice/lock/Node |
| `make install-git-hooks` | Sí, local repo | No | Activar pre-commit treegen y post-commit GitNexus en este checkout |
| `make validate-skills-structure` | No | No | Cambios en skills locales |
| `make ai-mcp-governance` | No | No | Cambios MANIFEST / plantillas |
| `make test-chezmoi` | No | No | Cambios Chezmoi / hooks |
| `make test-bats-ci` | No | No | Paridad CI / pre-PR |
| `make ai-doctor` | No | No | Readiness agregado pre-implementación |
| `make ai-cursor-check` | No | No | Tras materializar MCP en HOME |
| `make agent-validate` | No | No | Gate dotfiles post-BUILD (read-only) |
| `make agent-validate-report` | No | No | Gate + informe en `build/agent-validation/latest.md` |
| `make agent-validate-changed` | No | No | Solo archivos cambiados (local; sin OSV online) |
| `make agent-validate-audit` | No | No | Auditoría full-repo estricta (lint + security) |
| `SECURITY_ONLINE=1 make agent-validate-changed` | No | Sí | Cierre humano con escaneo OSV estricto |

---

## Referencias

- [OPERATIONS.md](OPERATIONS.md) — guía larga
- [CHEZMOI.md](CHEZMOI.md) — drift, Codex, launchers
- [UPDATE.md](UPDATE.md) — `make update`
- [INSTALL.md](INSTALL.md) — bootstrap
- [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md)
- [MCP_QUICKREF.md](MCP_QUICKREF.md)
- [TESTING.md](TESTING.md)
