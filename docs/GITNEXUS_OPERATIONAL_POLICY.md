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

Ejemplos válidos:

- Cambio grande de arquitectura o muchos símbolos nuevos.
- MCP o `make gitnexus-status` reporta índice **STALE** y el trabajo lo requiere.
- Antes de análisis de impacto importante que dependa del grafo actualizado.
- **Después** de cerrar procesos MCP que puedan retener lock en `lbug`.

Procedimiento: `make update-check` → confirmar no hay MCPs vivos → `gnx-analyze-here` → revisar diff en `AGENTS.md`/`CLAUDE.md` antes de commit.

---

## Referencias

- Helpers zsh: [`aliases`](../aliases) (`gnx-analyze-here`, `gnx-wiki-here`, …)
- MCP launcher (zona cerrada): `mcp-gitnexus-launcher`
- Skill CLI: [`ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md`](../ai/assets/skills/gitnexus/gitnexus-cli/SKILL.md)
- ADR: [`docs/adr/0002-gitnexus-mcp.md`](./adr/0002-gitnexus-mcp.md)
