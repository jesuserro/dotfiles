# SOS Command

Command to prepare a high-signal handoff prompt for GPT-5.4 when the current implementation is blocked, unclear, or needs a fresh external reasoning pass.

## Purpose

When the user invokes `/sos`, the AI should produce a prompt that captures the current implementation state so it can be given to GPT-5.4 for deeper help.

The prompt should help GPT-5.4 understand:

- The architecture we want to reach
- What has already been tried
- Which files are involved
- Which tools and versions matter
- What specific problem still remains open

## Behavior

When `/sos` is invoked, the AI should:

1. Briefly infer and restate the current implementation problem
2. Gather the most relevant technical context from the workspace
3. Produce a ready-to-use prompt for GPT-5.4 in Spanish unless the surrounding conversation clearly requires another language
4. Prefer concrete repo facts over generic summaries
5. Use MCPs when useful to enrich the context with reliable implementation details

## Required Prompt Contents

The generated prompt must include, whenever the information is available:

1. **Objetivo arquitectónico**
   - Qué arquitectura o diseño se quiere implementar
   - Qué separación de capas, responsabilidades o flujos se busca

2. **Situación actual**
   - Qué funciona ya
   - Qué sigue fallando, siendo confuso o incompleto

3. **Intentos realizados**
   - Qué soluciones, refactors o enfoques se han probado
   - Qué limitaciones, regresiones o resultados tuvieron

4. **Ficheros editados o afectados**
   - Incluir una instrucción con `treegen` centrada en los ficheros relevantes
   - Si conviene, resumir también qué papel tiene cada fichero importante

5. **Versiones y tooling**
   - Versiones actuales de herramientas implicadas, frameworks, CLIs o runtimes relevantes
   - Solo incluir las que aporten contexto real al problema

6. **Uso de MCPs**
   - Si hay MCPs útiles para entender mejor el problema, reflejar los hallazgos relevantes
   - Ejemplos: estructura del repo, relaciones entre archivos, estado de servicios, docs o configuraciones

7. **Pregunta final para GPT-5.4**
   - Cerrar con una petición concreta y accionable
   - Pedir propuesta de solución, diagnóstico o siguiente iteración de refactor

## Output Requirements

The response to `/sos` should primarily be the final prompt, not a long explanation around it.

Use this structure:

```markdown
# Prompt para GPT-5.4

Estoy trabajando en [problema o refactor].

## Arquitectura objetivo
- ...

## Estado actual
- ...

## Intentos realizados
- ...

## Ficheros editados o afectados
```bash
treegen [rutas relevantes]
```

## Versiones y herramientas implicadas
- ...

## Contexto adicional obtenido
- ...

## Lo que necesito de ti
[petición concreta para GPT-5.4]
```

## Style Guidelines

- Prioritize precision over breadth
- Do not invent missing facts
- Prefer repository facts, commands, and file paths over abstract wording
- Keep the prompt compact but sufficiently complete to be useful
- If some requested context could not be gathered, say so explicitly
- Avoid filler introductions or motivational language

## MCP Guidance

Use available MCPs when they materially improve the prompt.

Examples:

- Repo/code understanding MCPs to identify affected files or flows
- Docs MCPs to confirm current tool behavior
- System or runtime MCPs to inspect versions, services, or environment details

Do not mention MCP usage unless it contributed useful context to the prompt.

## When Not to Use

Do not use this command when:

- The user only wants a direct answer to a narrow question
- No implementation/debug/refactor context exists yet
- A simple next-step answer would be more helpful than preparing an external prompt

Use `/sos` when the best help is to package the current state clearly for a stronger external reasoning pass.
