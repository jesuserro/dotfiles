# Handoff templates — plantillas versionadas para agentes

## Propósito

Este directorio contiene plantillas **copiables en chats** para pedir trabajo a agentes IA sobre el repo dotfiles o proyectos relacionados.

Contrato operativo del repo: [docs/AGENT_WORKFLOW.md](../../docs/AGENT_WORKFLOW.md).

## Convenciones de modo

| Modo | Significado |
|------|-------------|
| **PLAN** | Diagnosticar y proponer sin modificar archivos |
| **BUILD** | Implementar un alcance acotado |
| **AUDIT** | Revisar sin cambios funcionales |
| **REVIEW** | Revisión externa o dirección arquitectónica (sin asumir estado del workspace) |

## Cuándo usar cada plantilla

| Plantilla | Agente | Modo | Uso |
|-----------|--------|------|-----|
| [cursor-plan.md](cursor-plan.md) | Cursor | PLAN | Diagnóstico, arquitectura, roadmap sin implementar |
| [cursor-build.md](cursor-build.md) | Cursor | BUILD | Implementación acotada con criterios de aceptación |
| [cursor-audit.md](cursor-audit.md) | Cursor | AUDIT | Revisión read-only de cambios o estado del repo |
| [codex-build.md](codex-build.md) | Codex | BUILD | Implementación con comandos y archivos explícitos |
| [chatgpt-review.md](chatgpt-review.md) | ChatGPT | REVIEW | Revisión externa con material aportado por el humano |

## Cómo usar

1. Copia la plantilla completa en el chat del agente.
2. Rellena las secciones entre corchetes o marcadores de placeholder.
3. Declara el modo (PLAN / BUILD / AUDIT / REVIEW) en la primera línea si no está claro.
4. Al cerrar, exige el formato de informe indicado en la plantilla.

## Nota sobre formato

Las plantillas **no usan bloques de código con triple backtick** para evitar problemas al copiar/pegar en chats. Los comandos van en listas indentadas o líneas simples.

Versión del set de plantillas: **1.0** (agent-first BUILD 2).
