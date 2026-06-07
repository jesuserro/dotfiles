# Documentación dotfiles

## Agentes IA

- **[AGENT_FIRST_SUMMARY.md](AGENT_FIRST_SUMMARY.md)** — Resumen operativo y checklist del bloque agent-first (BUILDs 1–10); punto de entrada sintético.
- **[AGENT_WORKFLOW.md](AGENT_WORKFLOW.md)** — Contrato operativo para agentes en este repo (modos PLAN/BUILD/AUDIT, rutas sensibles, validación).
- **[SCRIPT_CONVENTIONS.md](SCRIPT_CONVENTIONS.md)** — Convención `--check`, `--dry-run`, `DRY_RUN=1`, `--yes` y auditoría de comandos mutantes.
- **[AI_REPO_MAP.md](AI_REPO_MAP.md)** — Mapa operativo por zona (intención, riesgos, validación; complementa STRUCTURE.md).
- **[VALIDATION_MATRIX.md](VALIDATION_MATRIX.md)** — Matriz cambio → validación por tipo de archivo.
- **[adr/](adr/README.md)** — Architecture Decision Records: decisiones técnicas y memoria arquitectónica.

## Operaciones

- **[OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md)** — Chuleta diaria: casa/oficina, drift Chezmoi, apply acotado, MCP, GitNexus, agentes.
- **[OPERATIONS.md](OPERATIONS.md)** — Guía operativa principal: modelo mental (bootstrap / Chezmoi / update), máquina nueva o existente, secretos, MCPs y validaciones.

## Instalación

- **[INSTALL.md](INSTALL.md)** — Bootstrap e instalación inicial (clonar, Age, SOPS, `DOTFILES_APPLY=1`). No duplica toda la guía operativa; enlaza a OPERATIONS.

## Comandos

- **[UPDATE.md](UPDATE.md)** — `make update`: actualización diaria integral (Windows, WSL, Node, OpenCode, MCPs Docker).
- **[COMMANDS_ARCHITECTURE.md](COMMANDS_ARCHITECTURE.md)** — Sistema de commands globales para IA (sos, etc.).
- **[AI_PROMPTS_SYSTEM.md](AI_PROMPTS_SYSTEM.md)** — Sistema `ai-prompt`: prompts canónicos externos, contrato público, ejemplos y límites.
- **[VAULT_PROJECT_WIKI_FLOW.md](VAULT_PROJECT_WIKI_FLOW.md)** — Flujo para decidir cuándo capturar conocimiento destilado en `vault_trabajo/projects/<project>/knowledge/...`.

## Chezmoi + SOPS + Age

- **[CHEZMOI.md](CHEZMOI.md)** — Referencia principal. Requisitos, uso, configuración Age+SOPS, estructura de secretos y de los symlinks de la zsh stack (`~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`).
- **[SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md)** — Ejemplos prácticos: dar de alta token GitHub, DSN Postgres, claves MinIO.
- **[MIGRATION_MCP_CHEZMOI.md](MIGRATION_MCP_CHEZMOI.md)** — Migración MCP a Chezmoi. Qué gestiona, MCPs globales vs Store ETL.
- **[MIGRATION_MCP_ITER3.md](MIGRATION_MCP_ITER3.md)** — Layout de servidores MCP (`ai/runtime/mcp/`), venv.
- **[GUIA_MCP_AI.md](GUIA_MCP_AI.md)** — Guía práctica: añadir MCPs, skills, verificar.
- **[CAMBIAR_TOKEN_GITHUB.md](CAMBIAR_TOKEN_GITHUB.md)** — Cambiar token GitHub (PAT classic).

## Git

- **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)** — Flujo de trabajo con git (feat, rel, changelog, etc.).
- **[GIT_FLOW_POLICY.md](GIT_FLOW_POLICY.md)** — Política opt-in por repo para evolucionar el flujo `git feat` / `git rel`.
- **[examples/git-flow-policy.env](examples/git-flow-policy.env)** — Ejemplo canónico de `.git-flow-policy.env` para copiar en proyectos.
- **[GIT_REL_INCIDENT.md](GIT_REL_INCIDENT.md)** — Nota operativa de mantenimiento y debugging de `git rel` tras una incidencia real.
- **[GIT_AI_AUTHOR.md](GIT_AI_AUTHOR.md)** — Autor IA vs committer humano: `git-set-ai-author`, `git-ai-wrapper`, Chezmoi, activación en Cursor, validación.
- **[GIT_AI_CURSOR_SETTINGS.md](GIT_AI_CURSOR_SETTINGS.md)** — Solo rutas de `User/settings.json` y `git.path` (Linux / WSL + Cursor Windows / override).

## Otros

- **[../STRUCTURE.md](../STRUCTURE.md)** — Árbol del repositorio.
- **[../codex/README-mcp.md](../codex/README-mcp.md)** — MCPs locales, smoke tests, variables de entorno.
