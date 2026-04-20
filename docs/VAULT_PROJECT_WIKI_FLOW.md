# Vault Project Wiki Flow

Flujo operativo transversal para que un agente decida si un cambio importante debe dejar una nota útil en `vault_trabajo`.

## Propósito

- conservar conocimiento reutilizable después de implementaciones relevantes
- mantener separadas la fuente de verdad del repo y la wiki acumulativa del proyecto
- dar a los agentes un criterio simple para capturar conocimiento sin automatismos complejos

## Separación canónica

- repo del proyecto: fuente de verdad de implementación, código, scripts y documentación canónica
- `vault_trabajo`: wiki destilada en `projects/<project>/knowledge/...`
- `dotfiles`: capa operativa transversal para agentes, skills, prompts y convenciones

## Cuándo registrar una nota

Registra o actualiza una nota cuando el cambio deja aprendizaje reutilizable:

- una implementación relevante con restricciones o comportamiento no obvio
- una decisión con tradeoffs que conviene recordar
- un patrón que puede repetirse en el proyecto
- un incidente con causa, mitigación y lección útil

No registres:

- cambios menores o mecánicos
- release notes o changelog
- duplicados de documentación que ya vive mejor en el repo
- notas temporales sin valor acumulativo

## Ubicación

Ruta base:

```text
vault_trabajo/projects/<project>/knowledge/
```

Subcarpetas:

- `implementation-notes/`
- `decisions/`
- `patterns/`
- `incidents/`

Tipos de nota:

- `implementation-note`
- `decision-note`
- `pattern-note`
- `incident-note`

Status permitidos:

- `draft`
- `stable`
- `superseded`

## Frontmatter mínimo

```yaml
---
project: store-etl
type: implementation-note
status: stable
date: 2026-04-13
topics:
  - camino-a
  - hydration
source_of_truth:
  - repo-docs
---
```

La dimensión temporal va en frontmatter. `timeline/` no es el hogar principal de la wiki técnica.

## Criterio de escritura

- destilar conocimiento, no copiar el repo
- escribir notas breves y enlazadas
- actualizar una nota existente si el tema ya está cubierto
- enlazar a repo docs, PR o ADR cuando ahí esté la fuente de verdad

Ejemplo de ruta:

```text
vault_trabajo/projects/store-etl/knowledge/implementation-notes/camino-a-hydration-gate-by-batch.md
```

Referencia operativa para agentes: `ai/assets/skills/ops/vault-project-wiki/SKILL.md`.
