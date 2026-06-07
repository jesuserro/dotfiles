# Agent Workflow — contrato operativo para agentes IA

## 1. Propósito

Este documento es el **punto de entrada canónico** para agentes IA (Cursor, Codex, ChatGPT, OpenCode) que trabajan **en este repositorio dotfiles**.

Define cómo actuar, qué evitar y cómo validar cambios. No sustituye la guía de loop vault→proyecto ([AGENT_WORKFLOW_LOOP.md](AGENT_WORKFLOW_LOOP.md) y [ai/AGENT_WORKFLOW_FOR_AGENTS.md](../ai/AGENT_WORKFLOW_FOR_AGENTS.md)); aquí el foco es **operar y modificar dotfiles** de forma segura.

Para el mapa de zonas del repo, ver [AI_REPO_MAP.md](AI_REPO_MAP.md). Para qué validar según archivos tocados, ver [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md). Para flags `--check`, `--dry-run`, `DRY_RUN=1` y `--yes`, ver [SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md).

---

## 2. Modos PLAN, BUILD y AUDIT

| Modo | Qué hace | Qué no hace |
|------|----------|-------------|
| **PLAN** | Diagnosticar, explorar, proponer arquitectura y orden de trabajo | Modificar archivos salvo lectura estrictamente necesaria |
| **BUILD** | Implementar un alcance acotado y acordado | Ampliar alcance sin confirmación; cambios funcionales fuera del handoff |
| **AUDIT** | Revisar cambios o estado del repo sin mutar | Editar código, aplicar Chezmoi ni ejecutar instaladores |

Cada handoff debe declarar el modo. Si no está claro, asumir **PLAN** hasta que el usuario pida BUILD.

---

## 3. Principios de trabajo

- **Cambios pequeños y testeables** — un BUILD acotado por objetivo.
- **No destructivo por defecto** — preferir validación read-only antes de mutar HOME o sistema; usar `--check` o `DRY_RUN=1` según [SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md).
- **Referencias, no duplicación** — enlazar docs canónicos existentes en lugar de copiar bloques largos.
- **Respetar contratos del repo** — Chezmoi, taxonomía MCP, skills canónicas, hooks Git, [STRUCTURE.md](../STRUCTURE.md) y ADRs en [docs/adr/](adr/README.md).
- **Secretos** — nunca commitear credenciales en claro; ver [CHEZMOI.md](CHEZMOI.md) y [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md).
- **GitNexus** — seguir [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md); no auto-refrescar el índice.

### Prohibido sin instrucción explícita del usuario

- `chezmoi apply` (global o acotado que muta HOME); usar `dotfiles-apply` / `--check` para preview
- `make update` / `dotfiles-update` (mantenimiento integral del sistema)
- `--yes` en wrappers mutantes (`dotfiles-apply --apply --yes`, etc.)
- Instalar paquetes (`apt`, `winget`, `npm install -g`, etc.) salvo `DRY_RUN=1` preview
- Modificar bloques `<!-- gitnexus:* -->` en `AGENTS.md` / `CLAUDE.md`
- Ejecutar `gnx-analyze-here` o refresh GitNexus por índice stale

Detalle operativo diario: [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) §11.

---

## 4. Rutas habituales y rutas sensibles

### Rutas habituales (edición frecuente por agentes)

| Zona | Uso típico |
|------|------------|
| `docs/` | Documentación operativa y contratos |
| `ai/assets/skills/` | Skills globales canónicos |
| `ai/assets/mcps/` | MANIFEST y definición MCP |
| `scripts/` | Scripts shell y librerías |
| `tests/bats/` | Tests de regresión |
| `Makefile`, `*.mk` | Targets de validación e instalación |

### Rutas sensibles (extra cuidado o permiso explícito)

| Zona | Riesgo |
|------|--------|
| `secrets.sops.yaml`, `*.sops.yaml` | Secretos cifrados — no exponer en claro |
| `AGENTS.md`, `CLAUDE.md` (bloque GitNexus) | Auto-generado — no editar manualmente |
| `.chezmoiscripts/` | Hooks Chezmoi que mutan HOME al apply |
| `dot_*`, `dot_local/` | Plantillas Chezmoi — impacto en materialización |
| `ai/runtime/mcp/` | Runtimes MCP ejecutables |
| `system/packages/` | Dependencias declarativas del sistema |
| `.gitnexus/` | Índice GitNexus derivado |

Mapa completo con validación por zona: [AI_REPO_MAP.md](AI_REPO_MAP.md).

---

## 5. Chezmoi

Dotfiles usa Chezmoi para materializar configuración en HOME. Reglas para agentes:

1. **Drift primero** — tras cambios en plantillas, revisar con `dotfiles-apply`, `dotfiles-apply --check` o `make chezmoi-drift-report` (read-only).
2. **No apply global** — el flujo normal no es `chezmoi apply` sin paths. Ver [CHEZMOI.md](CHEZMOI.md) y [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) §5–6.
3. **Apply acotado** — solo con petición explícita de mutar HOME; preferir `dotfiles-apply --apply` con paths concretos documentados en la chuleta.
4. **No ocultar cambios** — `dotfiles-apply` muestra diff/status antes de cualquier apply autorizado.
5. **Agentes** — usar solo `dotfiles-apply` o `dotfiles-apply --check`; no `--apply --yes` salvo instrucción humana explícita.

Los agentes editan **plantillas en el repo** (`dot_*`, `dot_local/`, etc.), no surfaces en HOME directamente.

---

## 6. Skills y MCPs

### Skills

- **Fuente canónica:** `ai/assets/skills/` — editar aquí, no en `~/.cursor/skills-cursor/` ni `.claude/skills/` del repo.
- **No materializar** skills dentro del checkout (sin symlinks ni copias en rutas locales del repo). Si aparece `.claude/` en el checkout: `rm -rf .claude/` (ADR 0004); `make agent-validate` falla con hint de remediación.
- **Validar estructura:** `make validate-skills-structure` o `./scripts/validate-skills-structure.sh`.
- **Registrar skills nuevos:** skill [dotfiles-skill-registration](../ai/assets/skills/ops/dotfiles-skill-registration/SKILL.md).

### MCPs

- **SSOT:** `ai/assets/mcps/MANIFEST.yaml` — taxonomía en [MCP_TAXONOMY.md](MCP_TAXONOMY.md).
- **No editar** `~/.cursor/mcp.json` a mano si proviene de Chezmoi.
- **Validar governance:** `make ai-mcp-governance` (read-only).
- **Runtime productivo:** launchers bajo `~/.local/share/chezmoi/bin/mcp-*-launcher`, no paths arbitrarios en `~/dotfiles/bin/` para configs de agente.

Guía práctica: [GUIA_MCP_AI.md](GUIA_MCP_AI.md), [MCP_QUICKREF.md](MCP_QUICKREF.md).

---

## 7. GitNexus

Este repo está indexado por GitNexus. Los agentes deben:

- Usar herramientas MCP GitNexus en modo read-only (`gitnexus_query`, `gitnexus_context`, `gitnexus_impact`, etc.).
- Ejecutar `gitnexus_impact` antes de editar funciones o métodos significativos.
- Consultar `make gitnexus-status` si hay aviso de índice stale — **no** auto-refrescar.
- Respetar locks y política post-commit documentada en [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md).

Skills: `ai/assets/skills/gitnexus/`.

---

## 8. STRUCTURE.md

[STRUCTURE.md](../STRUCTURE.md) es el inventario estructural del repo, generado por `scripts/treegen.sh`.

- **No editar a mano** — se regenera vía pre-commit hook (`scripts/hooks/pre-commit-treegen.sh`).
- **Comprobar drift sin escribir** — `scripts/treegen.sh --check .` (exit 0 si está al día).
- Si añades carpetas o archivos visibles, el hook actualiza y stagea STRUCTURE.md automáticamente.
- Para **intención y contratos por zona**, usar [AI_REPO_MAP.md](AI_REPO_MAP.md), no STRUCTURE.md.

---

## 9. Validación

Tras un BUILD, validar según la zona modificada ([VALIDATION_MATRIX.md](VALIDATION_MATRIX.md)).

| Momento | Comando recomendado |
|---------|---------------------|
| Pre-implementación (readiness) | `make ai-doctor` |
| Post-BUILD (gate dotfiles) | `make agent-validate` |
| Post-cambio focalizado | `make agent-validate-changed` |
| Auditoría full-repo estricta | `make agent-validate-audit` |
| Pre-merge / release fuerte | `make agent-validate-full` |
| Reporte para handoff/PR | `make agent-validate-report` → `build/agent-validation/latest.md` |
| Índice regresión histórica | `make bats-agent` → `tests/bats/agent/regression.bats` |
| Área Chezmoi | `make test-chezmoi` |
| Área MCP | `make ai-mcp-governance` |
| Solo docs | `make bats-docs` |

Detalle de targets y política OSV: [TESTING.md](TESTING.md).

Los agentes deben ejecutar **`make agent-validate-changed`** tras cambios pequeños, o **`make agent-validate`** para el gate dotfiles completo al cerrar un BUILD. **`make agent-validate-report`** genera un informe Markdown persistente (incluso si la validación falla); no sustituye corregir los fallos. Ninguno ejecuta `chezmoi apply`, `make update` ni instalaciones.

---

## 10. Handoffs

Plantillas versionadas en [ai/assets/handoffs/](../ai/assets/handoffs/) — copiar en el chat y rellenar placeholders.

| Plantilla | Modo | Uso |
|-----------|------|-----|
| `cursor-plan.md` | PLAN | Diagnóstico sin implementar |
| `cursor-build.md` | BUILD | Implementación acotada |
| `cursor-audit.md` | AUDIT | Revisión read-only |
| `codex-build.md` | BUILD | Implementación explícita (Codex) |
| `chatgpt-review.md` | REVIEW | Revisión externa con material aportado |

Índice y convenciones: [ai/assets/handoffs/README.md](../ai/assets/handoffs/README.md).

Cada handoff debe declarar modo, alcance, fuera de alcance, validación y criterios de aceptación. Para loop vault→proyecto, ver también [ai/AGENT_WORKFLOW_FOR_AGENTS.md](../ai/AGENT_WORKFLOW_FOR_AGENTS.md) §9.

### Revisión post-cambio

Para auditar un BUILD o diff en dotfiles, usar la skill [Dotfiles Agent Review](../ai/assets/skills/ops/dotfiles-agent-review/SKILL.md) (`dotfiles-agent-review`). Es read-only por defecto; no sustituye `make agent-validate-changed`.

---

## 11. Formato esperado de informe

Al terminar PLAN, BUILD o AUDIT, el agente debe entregar un informe con:

1. **Veredicto** — implemented / partially implemented / blocked (BUILD) o viable / viable con riesgos / no viable (PLAN)
2. **Cambios realizados** — archivos creados o modificados
3. **Decisiones tomadas** — breve justificación de diseño
4. **Validaciones ejecutadas** — comandos y resultado (pass/fail)
5. **Riesgos o pendientes** — solo técnicos, para el siguiente paso
6. **Siguiente paso recomendado** — BUILD o handoff concreto

Separar claramente lo **implementado**, lo **validado** y lo **pendiente**.

---

## 12. Documentos relacionados

| Documento | Contenido |
|-----------|-----------|
| [AI_REPO_MAP.md](AI_REPO_MAP.md) | Mapa operativo por zona |
| [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md) | Cambio → validación |
| [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) | Chuleta diaria y política agentes |
| [OPERATIONS.md](OPERATIONS.md) | Guía operativa principal |
| [TESTING.md](TESTING.md) | Stack de tests y targets Make |
| [CHEZMOI.md](CHEZMOI.md) | Referencia Chezmoi + SOPS |
| [GITNEXUS_OPERATIONAL_POLICY.md](GITNEXUS_OPERATIONAL_POLICY.md) | Política GitNexus |
| [MCP_TAXONOMY.md](MCP_TAXONOMY.md) | Taxonomía MCP |
| [adr/README.md](adr/README.md) | Memoria arquitectónica (decisiones ADR) |
| [STRUCTURE.md](../STRUCTURE.md) | Árbol del repositorio |
| [ai/AGENT_WORKFLOW_FOR_AGENTS.md](../ai/AGENT_WORKFLOW_FOR_AGENTS.md) | Loop vault → spec → issues |
| [ai/assets/handoffs/README.md](../ai/assets/handoffs/README.md) | Plantillas handoff PLAN/BUILD/AUDIT |
| [dotfiles-agent-review](../ai/assets/skills/ops/dotfiles-agent-review/SKILL.md) | Skill revisión post-cambio |
| [AGENT_WORKFLOW_LOOP.md](AGENT_WORKFLOW_LOOP.md) | Tutorial humano del loop |
