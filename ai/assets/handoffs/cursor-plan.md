# HANDOFF — Cursor PLAN

version: 1.0
agent: Cursor
mode: PLAN

---

## 1. Modo de trabajo

Modo requerido: **PLAN**

No implementes cambios en archivos salvo lectura estrictamente necesaria para diagnosticar.

Este pase debe producir un informe de planificación, no código ni commits.

---

## 2. Contexto

[Describe el problema, el historial relevante y qué ya se intentó.]

Repo o área principal: [dotfiles / ruta concreta / proyecto]

Referencias canónicas si aplica:

- docs/AGENT_WORKFLOW.md
- docs/AI_REPO_MAP.md
- docs/VALIDATION_MATRIX.md

---

## 3. Objetivo

[Qué debe quedar resuelto al final del PLAN: decisión, arquitectura, orden de trabajo.]

---

## 4. Alcance permitido

- Leer workspace real (archivos, tests, docs existentes).
- Detectar solapamientos con documentación y scripts actuales.
- Proponer implementación incremental por fases.
- Identificar riesgos técnicos y decisiones pendientes.

---

## 5. Fuera de alcance

- No modificar archivos del repo.
- No ejecutar chezmoi apply ni make update.
- No instalar paquetes.
- No ampliar alcance más allá del objetivo declarado.
- No gastar tokens en recomendaciones de Git salvo que afecten técnicamente al diseño.

---

## 6. Instrucciones de validación

En modo PLAN no se exigen tests de implementación.

Si propones targets o scripts futuros, indica qué validación existente del repo aplicaría (consultar docs/TESTING.md y docs/VALIDATION_MATRIX.md).

---

## 7. Formato de informe esperado

Entrega un informe Markdown con estas secciones:

1. Veredicto de viabilidad (viable / viable con riesgos / no viable)
2. Mapa actual del workspace (hallazgos con rutas)
3. Solapamientos detectados
4. Propuesta de arquitectura objetivo
5. Roadmap secuencial de implementación
6. Diseño detallado por mejora o fase
7. Archivos candidatos a crear/modificar
8. Tests recomendados
9. Riesgos y decisiones pendientes
10. Propuesta de primer BUILD seguro

---

## 8. Criterios de aceptación

- [ ] El informe se basa en el workspace real, sin inventar rutas inexistentes.
- [ ] Propone orden incremental (docs → targets → scripts → fixtures).
- [ ] Separa claramente PLAN de BUILD futuro.
- [ ] No incluye implementación ni cambios funcionales.
- [ ] Identifica solapamientos con docs y validadores existentes.
