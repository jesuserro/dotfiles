# Validation Matrix — cambio → validación

## 1. Propósito

Esta matriz indica **qué validar** según el tipo de archivo o zona modificada en dotfiles. Está orientada a agentes IA que cierran un BUILD.

Contrato de comportamiento: [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md). Mapa por zona: [AI_REPO_MAP.md](AI_REPO_MAP.md).

---

## 2. Uso rápido

1. Identifica qué zonas tocaste en el BUILD.
2. Ejecuta la **validación mínima** de cada zona afectada.
3. Si el cambio es amplio o toca contratos, añade **validación extendida**.
4. Cierra con **`make agent-validate-changed`** (gate focalizado post-cambio).
5. Consulta [TESTING.md](TESTING.md) para detalle de targets y política OSV.

---

## 3. Matriz por zona

| Zona | Validación mínima | Validación extendida | Notas de riesgo |
|------|-------------------|----------------------|-----------------|
| `zsh/*` | `make test-lint`, `bats-zsh` | `make chezmoi-drift-report` | RC y symlinks afectan shell interactivo |
| `scripts/*` | `make agent-validate-changed` | `make test-lint`, `make test-fast` | shellcheck/shfmt estrictos en archivos cambiados |
| `scripts/update/*` | `update-workflow.bats` | `make update-check` | No ejecutar `make update` sin permiso |
| `scripts/hooks/*` | `git-hooks/hooks.bats` | `make bats-docs` si cambia doc asociada | post-commit GitNexus puede ser best-effort |
| `ai/assets/skills/*` | `make validate-skills-structure` | `make bats-skills` | No materializar skills en checkout |
| `ai/assets/mcps/*` | `make ai-mcp-governance` | `mcp-render-drift.bats`, `mcp-manifest.bats` | Drift render en `build/mcps/` |
| `ai/runtime/mcp/*` | `make ai-mcp-governance` | `ai-runtime-uv.bats`, `make bats-mcp` | Contrato launcher MCP |
| `docs/*` | `make bats-docs` | `documentation-consistency.bats` (vía bats-docs) | Mantener enlaces cruzados |
| `tests/*` | `make test-fast` | `make test` o `make test-ci` | Verificar que nuevos bats estén cableados en Makefile.tests |
| `.chezmoiscripts/*` | `make test-chezmoi` | `make chezmoi-drift-report` | Hooks mutan HOME en apply |
| `dot_local/bin/*` | `make agent-validate-changed` | `make test-chezmoi`, bats focalizados (p. ej. `playwright-docker.bats`) | Symlinks Chezmoi |
| `bin/*` | `make agent-validate-changed` | `make test-lint`, bats del wrapper | Launchers y utilidades globales |
| `system/packages/*` | `system-deps.bats` | `make deps-check` | Deps declarativas máquina nueva |
| `Makefile`, `*.mk` | `make -pn` (parse) | `make test-fast`, `system-deps.bats` si afecta deps | Targets rotos bloquean todo el repo |

---

## 4. Validación mínima

La validación mínima es el conjunto **imprescindible** para no romper contratos del área tocada:

- **Siempre al cerrar un BUILD con cambios:** `make agent-validate-changed`
- **Solo documentación:** `make bats-docs`
- **Solo skills:** `make validate-skills-structure`
- **Solo MCP manifest/runtime:** `make ai-mcp-governance`
- **Solo Chezmoi templates/hooks:** `make test-chezmoi`

`make agent-validate-changed` incluye `gitleaks` en el working tree — obligatorio para detectar secretos accidentales.

---

## 5. Validación extendida

Usar cuando el BUILD es amplio, toca varias zonas o modifica contratos estructurales:

| Comando | Cuándo |
|---------|--------|
| `make ai-doctor` | Pre-BUILD o diagnóstico de entorno (read-only) |
| `make test-fast` | Cambios en scripts, tests o Make sin tocar chezmoi pesado |
| `make test-ci` | Paridad con CI antes de handoff importante |
| `make agent-validate` | Gate dotfiles operativo (read-only; orquesta skills, MCP, changed files, docs) |
| `make agent-validate-audit` | Auditoría full-repo estricta (`quality-check` + `security-check`) |
| `make agent-validate-full` | `agent-validate` + `agent-validate-audit` |
| `SECURITY_ONLINE=1 make agent-validate-changed` | Escaneo OSV online (humano/pre-merge; requiere red) |
| `make chezmoi-drift-report` | Cambios en plantillas Chezmoi — sin apply |

`make agent-validate-audit` puede reportar deuda histórica shellcheck/shfmt en archivos no tocados; no sustituye el gate focalizado post-cambio.

---

## 6. Relación con agent-validate-changed

[`scripts/agent-validate-changed.sh`](../scripts/agent-validate-changed.sh) implementa **parte** de esta matriz de forma automática según `git diff`:

| Disparador (paths cambiados) | Acción automática |
|------------------------------|-------------------|
| `*.sh`, `*.bash`, `*.bats`, launchers | shellcheck + shfmt estrictos |
| `*.yaml`, `*.yml` | yamllint |
| `.github/workflows/*` | actionlint |
| `Makefile`, `*.mk` | `make -pn` |
| `system/packages/`, deps scripts | `system-deps.bats` |
| MCP paths (`ai/assets/mcps/`, `ai/runtime/mcp/`, etc.) | `make ai-mcp-governance` + bats MCP |
| `docs/` | `make bats-docs` |
| `ai/assets/handoffs/` | `documentation-consistency.bats` |
| `ai/assets/skills/` | `validate-skills-structure` + bats skills |
| `ai/assets/commands/` | `validate-commands` + bats commands |
| `.chezmoiscripts/`, `dot_*` | `make test-chezmoi` |
| `scripts/hooks/`, `.githooks/` | `git-hooks/hooks.bats` |
| `zsh/` | `make bats-zsh` |
| `scripts/update/` | `update-workflow.bats`, `update-governance.bats` |
| `bin/playwright-docker`, `dot_local/bin/` (playwright) | `playwright-docker.bats` |
| `bin/dotfiles-update`, symlink template | `dotfiles-update.bats` |
| Cualquier cambio | `gitleaks` working-tree |

El gate completo `make agent-validate` ejecuta además skills, MCP governance, `agent-validate-changed`, `bats-docs` y `update-check` vía [`scripts/agent-validate-dotfiles.sh`](../scripts/agent-validate-dotfiles.sh).

Para adjuntar resultados a handoffs: `make agent-validate-report` → [`scripts/agent-validate-report.sh`](../scripts/agent-validate-report.sh) → `build/agent-validation/latest.md`.

---

## 7. Documentos relacionados

| Documento | Contenido |
|-----------|-----------|
| [AGENT_WORKFLOW.md](AGENT_WORKFLOW.md) | Contrato y modos PLAN/BUILD/AUDIT |
| [AI_REPO_MAP.md](AI_REPO_MAP.md) | Intención y riesgos por zona |
| [TESTING.md](TESTING.md) | Stack, targets Make, política lint/OSV |
| [OPERATIONS_CHEATSHEET.md](OPERATIONS_CHEATSHEET.md) | Comandos por escenario y riesgo |
