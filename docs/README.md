# Documentación dotfiles

## Instalación

- **[INSTALL.md](INSTALL.md)** — Instalación paso a paso (clonar, Age, SOPS, apply).

## Comandos

- **[UPS.md](UPS.md)** — Comando `ups`: actualización integral (APT, npm, Oh My Zsh, MCPs).
- **[COMMANDS_ARCHITECTURE.md](COMMANDS_ARCHITECTURE.md)** — Sistema de commands globales para IA (sos, etc.).
- **[AI_PROMPTS_SYSTEM.md](AI_PROMPTS_SYSTEM.md)** — Sistema `ai-prompt`: prompts canónicos externos, contrato público, ejemplos y límites.
- **[VAULT_PROJECT_WIKI_FLOW.md](VAULT_PROJECT_WIKI_FLOW.md)** — Flujo para decidir cuándo capturar conocimiento destilado en `vault_trabajo/projects/<project>/knowledge/...`.

## Chezmoi + SOPS + Age

- **[CHEZMOI.md](CHEZMOI.md)** — Referencia principal. Requisitos, uso, configuración Age+SOPS, estructura de secretos. Incluye **cuándo usar rcup, source y chezmoi**.
- **[SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md)** — Ejemplos prácticos: dar de alta token GitHub, DSN Postgres, claves MinIO.
- **[MIGRATION_MCP_CHEZMOI.md](MIGRATION_MCP_CHEZMOI.md)** — Migración MCP a Chezmoi. Qué gestiona, MCPs globales vs Store ETL.
- **[MIGRATION_MCP_ITER3.md](MIGRATION_MCP_ITER3.md)** — Layout de servidores MCP (`ai/runtime/mcp/`), venv.
- **[GUIA_MCP_AI.md](GUIA_MCP_AI.md)** — Guía práctica: añadir MCPs, skills, verificar.
- **[CAMBIAR_TOKEN_GITHUB.md](CAMBIAR_TOKEN_GITHUB.md)** — Cambiar token GitHub (PAT classic).

## Git

- **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)** — Flujo de trabajo con git (feat, rel, changelog, etc.).
- **[GIT_REL_INCIDENT.md](GIT_REL_INCIDENT.md)** — Nota operativa de mantenimiento y debugging de `git rel` tras una incidencia real.
- **[GIT_AI_AUTHOR.md](GIT_AI_AUTHOR.md)** — Autor IA vs committer humano: `git-set-ai-author`, `git-ai-wrapper`, Chezmoi, activación en Cursor, validación.
- **[GIT_AI_CURSOR_SETTINGS.md](GIT_AI_CURSOR_SETTINGS.md)** — Solo rutas de `User/settings.json` y `git.path` (Linux / WSL + Cursor Windows / override).

## Otros

- **[../STRUCTURE.md](../STRUCTURE.md)** — Árbol del repositorio.
- **[../codex/README-mcp.md](../codex/README-mcp.md)** — MCPs locales, smoke tests, variables de entorno.
