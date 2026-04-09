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
path <prompt-id>
check
help
```

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

Si los publicas en `PATH` con `chezmoi apply`:

```bash
ai-prompt list
ai-prompt show understand-context | head
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
```
