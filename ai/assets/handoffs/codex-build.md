# HANDOFF — Codex BUILD

version: 1.0
agent: Codex
mode: BUILD

---

## 1. Modo de trabajo

Modo requerido: **BUILD**

Implementación acotada. Codex puede tener menos contexto IDE: sé explícito en rutas y comandos.

---

## 2. Contexto

Repo raíz: [ruta absoluta o ~/dotfiles]

BUILD anterior aprobado: [referencia breve o N/A]

Leer antes de editar:

- docs/AGENT_WORKFLOW.md
- docs/VALIDATION_MATRIX.md

---

## 3. Objetivo

[Resultado concreto al terminar — archivos que deben existir o comportamiento esperado.]

---

## 4. Alcance permitido

Archivos que puedes crear:

- [lista exacta de rutas]

Archivos que puedes modificar:

- [lista exacta de rutas]

Tests que puedes crear o extender:

- [lista exacta de rutas .bats]

---

## 5. Fuera de alcance

No tocar:

- [lista explícita]
- Makefile, install.mk, update.mk (salvo que este handoff lo autorice)
- scripts/agent-validate-changed.sh
- secretos, chezmoi apply, make update

---

## 6. Instrucciones de validación

Desde la raíz del repo, ejecutar en este orden:

    cd [DOTFILES_DIR]
    make agent-validate-changed

Comandos adicionales según zona (ver docs/VALIDATION_MATRIX.md):

- Docs: make bats-docs
- Skills: ./scripts/validate-skills-structure.sh
- Shell: make test-lint

Reportar salida resumida (pass/fail) de cada comando.

---

## 7. Formato de informe esperado

1. Veredicto (implemented / partially implemented / blocked)
2. Lista de archivos tocados (created / modified)
3. Resumen del diff por archivo (1-2 líneas cada uno)
4. Comandos ejecutados y resultado
5. Pendientes o bloqueos
6. Siguiente paso sugerido

---

## 8. Criterios de aceptación

- [ ] Solo archivos del alcance permitido fueron modificados.
- [ ] [Criterio específico 1]
- [ ] [Criterio específico 2]
- [ ] make agent-validate-changed pasa (o fallo explicado si preexistente).
- [ ] Sin cambios fuera de alcance documentados.
