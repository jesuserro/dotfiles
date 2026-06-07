# AI Repo Map — mapa operativo para agentes

## 1. Propósito

Este documento explica **intención, contratos, riesgos y validación** por zona del repositorio dotfiles, orientado a agentes IA.

**No sustituye a [STRUCTURE.md](../STRUCTURE.md):**

| Documento | Rol |
|-----------|-----|
| **STRUCTURE.md** | Árbol completo del repo (inventario, generado automáticamente) |
| **AI_REPO_MAP.md** | Qué hace cada zona, qué riesgos tiene y qué validar al cambiarla |

Contrato de comportamiento del agente: [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md). Matriz cambio → validación: [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md).

---

## 2. Capas principales del repo

El repo sigue un modelo de tres capas (detalle en [OPERATIONS.md](OPERATIONS.md)):

| Capa | Qué es | Ejemplos |
|------|--------|----------|
| **Bootstrap** | Instalación inicial en máquina nueva | `make install*`, `install.mk` |
| **Materialización** | Publicar plantillas y secretos en HOME | Chezmoi, `.chezmoiscripts/`, `dot_*` |
| **Mantenimiento** | Actualización diaria sin sustituir Chezmoi | `make update`, `scripts/update/` |

Los agentes suelen trabajar en la capa **fuente del repo** (plantillas, scripts, docs, assets IA), no en HOME directamente.

---

## 3. Mapa por carpetas

| Ruta | Responsabilidad | Riesgos | Validación relacionada |
|------|-----------------|---------|------------------------|
| `docs/` | Documentación operativa, contratos, ADRs | Inconsistencia entre docs; duplicar chuletas | `make bats-docs` |
| `ai/` | Hub IA: runtime, assets, adapters | Confundir fuente vs surface en HOME | `make validate-skills-structure`, `make ai-mcp-governance` |
| `ai/assets/skills/` | Skills globales canónicos (SSOT) | Materializar en checkout; symlinks; duplicar vault | `validate-skills-structure`, `make bats-skills` |
| `ai/assets/handoffs/` | Plantillas handoff PLAN/BUILD/AUDIT para agentes | Plantillas desactualizadas; backticks anidados al copiar | `make bats-docs` |
| `ai/assets/mcps/` | MANIFEST MCP, perfiles, taxonomía | Drift render; MCP mal clasificado | `make ai-mcp-governance`, `mcp-render-drift.bats` |
| `ai/runtime/mcp/` | Servidores MCP Python, venv, launchers fuente | Romper contrato launcher; deps runtime | `ai-mcp-governance`, `ai-runtime-uv.bats` |
| `scripts/` | Scripts shell, librerías (`lib/`) | shellcheck/shfmt drift; efectos secundarios | `make agent-validate-changed`, `make test-lint` |
| `scripts/update/` | Workflow `make update` (WSL, Node, MCPs) | Mutar sistema; shadowing Node | `update-workflow.bats`, `make update-check` |
| `scripts/hooks/` | Hooks Git versionados (treegen, GitNexus) | Permisos; post-commit bloqueante | `git-hooks/hooks.bats` |
| `tests/` | Bats, fixtures, Makefile de tests | Tests huérfanos no cableados en CI | `make test-fast`, `make test-ci` |
| `.chezmoiscripts/` | Hooks Chezmoi (before/after apply) | Mutan HOME al apply; secretos | `make test-chezmoi`, `make chezmoi-drift-report` |
| `dot_local/bin/` | Plantillas Chezmoi para binarios en HOME | Symlinks rotos post-apply | `chezmoi/smoke.bats`, bats focalizados |
| `bin/` | Wrappers repo (`dotfiles-update`, launchers, playwright) | Confundir con runtime Chezmoi en HOME | shellcheck + bats (`playwright-docker.bats`, etc.) |
| `zsh/` | Stack zsh, aliases, plugins, RC templates | RC apply no deseado; symlinks | `make test-lint`, `bats-zsh` |
| `system/packages/` | Dependencias declarativas APT/winget | Paquetes faltantes en máquina nueva | `system-deps.bats`, `make deps-check` |

---

## 4. Chezmoi y materialización

**Flujo conceptual:**

```
dot_* / dot_local/  →  chezmoi apply (humano)  →  ~/.config, ~/.local, RC files
.chezmoiscripts/    →  hooks automáticos en apply (secretos, link assets, commands)
```

- **Fuente:** plantillas en el repo (`dot_*`, `dot_local/`, paths gestionados por Chezmoi).
- **Destino:** HOME del usuario — **no editar directamente** salvo diagnóstico read-only (`chezmoi diff`, `chezmoi status`).
- **Drift:** `make chezmoi-drift-report` antes de considerar apply.

Referencia: [CHEZMOI.md](CHEZMOI.md), [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) §5–6.

---

## 5. Skills IA

| Concepto | Ubicación | Regla |
|----------|-----------|-------|
| Fuente canónica | `ai/assets/skills/` | Editar aquí |
| Surfaces (symlinks) | `~/.config/ai/skills/`, `~/.cursor/skills-cursor/`, etc. | No editar; refrescar con apply |
| Externos opt-in | `ai/assets/external-skills/` | Política y docs; no vendorizar en skills/ |
| Registro | `ai/assets/skills/README.md` | Índice y convenciones |

Hook relevante: `.chezmoiscripts/run_after_11_link_ai_assets.sh.tmpl`.

Arquitectura: [ai/SKILLS_ARCHITECTURE.md](../ai/SKILLS_ARCHITECTURE.md), ADR [0003-skills-architecture.md](adr/0003-skills-architecture.md). Índice ADRs: [adr/README.md](adr/README.md).

---

## 6. MCPs

| Concepto | Ubicación | Regla |
|----------|-----------|-------|
| SSOT definición | `ai/assets/mcps/MANIFEST.yaml` | Editar manifest + regenerar configs |
| Runtime ejecutable | `ai/runtime/mcp/` | Código servidor y deps |
| Launchers productivos | `~/.local/share/chezmoi/bin/mcp-*-launcher` | Materializados por Chezmoi |
| Render drift | `build/mcps/` (gitignored) | Comparar con `make ai-mcp-drift` |

Cadena de validación: `make ai-mcp-validate` → `make ai-mcp-render` → `make ai-mcp-drift` (agrupado en `make ai-mcp-governance`).

Taxonomía: [MCP_TAXONOMY.md](MCP_TAXONOMY.md). ADR: [0001-mcp-governance.md](adr/0001-mcp-governance.md).

---

## 7. Scripts y comandos

| Área | Contenido | Notas |
|------|-----------|-------|
| `scripts/` | Instaladores, validadores, utilidades | Preferir cambios pequeños; respetar `DRY_RUN=1` en instaladores |
| `scripts/lib/` | Librerías compartidas (gitnexus, git-flow, system_deps) | Impact analysis GitNexus antes de editar funciones |
| `bin/` | Entrypoints globales (`dotfiles-update`, MCP launchers) | Wrappers delgados; lógica en scripts/ |
| `local/bin/` | Helpers no gestionados por Chezmoi (`ai-prompt`, git-ai) | Menor superficie Chezmoi |

Commands IA: `ai/assets/commands/` — ver [COMMANDS_ARCHITECTURE.md](COMMANDS_ARCHITECTURE.md).

---

## 8. Update workflow

`make update` orquesta mantenimiento diario vía `update.mk` y `scripts/update/`.

- **No sustituye Chezmoi** — actualiza sistema, npm, imágenes Docker MCP, skills symlink refresh, etc.
- **Readiness read-only:** `make update-check` (incluido en `make ai-doctor`).
- **Agentes:** no ejecutar `make update` sin instrucción explícita.

Detalle: [UPDATE.md](UPDATE.md), skill [system-updates](../ai/assets/skills/ops/system-updates/SKILL.md).

---

## 9. Hooks y GitNexus

### Hooks Git (repo)

| Hook | Script | Efecto |
|------|--------|--------|
| pre-commit | `scripts/hooks/pre-commit-treegen.sh` | Regenera STRUCTURE.md |
| post-commit | `scripts/hooks/post-commit-gitnexus.sh` | Refresh GitNexus best-effort |

Instalación: `scripts/install-git-hooks.sh`. Tests: `git-hooks/hooks.bats`.

### GitNexus

- Índice local: `.gitnexus/` (derivado, no editar manualmente).
- Política agentes: [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md).
- Status read-only: `make gitnexus-status`.

---

## 10. Tests y validación

| Target | Cuándo usarlo |
|--------|---------------|
| `make test-fast` | Iteración rápida (sin chezmoi bats pesados) |
| `make test` | Suite completa local |
| `make test-ci` | Subconjunto alineado con CI |
| `make bats-docs` | Solo consistencia documental |
| `make agent-validate-changed` | Gate post-cambio focalizado |
| `make ai-doctor` | Readiness pre-BUILD |

Matriz detallada: [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md). Stack: [TESTING.md](TESTING.md).

---

## 11. Riesgos frecuentes

| Riesgo | Mitigación |
|--------|------------|
| `chezmoi apply` global accidental | Drift report primero; apply acotado solo con permiso |
| Skills materializados en checkout | Editar solo `ai/assets/skills/`; validar con `canonical-skills.bats` |
| MCP render drift | `make ai-mcp-governance` tras cambiar MANIFEST |
| Secretos en claro en commits | `gitleaks` en `agent-validate-changed`; SOPS para secretos |
| STRUCTURE.md desactualizado | Pre-commit treegen; no editar a mano |
| Node sombreado por Cursor/IDE | `make update-check` / `make ai-doctor` |
| `mcp-server-fetch` como uv tool persistente | Debe ser runtime-managed (uvx); ver `update-workflow.bats` |
| Editar bloques GitNexus en AGENTS.md | Bloque auto-generado — prohibido para agentes |
| Confundir dotfiles-update con Chezmoi | `dotfiles-update` → `make update`; Chezmoi es capa separada |

---

## 12. Documentos relacionados

| Documento | Contenido |
|-----------|-----------|
| [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) | Contrato operativo agentes |
| [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md) | Matriz cambio → validación |
| [STRUCTURE.md](../STRUCTURE.md) | Árbol del repositorio |
| [OPERATIONS.md](OPERATIONS.md) | Guía operativa |
| [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) | Chuleta diaria |
| [TESTING.md](TESTING.md) | Targets y política de tests |
| [CHEZMOI.md](CHEZMOI.md) | Chezmoi + SOPS |
| [ai/README.md](../ai/README.md) | Hub IA |
