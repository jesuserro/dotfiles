# Chuleta operativa (dotfiles)

Referencia corta por escenario. Detalle en [OPERATIONS.md](OPERATIONS.md), [CHEZMOI.md](CHEZMOI.md), [UPDATE.md](UPDATE.md), [INSTALL.md](INSTALL.md).

---

## 1. Cómo usar esta chuleta

| Capa | Herramientas | Qué hace |
|------|--------------|----------|
| **Descubrimiento** | `make help` | Índice CLI de targets por riesgo (read-only vs humano/mutante) |
| **Bootstrap** | `make install*`, `make deps-*` | Paquetes y opt-ins en máquina nueva |
| **Materialización** | `chezmoi status` / `diff` / apply acotado | Publica plantillas y secretos en HOME |
| **Mantenimiento** | `make update`, checks read-only | Sistema, npm, imágenes MCP — **no** sustituye Chezmoi |

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
cd ~/dotfiles
git pull
make chezmoi-drift-report
chezmoi --source="$HOME/dotfiles" status
chezmoi --source="$HOME/dotfiles" diff
# apply acotado solo si el reporte o diff lo indican (ver §5–6)
source ~/.zshrc                 # si cambió PATH tras apply
make update-check
make update                     # humano: muta sistema, puede usar red
```

- Si materializaste MCP/Codex/launchers: **`make ai-cursor-check`**.
- **`make update`:** humano; APT/sudo, npm, Docker pull, WinGet en otra pestaña.

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

---

## 9. Skills

```bash
make validate-skills-structure              # read-only: árbol ai/assets/skills/
make install-mattpocock-skills DRY_RUN=1  # agente: solo simulación
```

- Instalación Matt real (`make install-mattpocock-skills` sin `DRY_RUN`): **humano**; usa red (`npx skills add`).
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
| General | `make agent-validate-changed` |

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
| `make chezmoi-drift-report` | No | No | Tras `git pull` / merge |
| `make mcp-launcher-contract-check` | No | No | Cambios launchers / plantillas MCP |
| `make gitnexus-status` | No | No | Estado índice/lock/Node |
| `make validate-skills-structure` | No | No | Cambios en skills locales |
| `make ai-mcp-governance` | No | No | Cambios MANIFEST / plantillas |
| `make test-chezmoi` | No | No | Cambios Chezmoi / hooks |
| `make test-bats-ci` | No | No | Paridad CI / pre-PR |
| `make ai-doctor` | No | No | Readiness agregado pre-implementación |
| `make ai-cursor-check` | No | No | Tras materializar MCP en HOME |
| `make agent-validate-changed` | No | No | Cierre de rama con cambios |

---

## Referencias

- [OPERATIONS.md](OPERATIONS.md) — guía larga
- [CHEZMOI.md](CHEZMOI.md) — drift, Codex, launchers
- [UPDATE.md](UPDATE.md) — `make update`
- [INSTALL.md](INSTALL.md) — bootstrap
- [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md)
- [MCP_QUICKREF.md](MCP_QUICKREF.md)
- [TESTING.md](TESTING.md)
