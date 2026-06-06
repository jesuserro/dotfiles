# GitNexus Operational Policy

Política operativa para agentes y humanos en repos gestionados con dotfiles. Complementa [MCP_QUICKREF.md](./MCP_QUICKREF.md) y los skills en `ai/assets/skills/gitnexus/`.

**Comando read-only de estado:** `make gitnexus-status` → [`scripts/gitnexus-status.sh`](../scripts/gitnexus-status.sh).

---

## Qué es canónico y qué es derivado

| Artefacto | Tipo | Versionado | Notas |
|-----------|------|------------|-------|
| `.gitnexus/` | Derivado | Ignorado (`.gitignore`) | Índice local del repo. **No tocar por agentes.** |
| `.gitnexus/lbug` | Derivado (LadybugDB / lock) | Ignorado | **No borrar automáticamente.** |
| `.gitnexus/meta.json` | Derivado | Ignorado | Leer para staleness; no regenerar desde agentes. |
| `AGENTS.md` | **Mixto** | Versionado | Bloque `<!-- gitnexus:start/end -->` es derivado; secciones humanas (p. ej. Vault) son canónicas. |
| `CLAUDE.md` | Derivado (bloque GitNexus) | Versionado | Puede regenerarse con analyze; no editar sin petición. |
| `docs/wiki/` | Derivado | Depende del proyecto | Salida de `gnx-wiki-here`; no generar desde agentes. |
| `ai/assets/skills/gitnexus/*` | Canónico | Versionado | Política y workflows para agentes. |

---

## Acciones permitidas a agentes

- `make gitnexus-status` — estado read-only (índice, lock, Node, artefactos).
- Lectura con **MCP GitNexus** (`gitnexus_query`, `gitnexus_context`, `gitnexus_impact`, `gitnexus_detect_changes`, recursos `gitnexus://…`).
- `make update-check` — precheck Node/runtime (read-only).
- Inspección de docs, `meta.json` (si existe) y código fuente por medios habituales.
- El post-commit local instalado explícitamente con `make install-git-hooks` puede ejecutar el refresh best-effort descrito abajo; los agentes no lo invocan directamente.

---

## Acciones prohibidas salvo petición explícita de Jesús

- `gitnexus analyze` / `npx gitnexus analyze`
- `gnx-analyze-here`
- `gitnexus wiki` / `gnx-wiki-here`
- `gitnexus clean` / `npx gitnexus clean`
- Borrar `.gitnexus/lbug` o `.gitnexus/`
- Editar bloques `<!-- gitnexus:* -->` en `AGENTS.md` / `CLAUDE.md`
- Regenerar o commitear `AGENTS.md` / `CLAUDE.md` producidos por analyze
- `npx gitnexus …` como ruta por defecto en shells lanzados por IDE

---

## Locks (`.gitnexus/lbug`)

Flujo recomendado:

1. Ejecutar `make gitnexus-status`.
2. Revisar procesos listados (`gitnexus`, `ladybug`, MCP).
3. Si hay **MCPs vivos** (p. ej. Cursor con GitNexus MCP), **esperar** o cerrar IDE/MCP antes de analyze.
4. Si **no hay procesos** y analyze sigue fallando por lock, **reiniciar IDE** antes de considerar limpieza manual.
5. **No borrar `lbug`** sin decisión humana explícita.

---

## Post-commit local best-effort

`make install-git-hooks` configura `core.hooksPath=.githooks` solo para el
checkout actual. Su post-commit es best-effort y no invalida commits (siempre
sale `0`).

Comportamiento:

- Si `~/.gitnexus` (o `GITNEXUS_HOME`) o `registry.json` no son escribibles,
  omite el refresh con `WARN` y recomienda revisar permisos (`make gitnexus-status`).
- Si detecta MCP/procesos GitNexus o `.gitnexus/lbug` abierto, **no** ejecuta
  analyze; omite el refresh con `WARN` (el índice puede quedar **STALE** hasta
  refresh humano). Alineado con la política humana de no analyze con lock activo.
- Si no hay skip flags, permisos correctos y el índice libre, ejecuta
  síncronamente `gnx-analyze-here --force --skip-agents-md` con Node gestionado.
- El refresh expira tras 30 segundos para no bloquear commits largos.
- Si analyze falla o expira, avisa con mensaje accionable y sale `0`.
- Nunca usa background, retries largos, mata procesos MCP, limpia locks,
  `chmod`/`chown` automáticos ni ejecuta operaciones Git.
- `DOTFILES_SKIP_HOOKS=1` y `DOTFILES_SKIP_GITNEXUS=1` permiten omitirlo.

Refresh manual cuando el hook omitió o falló:

```bash
make gitnexus-status
# Si hay varios procesos gitnexus mcp: cerrar sesiones duplicadas de Cursor
gnx-analyze-here --force --skip-agents-md
```

---

## Node gestionado

| Ruta | Uso |
|------|-----|
| `make gitnexus-status` + MCP read-only | **Agentes** — seguro |
| `make update-check` | **Agentes** — diagnóstico Node |
| `gnx-analyze-here` | **Solo humano** — overlay Node gestionado (`>=22`) |
| `gnx-serve` | **Solo humano** — overlay Node gestionado; abre servidor local |
| `gnx-map` | **Solo humano** — analyze + serve vía helpers gestionados |
| `gnx-wiki-here` | **Solo humano** — overlay Node gestionado; puede usar red/LLM y escribir `docs/wiki/` |
| `make update-wsl` | **Mantenimiento humano** — instala/actualiza CLI con overlay |
| `scripts/install-gitnexus.sh` | **Bootstrap manual** — preferir `make update-wsl` para mantenimiento gestionado |
| `mcp-gitnexus-launcher` | **MCP (agentes)** — sin overlay explícito; PATH ordering (`/usr/bin` antes del Node IDE) |
| `npx gitnexus …` | **No recomendado** — puede ejecutar bajo Node v20 inyectado por Cursor/VS Code |

El problema: shells de agentes en IDE suelen tener `node` de `.cursor-server` (<22). Los helpers `gnx-*` cargan [`node_runtime.sh`](../scripts/update/lib/node_runtime.sh) y aplican overlay cuando hace falta; `npx gitnexus` no.

---

## Cuándo refrescar el índice (solo humano)

**`STALE` en `make gitnexus-status` no implica refresh automático.** Los agentes deben seguir con MCP read-only o pedir decisión humana; nunca ejecutar analyze por staleness sola.

Ejemplos válidos para que un humano refresque:

- Cambio grande de arquitectura o muchos símbolos nuevos.
- Índice **STALE** o **NO_INDEX** y el trabajo concreto depende del grafo actualizado.
- Antes de un análisis de impacto humano que requiera índice al día.

**No ejecutar analyze** si `make gitnexus-status` lista procesos `gitnexus mcp` / `analyze` / `ladybug`, o si el lock en `.gitnexus/lbug` está en uso: cerrar Cursor, desactivar el MCP GitNexus o esperar a que terminen y repetir status hasta que no haya procesos vivos. La presencia de `lbug` con MCP activo es habitual y no autoriza borrar el lock.

El post-commit local instalado explícitamente es la única automatización de
refresh: usa `--force --skip-agents-md`, timeout y semántica best-effort no
fatal, pero **no compite** con MCP/lock activo.

### Procedimiento humano de refresh (dotfiles)

Comando **canónico** — solo índice en `.gitnexus/`, sin tocar bloques versionados:

```bash
make update-check
make gitnexus-status
# Si hay procesos MCP o lock en uso: cerrar Cursor / desactivar MCP GitNexus; repetir status
gnx-analyze-here --skip-agents-md
make gitnexus-status
git status --short -- .gitnexus AGENTS.md CLAUDE.md docs/wiki
bats tests/bats/docs/agents-claude-gitnexus-blocks.bats
```

- **`--skip-agents-md`** evita regenerar `AGENTS.md` y `CLAUDE.md`. Es la ruta por defecto en este repo.
- Usar terminal con aliases cargados (`gnx-analyze-here`), no `gitnexus analyze` ni `npx gitnexus` desde shells de IDE.
- **No borrar** `.gitnexus/lbug` automáticamente.
- Tras un refresh exitoso, **reiniciar Cursor** (o el cliente MCP) si las herramientas siguen viendo índice viejo.

### Excepción: regenerar bloques AGENTS/CLAUDE

Solo si el humano **quiere** actualizar la sección `<!-- gitnexus:start/end -->`:

```bash
gnx-analyze-here
```

GitNexus puede sobrescribir esos bloques con texto upstream (incluido referencias a `npx gitnexus analyze`). Revisar diff manualmente antes de commit. Los tests en `tests/bats/docs/agents-claude-gitnexus-blocks.bats` detectan regresiones.

Versión corta operativa: [OPERATIONS_CHEATSHEET.md §8](OPERATIONS_CHEATSHEET.md).

---

## Referencias

- Helpers zsh: [`aliases`](../aliases) (`gnx-analyze-here`, `gnx-wiki-here`, …)
- MCP launcher (zona cerrada): `mcp-gitnexus-launcher`
- Skill CLI: [`ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md`](../ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md)
- ADR: [`docs/adr/0002-gitnexus-mcp.md`](./adr/0002-gitnexus-mcp.md)
