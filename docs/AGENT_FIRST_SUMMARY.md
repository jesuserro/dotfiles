# Agent-first workflow — resumen operativo

Página de entrada sintética del bloque agent-first (BUILDs 1–10). No sustituye el contrato completo; enlaza a la documentación canónica.

**Contrato detallado:** [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) · **Mapa por zona:** [AI_REPO_MAP.md](AI_REPO_MAP.md) · **Validación por cambio:** [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md)

---

## 1. Qué se construyó (BUILDs 1–10)

| BUILD | Entregable principal |
|-------|----------------------|
| 1 | Contrato `AGENT_WORKFLOW`, mapa `AI_REPO_MAP`, matriz `VALIDATION_MATRIX` |
| 2 | Plantillas handoff en `ai/assets/handoffs/`, skill `dotfiles-agent-review` |
| 3 | ADRs 0004–0010 (memoria arquitectónica agent-first) |
| 4 | Gate `make agent-validate` + extensión `agent-validate-changed` |
| 5 | Reporte `make agent-validate-report` → `build/agent-validation/latest.md` |
| 6 | Limpieza skills canónicas (sin `.claude/` en checkout, ADR 0004) |
| 7 | Wrapper seguro `dotfiles-apply` (preview por defecto) |
| 8 | Convención `--check` / `--dry-run` / `DRY_RUN=1` → [SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md) |
| 9 | Índice regresión `make bats-agent` → [tests/bats/agent/README.md](../tests/bats/agent/README.md) |
| 10 | Cableado tests huérfanos en `bats-system`, guard `.claude/` en `agent-validate` |

---

## 2. Mapa de comandos

### Validación (agentes — read-only por defecto)

| Comando | Cuándo |
|---------|--------|
| `make agent-validate-changed` | Tras cambios pequeños / focalizados |
| `make agent-validate` | Gate completo al cerrar un BUILD |
| `make agent-validate-report` | Informe Markdown para handoff (`build/agent-validation/latest.md`) |
| `make agent-validate-audit` | Auditoría estricta full-repo (humano / pre-release) |
| `make agent-validate-full` | `agent-validate` + `agent-validate-audit` |
| `make bats-agent` | Índice de regresión histórica (meta-tests) |
| `make bats-docs` | Contrato documental |
| `make bats-skills` | Skills canónicas + estructura |
| `make ai-mcp-governance` | MANIFEST MCP + render + drift |
| `make ai-doctor` | Readiness pre-implementación |

### Chezmoi seguro

| Comando | Efecto |
|---------|--------|
| `dotfiles-apply` | Preview: `diff` + `status` (no aplica) |
| `dotfiles-apply --check` | Igual que default |
| `dotfiles-apply --apply` | Apply con confirmación `APPLY` |
| `dotfiles-apply --apply --yes` | Apply no interactivo — **solo humano/CI explícito** |

Detalle: [CHEZMOI.md](CHEZMOI.md) · Convenciones: [SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md)

### Mantenimiento (humano — fuera del gate agent-first)

| Comando | Nota |
|---------|------|
| `dotfiles-update` / `make update` | Mantenimiento sistema; **no** para agentes sin instrucción |
| `chezmoi apply` directo | Solo humano consciente; preferir `dotfiles-apply` |

No usar `ups` — retirado (ADR 0010); usar `dotfiles-update`.

---

## 3. Checklist operativa

### Antes de un BUILD

- [ ] Leer [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) (modo PLAN/BUILD/AUDIT)
- [ ] Copiar plantilla de [ai/assets/handoffs/](../ai/assets/handoffs/)
- [ ] Identificar zona en [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md)
- [ ] Confirmar alcance y fuera de alcance en el handoff

### Después de un BUILD

- [ ] `make agent-validate-changed`
- [ ] `make agent-validate`
- [ ] `make agent-validate-report`
- [ ] Revisar `build/agent-validation/latest.md`
- [ ] Si tocaste Chezmoi: `dotfiles-apply --check` (no `--apply --yes` sin instrucción humana)
- [ ] Entregar informe según [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) §11

### Si aparece `.claude/` en el checkout

Materialización runtime prohibida ([ADR 0004](adr/0004-ai-assets-not-materialized.md)).

```bash
rm -rf .claude/
make bats-skills
make agent-validate
```

Fuente canónica de skills: `ai/assets/skills/` (no copiar a `.claude/` dentro del repo).

---

## 4. Documentación canónica

| Tema | Documento |
|------|-----------|
| Contrato agentes | [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) |
| Mapa operativo | [AI_REPO_MAP.md](AI_REPO_MAP.md) |
| Matriz validación | [VALIDATION_MATRIX.md](VALIDATION_MATRIX.md) |
| Handoffs | [ai/assets/handoffs/README.md](../ai/assets/handoffs/README.md) |
| Revisión post-cambio | [dotfiles-agent-review](../ai/assets/skills/ops/dotfiles-agent-review/SKILL.md) |
| ADRs | [adr/README.md](adr/README.md) |
| Tests y targets | [TESTING.md](TESTING.md) |
| Chuleta diaria | [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) |
| Flags scripts | [SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md) |
| Regresión histórica | [tests/bats/agent/README.md](../tests/bats/agent/README.md) |

---

## 5. Fuera de este bloque agent-first

No forman parte del cierre BUILDs 1–10; tienen handoffs o ADRs pointer aparte:

- **git-flow PR** — ADR 0008 (pointer)
- Bootstrap máquina nueva — [INSTALL.md](INSTALL.md)
- Loop vault → spec → issues — [ai/AGENT_WORKFLOW_FOR_AGENTS.md](../ai/AGENT_WORKFLOW_FOR_AGENTS.md)

**Cerrado (BUILD A):** `dotfiles-update` / retirada de `ups` — ADR [0009](adr/0009-dotfiles-update-wrapper.md), [0010](adr/0010-ups-removal.md). Contrato: `make update` (interno) + `dotfiles-update` (global).

---

## 6. Estado del bloque

El bloque agent-first queda **cerrado** con BUILD 11: contrato, validación, reporte, Chezmoi seguro, convenciones, regresión y guard `.claude/` documentados y testeados. Mejora futura pendiente: **git-flow PR** (ADR 0008, handoff separado).
