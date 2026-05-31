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

### Procedimiento humano de refresh (dotfiles)

Comando **canónico** — solo índice en `.gitnexus/`, sin tocar bloques versionados:

```bash
make update-check
make gitnexus-status
# Si hay procesos MCP o lock en uso: cerrar Cursor / desactivar MCP GitNexus; repetir status
gnx-analyze-here -- --skip-agents-md
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
