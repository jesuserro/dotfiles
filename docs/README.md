# Documentación dotfiles

## Instalación

- **[INSTALL.md](INSTALL.md)** — Instalación paso a paso (clonar, Age, SOPS, apply).

## Comandos

- **[UPS.md](UPS.md)** — Comando `ups`: actualización integral (APT, npm, Oh My Zsh, MCPs).
- **[COMMANDS_ARCHITECTURE.md](COMMANDS_ARCHITECTURE.md)** — Sistema de commands globales para IA (sos, etc.).

## Chezmoi + SOPS + Age

- **[CHEZMOI.md](CHEZMOI.md)** — Referencia principal. Requisitos, uso, configuración Age+SOPS, estructura de secretos. Incluye **cuándo usar rcup, source y chezmoi**.
- **[SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md)** — Ejemplos prácticos: dar de alta token GitHub, DSN Postgres, claves MinIO.
- **[MIGRATION_MCP_CHEZMOI.md](MIGRATION_MCP_CHEZMOI.md)** — Migración MCP a Chezmoi. Qué gestiona, MCPs globales vs Store ETL.
- **[MIGRATION_MCP_ITER3.md](MIGRATION_MCP_ITER3.md)** — Layout de servidores MCP (`ai/runtime/mcp/`), venv.
- **[GUIA_MCP_AI.md](GUIA_MCP_AI.md)** — Guía práctica: añadir MCPs, skills, verificar.
- **[CAMBIAR_TOKEN_GITHUB.md](CAMBIAR_TOKEN_GITHUB.md)** — Cambiar token GitHub (PAT classic).

## Git

- **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)** — Flujo de trabajo con git (feat, rel, changelog, etc.).

## Otros

- **[../STRUCTURE.md](../STRUCTURE.md)** — Árbol del repositorio.
- **[../codex/README-mcp.md](../codex/README-mcp.md)** — MCPs locales, smoke tests, variables de entorno.
