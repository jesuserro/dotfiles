# Prompt Launchers

CLI mínima para imprimir por `stdout` prompts canónicos guardados fuera del repo, en tu vault de trabajo.

## Contrato público

- Comando unificado:
  - `ai-prompt`
- Launchers compatibles:
  - `prompt-understand-context`
  - `prompt-plan-safe-change`
  - `prompt-detect-errors`
- Variable de entorno:
  - `AI_PROMPTS_VAULT_ROOT`

`ai-prompt show <prompt-id>` imprime el contenido del prompt en `stdout`. Si falla, devuelve `exit != 0` y muestra un error útil en `stderr`.

Subcomandos disponibles:

```text
list
show <prompt-id>
render <prompt-id>
task <task-name>
path <prompt-id>
check
help
```

`render` escribe a `stdout` por defecto. Si usas `--output-file` o `--output-temp`, guarda el resultado en archivo; con `--print-output-path` imprime por `stdout` sólo la ruta final generada.

`task` es una capa fina de presets sobre `render`. Los tasks iniciales son:

- `review-diff` -> `review-diff` + `--git-diff --git-status`
- `write-commit-message` -> `write-commit-message` + `--git-diff --git-status`
- `summarize-repo` -> `summarize-repo` + `README.md` del cwd si existe

## Resolución del vault

La ruta del vault se resuelve en un único helper shell:

1. `AI_PROMPTS_VAULT_ROOT`, si está definida.
2. `DEFAULT_AI_PROMPTS_VAULT_ROOT`, fallback local/provisional centralizado para esta máquina.

La convención interna actual del prompt queda encapsulada en el helper:

```text
<vault-root>/agents/prompts/<prompt-name>.md
```

## Uso

Listar prompts soportados:

```bash
./local/bin/ai-prompt list
```

Mostrar un prompt:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show understand-context | head
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show plan-safe-change | head
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show detect-errors | head
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show summarize-repo | head
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show review-diff | head
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show write-commit-message | head
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt show design-test-cases | head
```

Renderizar un prompt compuesto:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt render summarize-repo --context-file README.md | head -40
printf 'Diff summary here\n' | AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt render review-diff --stdin | head -40
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt render write-commit-message --git-status | head -40
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt render write-commit-message --git-diff --git-status | head -60
printf 'Small diff summary\n' | AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt render review-diff --stdin --output-temp --print-output-path
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt render summarize-repo --context-file README.md --output-file /tmp/repo-summary-prompt.md
```

Usar presets de tarea:

```bash
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt task review-diff | head -60
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt task write-commit-message --output-temp --print-output-path
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt task summarize-repo | head -60
AI_PROMPTS_VAULT_ROOT=/mnt/c/Users/jesus/Documents/vault_trabajo ./local/bin/ai-prompt task summarize-repo --output-file /tmp/repo-summary.md
./local/bin/ai-prompt task help
./local/bin/ai-prompt task review-diff --explain
```

Si los publicas en `PATH` con `chezmoi apply`:

```bash
ai-prompt list
ai-prompt show understand-context | head
ai-prompt render summarize-repo --context-file README.md | head -40
ai-prompt check
prompt-understand-context | head
prompt-plan-safe-change | head
prompt-detect-errors | head
```

## Depuración rápida

Si falla la resolución, el launcher muestra:

- vault root resuelto
- ruta final del markdown intentada
- sugerencia de override con `AI_PROMPTS_VAULT_ROOT`

Ejemplos:

```bash
AI_PROMPTS_VAULT_ROOT=/tmp/no-existe ./local/bin/ai-prompt show detect-errors
AI_PROMPTS_VAULT_ROOT=/tmp/vault-sin-prompt ./local/bin/ai-prompt show detect-errors
./local/bin/ai-prompt show no-such-prompt
./local/bin/ai-prompt render summarize-repo --context-file /tmp/no-existe
./local/bin/ai-prompt render summarize-repo --output-file /proc/forbidden.md
./local/bin/ai-prompt render summarize-repo --output-file /tmp/a.md --output-temp
./local/bin/ai-prompt task no-such-task
```
