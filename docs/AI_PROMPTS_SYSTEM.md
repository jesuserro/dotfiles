# AI Prompt System

Sistema para consumir prompts canónicos externos desde terminal y desde agentes, sin duplicar su contenido dentro de `dotfiles`.

## Propósito

`ai-prompt` resuelve un problema concreto: reutilizar prompts transversales de trabajo diario desde una CLI pequeña y estable, manteniendo el texto canónico fuera del repo.

La separación buscada es esta:

- vault externo: fuente canónica de prompts
- `dotfiles`: capa de lanzamiento, composición y ergonomía
- humano o agente: consumidor del prompt

Esto evita duplicar prompts en varios repos, reduce deriva entre versiones y permite mejorar la ergonomía sin tocar el contenido canónico.

## Arquitectura

```text
vault_trabajo/
  agents/prompts/*.md        <- prompts canónicos

dotfiles/
  scripts/lib/prompt-vault-common.sh
  local/bin/ai-prompt        <- CLI principal
  local/bin/prompt-*         <- compatibilidad heredada

salidas:
  stdout                     <- por defecto
  archivo fijo               <- --output-file
  archivo temporal           <- --output-temp
  clipboard opcional         <- --copy
```

Resumen funcional:

- el vault contiene el markdown canónico
- `ai-prompt` localiza ese markdown, lo valida y lo entrega
- `render` compone contexto ligero sin modificar el prompt fuente
- `task` aplica presets pequeños sobre `render`

## Contrato público estable

### Variable pública

- `AI_PROMPTS_VAULT_ROOT`

Si existe, tiene prioridad absoluta para resolver el vault.

### CLI pública

```text
ai-prompt list
ai-prompt show <prompt-id>
ai-prompt path <prompt-id>
ai-prompt check
ai-prompt render <prompt-id> [extras]
ai-prompt task <task-name> [extras]
ai-prompt help
```

### Compatibilidad heredada

Se mantienen estos launchers:

- `prompt-understand-context`
- `prompt-plan-safe-change`
- `prompt-detect-errors`

### Qué es estable

- `AI_PROMPTS_VAULT_ROOT`
- `ai-prompt` como entrada principal
- `show` como salida pura del prompt canónico
- `render` como composición ligera
- `task` como preset fino sobre `render`
- salida por `stdout` salvo que el usuario pida archivo
- errores útiles con `exit != 0`

### Qué es local o provisional

- `DEFAULT_AI_PROMPTS_VAULT_ROOT` es un fallback técnico de esta máquina, no un contrato portable
- el clipboard es por mejor esfuerzo y depende de backends disponibles
- los launchers `prompt-*` son compatibilidad, no la superficie principal recomendada

## Resolución del vault

La resolución vive en un único helper:

1. usar `AI_PROMPTS_VAULT_ROOT` si está definida
2. si no, usar `DEFAULT_AI_PROMPTS_VAULT_ROOT` como fallback local/provisional

La convención interna actual queda encapsulada y no debe asumirse fuera del helper:

```text
<vault-root>/agents/prompts/<prompt-id>.md
```

## Catálogo actual

### Prompt ids

- `understand-context`
- `plan-safe-change`
- `detect-errors`
- `summarize-repo`
- `review-diff`
- `write-commit-message`
- `design-test-cases`

### Tasks

- `review-diff`
  usa el prompt `review-diff` con `--git-diff --git-status`
- `write-commit-message`
  usa el prompt `write-commit-message` con `--git-diff --git-status`
- `summarize-repo`
  usa `summarize-repo` y añade `README.md` del cwd si existe y es legible

## Cuándo usar cada comando

### `list`

Para descubrir el catálogo soportado de forma simple y parseable.

### `show`

Para obtener el prompt canónico puro, sin composición extra.

### `path`

Para depurar la ruta exacta del markdown resuelto.

### `check`

Para validar rápidamente si el catálogo declarado sigue apuntando a archivos reales del vault.

### `render`

Para generar un prompt final compuesto con contexto explícito.

Soporta:

- `--context-file <path>`
- `--stdin`
- `--git-diff`
- `--git-status`
- `--output-file <path>`
- `--output-temp`
- `--print-output-path`
- `--copy`

### `task`

Para flujos frecuentes con poca sorpresa. Internamente reutiliza `render` y no inventa heurísticas complejas.

## Ejemplos de uso

Listar catálogo:

```bash
./local/bin/ai-prompt list
```

Obtener prompt canónico:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo \
  ./local/bin/ai-prompt show review-diff | head -20
```

Renderizar con contexto explícito:

```bash
printf 'Small diff summary\n' | \
  AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo \
  ./local/bin/ai-prompt render review-diff --stdin | head -30
```

Renderizar a archivo fijo:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo \
  ./local/bin/ai-prompt render summarize-repo \
  --context-file README.md \
  --output-file /tmp/repo-summary-prompt.md
```

Renderizar a archivo temporal y devolver la ruta:

```bash
printf 'Small diff summary\n' | \
  AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo \
  ./local/bin/ai-prompt render review-diff \
  --stdin \
  --output-temp \
  --print-output-path
```

Usar un task:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo \
  ./local/bin/ai-prompt task write-commit-message | head -40
```

Copiar al clipboard sin perder stdout:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo \
  ./local/bin/ai-prompt show review-diff --copy | head -20
```

## Portapapeles

`--copy` es opcional. Si funciona, copia el contenido y mantiene la salida normal del comando.

Backends soportados por mejor esfuerzo:

- `pbcopy`
- `wl-copy`
- `xclip`
- `xsel`
- `clip.exe`

Si no hay backend disponible, el comando falla claramente.

## Depuración básica

### Si falta el vault

Comprueba primero la variable:

```bash
echo "$AI_PROMPTS_VAULT_ROOT"
```

Y luego valida:

```bash
./local/bin/ai-prompt check
```

### Si falta un prompt

Comprueba si está soportado y si existe físicamente:

```bash
./local/bin/ai-prompt list
./local/bin/ai-prompt path review-diff
./local/bin/ai-prompt check
```

### Si falla `--git-diff` o `--git-status`

El comando debe ejecutarse dentro de un repo Git válido del cwd actual. No busca repos por fuera.

### Si falla `--copy`

El problema suele ser uno de estos:

- no hay backend de clipboard disponible
- el backend existe pero reporta error

En ambos casos el comando falla con un mensaje explícito.

## Qué no es este sistema

- no es una base de datos de prompts
- no hace indexing complejo del repo
- no sustituye la documentación específica de cada proyecto
- no impone que todos los proyectos deban usar estos prompts
- no está acoplado todavía de forma profunda a Cursor, Codex u OpenCode

## Cómo crecer sin romper la base

Reglas prácticas para extenderlo:

1. mantener un único punto de catálogo
2. no copiar prompts canónicos al repo
3. usar `show` para contrato base, `render` para composición, `task` para presets
4. añadir presets sólo si son pocos, claros y de valor real
5. tratar nuevas integraciones como capas opcionales, no como rediseño del núcleo

## Referencias

- Referencia operativa corta de CLI: [PROMPT_LAUNCHERS.md](PROMPT_LAUNCHERS.md)
- Guía para agentes: [ai-prompt-consumer skill](../ai/assets/skills/ops/ai-prompt-consumer/SKILL.md)
