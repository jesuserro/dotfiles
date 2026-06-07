# HANDOFF — ChatGPT REVIEW

version: 1.0
agent: ChatGPT
mode: REVIEW

---

## 1. Modo de trabajo

Modo requerido: **REVIEW**

Revisión externa o dirección arquitectónica. No asumas estado del workspace si no se aportan evidencias.

---

## 2. Contexto

[Descripción del sistema, restricciones y por qué se pide revisión externa.]

Material aportado por el humano (obligatorio pegar o adjuntar):

- [diff, PLAN, spec, extractos de código, diagrama]
- [docs relevantes]

Si falta evidencia, indícalo y pide lo necesario en lugar de inventar.

---

## 3. Objetivo

[Qué debe aportar esta revisión: riesgos, alternativas, preguntas abiertas, validación de diseño.]

---

## 4. Alcance permitido

- Analizar solo el material aportado.
- Responder preguntas explícitas listadas abajo.
- Proponer mejoras conceptuales.
- Señalar ambigüedades y supuestos no verificados.

---

## 5. Fuera de alcance

- No afirmar qué archivos existen en el repo sin evidencia.
- No proponer comandos destructivos (apply global, force push, etc.).
- No sustituir una auditoría local del workspace (usar cursor-audit para eso).

---

## 6. Instrucciones de validación

Esta revisión no ejecuta validadores del repo.

Si recomiendas validación, cita targets genéricos de dotfiles solo como sugerencia al humano:

- make agent-validate-changed
- make bats-docs
- docs/VALIDATION_MATRIX.md

---

## 7. Formato de informe esperado

1. Resumen (3-5 líneas)
2. Respuestas a las preguntas planteadas (numeradas)
3. Riesgos críticos
4. Riesgos medios
5. Observaciones menores
6. Alternativas consideradas
7. Preguntas abiertas para el humano
8. Recomendación final (aprobar diseño / replantear / dividir en fases)

---

## 8. Criterios de aceptación

- [ ] No inventa estado del repo sin evidencia aportada.
- [ ] Responde todas las preguntas listadas en § Preguntas.
- [ ] Separa hechos (del material) de opiniones (recomendaciones).
- [ ] Hallazgos clasificados por severidad.

---

## Preguntas a responder

1. [Pregunta 1]
2. [Pregunta 2]
3. [Pregunta 3]
