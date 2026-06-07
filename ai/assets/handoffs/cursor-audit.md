# HANDOFF — Cursor AUDIT

version: 1.0
agent: Cursor
mode: AUDIT

---

## 1. Modo de trabajo

Modo requerido: **AUDIT**

Revisión read-only. No modifiques archivos del repo.

Para revisión estructurada en dotfiles, puedes combinar con la skill Dotfiles Agent Review (ai/assets/skills/ops/dotfiles-agent-review/).

---

## 2. Contexto

[Qué se revisa: diff, rama, conjunto de archivos, área del repo.]

Punto de partida:

- Commit o rango: [SHA / branch / working tree]
- Objetivo de la revisión: [pre-merge / post-BUILD / deuda técnica]

---

## 3. Objetivo

[Qué preguntas debe responder la auditoría.]

---

## 4. Alcance permitido

- Leer archivos, tests, docs y diff.
- Ejecutar validadores read-only (make ai-doctor, make bats-docs, grep, etc.).
- Clasificar hallazgos por severidad.
- Proponer mejoras sin aplicarlas.

---

## 5. Fuera de alcance

- No editar código ni documentación.
- No ejecutar chezmoi apply, make update ni instaladores.
- No commitear ni modificar Git.
- No asumir estado no verificado del workspace.

---

## 6. Instrucciones de validación

Ejecutar solo lectura según el área auditada:

    make agent-validate-changed   # si hay cambios locales
    make bats-docs                # si hay cambios en docs
    make ai-mcp-governance        # si el diff toca MCPs

Reportar pass/fail de cada comando ejecutado.

---

## 7. Formato de informe esperado

1. Veredicto (pass / pass with warnings / fail)
2. Resumen ejecutivo
3. Riesgos críticos
4. Riesgos medios
5. Observaciones menores
6. Validaciones ejecutadas
7. Mejoras propuestas (sin implementar)
8. Siguiente acción recomendada

---

## 8. Criterios de aceptación

- [ ] Revisión read-only confirmada (sin edits).
- [ ] Hallazgos clasificados en crítico / medio / menor.
- [ ] Inconsistencias con docs/AGENT_WORKFLOW.md o VALIDATION_MATRIX señaladas.
- [ ] Riesgos Chezmoi, secretos, MCPs y skills evaluados si aplican.
- [ ] Propuestas separadas de la implementación.
