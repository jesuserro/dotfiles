# HANDOFF — Cursor BUILD

version: 1.0
agent: Cursor
mode: BUILD

---

## 1. Modo de trabajo

Modo requerido: **BUILD**

Implementa solo el alcance cerrado de este handoff.

No amplies alcance sin justificar en el informe final.

---

## 2. Contexto

[Resumen del PLAN aprobado o del objetivo concreto.]

Repo: [dotfiles / ruta]

Documentos de referencia:

- docs/AGENT_WORKFLOW.md
- docs/VALIDATION_MATRIX.md

---

## 3. Objetivo

[Qué debe existir al terminar este BUILD — una frase clara.]

---

## 4. Alcance permitido

[Lista explícita de archivos, carpetas o tipos de cambio permitidos.]

Ejemplo de formato:

- Crear: [rutas]
- Modificar: [rutas]
- Tests: [rutas bats o extensión de tests existentes]

---

## 5. Fuera de alcance

[Lista explícita de lo que NO debe tocarse en este BUILD.]

Incluir por defecto si no se indica lo contrario:

- No modificar Makefile ni targets Make no listados.
- No ejecutar chezmoi apply ni make update.
- No instalar paquetes.
- No tocar secretos en claro.

---

## 6. Instrucciones de validación

Al cerrar el BUILD, ejecutar según la zona modificada (ver docs/VALIDATION_MATRIX.md).

Mínimo habitual en dotfiles:

    make agent-validate-changed

Si solo docs:

    make bats-docs

Si skills:

    ./scripts/validate-skills-structure.sh

Comandos adicionales si aplica:

- [make test-fast / make bats-skills / make ai-mcp-governance / otro]

---

## 7. Formato de informe esperado

1. Veredicto (implemented / partially implemented / blocked)
2. Cambios realizados (archivos creados y modificados)
3. Decisiones tomadas
4. Validaciones ejecutadas (comando + resultado)
5. Riesgos o pendientes (solo técnicos)
6. Siguiente BUILD recomendado

Separar lo implementado, lo validado y lo pendiente.

---

## 8. Criterios de aceptación

- [ ] [Criterio verificable 1]
- [ ] [Criterio verificable 2]
- [ ] Validaciones ejecutadas y reportadas.
- [ ] Sin cambios fuera de alcance.
- [ ] Sin secretos ni apply no autorizado.
