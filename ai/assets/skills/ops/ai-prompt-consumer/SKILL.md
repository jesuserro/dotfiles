---
name: vault-ai-prompt-consumer
description: Use when an agent should consume canonical external prompts through ai-prompt instead of inventing or duplicating transversal instructions.
---

# Vault AI Prompt Consumer

Guía operativa para agentes que necesitan reutilizar prompts canónicos desde `dotfiles`.

## When to Use

Usa `ai-prompt` cuando:

- el usuario pide un prompt transversal ya existente
- conviene reutilizar un prompt canónico en vez de reescribir instrucciones
- necesitas componer contexto ligero alrededor de un prompt base
- un flujo frecuente ya existe como `task`

No lo uses por defecto para todo. Si el proyecto no necesita un prompt transversal, no fuerces esta herramienta.

## Guidelines

- `show`
  usa esto para obtener el prompt canónico puro
- `render`
  usa esto cuando necesitas añadir contexto explícito y controlado
- `task`
  usa esto cuando ya existe un preset pequeño y transparente para el flujo real

## Qué debe comprobar el agente

Antes de depender de `ai-prompt`, comprueba:

1. si `ai-prompt` existe en `PATH`
2. si el prompt id o task existen
3. si el contexto requerido está disponible
4. si el cwd es un repo Git válido cuando uses `--git-diff` o `--git-status`

Comandos útiles:

```bash
command -v ai-prompt
ai-prompt list
ai-prompt check
```

## Qué no debe asumir el agente

- no asumir que el fallback local del vault sea portable
- no asumir clipboard disponible
- no asumir repo Git en el cwd
- no asumir `README.md` presente
- no asumir que todo proyecto deba usar estos prompts
- no asumir que el contenido de los prompts vive en `dotfiles`

La fuente canónica sigue estando fuera del repo, en el vault externo.

## Cómo degradar con seguridad

### Si falta `ai-prompt`

- explicar que el launcher no está disponible en el entorno
- usar documentación del sistema si basta
- pedir intervención mínima sólo si el prompt canónico es realmente necesario

### Si falta un prompt o falla `check`

- no inventar el prompt silenciosamente
- informar con claridad que el catálogo o el vault no están alineados
- proponer `ai-prompt list`, `ai-prompt path <id>` o `ai-prompt check`

### Si falla el contexto Git

- no intentes descubrir el repo fuera del cwd
- informa que el comando requiere ejecutarse dentro de un repo Git válido

### Si falla el clipboard

- no asumas copia correcta
- explica que no hay backend disponible o que el backend reportó error
- si hace falta, degradar a stdout o a archivo temporal

## Examples

Obtener prompt canónico:

```bash
ai-prompt show review-diff
```

Renderizar con contexto por stdin:

```bash
git diff -- src/app.py | ai-prompt render review-diff --stdin
```

Usar un preset:

```bash
ai-prompt task write-commit-message
```

Renderizar a archivo temporal:

```bash
ai-prompt render review-diff --git-diff --git-status --output-temp --print-output-path
```

## Contrato que un agente sí puede asumir

- `AI_PROMPTS_VAULT_ROOT` es la variable pública correcta
- `list`, `show`, `path`, `check`, `render`, `task`, `help` son la superficie pública
- `show` devuelve el prompt canónico puro
- `render` compone contexto explícito
- `task` es una capa fina sobre `render`
- los errores deben ser claros y salir con código no cero

## Referencia adicional

Para arquitectura, contrato y ejemplos humanos completos:

- `docs/AI_PROMPTS_SYSTEM.md`
- `docs/PROMPT_LAUNCHERS.md`
