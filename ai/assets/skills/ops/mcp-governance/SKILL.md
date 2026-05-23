---
name: mcp-governance
description: Guides classification, integration and maintenance of MCP servers following the layered architecture. Use when adding, modifying or auditing MCP configuration in the dotfiles.
---

# Dotfiles MCP Governance

Guía para mantener la arquitectura de MCPs según la convención de capas y el **manifiesto canónico**.

## Fuente de verdad

- **Intención producto** (qué MCPs existen y en qué superficies están activos): **`ai/assets/mcps/MANIFEST.yaml`**, con **`policy.compatible_by_default_enabled: true`**.
- **Coherencia repo** (manifiesto + recetas Python + plantillas Chezmoi): **`make ai-mcp-governance`** o **`bin/validate-mcp-governance`** (encadena validate + render + drift).
- **Readiness en máquina** (HOME, Cursor, secretos, binarios): **`make ai-cursor-check`** — no lo sustituye governance.

## Cadena canónica (repo → HOME)

```text
MANIFEST.yaml
  → make ai-mcp-governance
  → make ai-mcp-generate APPLY=1    # solo cuando toque regenerar plantillas
  → chezmoi --source=$HOME/dotfiles apply   # publicar ~/.cursor/mcp.json, etc.
  → make ai-cursor-check
```

**`make update` no sustituye** `chezmoi apply` ni regenera secretos. Operación general: skill **`dotfiles-operations`**.

### Troubleshooting breve

| Síntoma | Causa habitual | Acción agente |
|---------|----------------|---------------|
| Docker MCP / `Docker Desktop is not running` | Desktop cerrado en Windows | Abrir Docker Desktop; validar `docker.exe mcp version` — no solo `npm update` |
| Postgres: `POSTGRES_DSN not set` | `mcp.postgres_dsn` vacío en SOPS | `sops secrets.sops.yaml` → `chezmoi apply -i scripts`; verificar `grep -E '^export POSTGRES_DSN=.' ~/.config/mcp-secrets.env` |
| Drift plantillas | MANIFEST ≠ `dot_cursor/` | `make ai-mcp-governance` → `make ai-mcp-generate APPLY=1` si procede |

## Referencia rápida (capas = rol, no segunda política de `enabled`)

| Capa | Scope | Manifest default (superficies globales) | Ejemplos |
|------|-------|----------------------------------------|----------|
| **Core Workstation** | Todos los proyectos | enabled | docker, github, fetch, context7, excalidraw, playwright, filesystem, git, sequential-thinking |
| **Platform** | Servicios locales | enabled (readiness si el servicio no está) | dagster, loki, minio, prometheus, tempo, store_etl_ops |
| **Connection-oriented** | DB / motores | enabled; credenciales fuera del repo | postgres, trino |

## Anti-patterns a evitar

- DSN o contraseñas hardcodeadas en plantillas del repo
- Omitir un MCP de una superficie sin **`enabled: false` + `reason`** en **`MANIFEST.yaml`**
- Mantener scripts grep que impongan otra política de activación que contradiga el manifiesto
- Confundir **governance** (drift / manifiesto) con **readiness** (`ai-cursor-check`)

## Añadir un nuevo MCP

### Paso 1: Clasificar (rol)

Asigna **layer** / **category** en el manifiesto según propósito (core, knowledge, domain, platform, connection).

### Paso 2: Superficies

Declara **`surfaces.cursor`**, **`codex`**, **`opencode`**. Usa **`enabled: false` + `reason`** solo para incompatibilidades reales.

### Paso 3: Definir runtime

- **npm/npx**: `npx -y @vendor/package`
- **Python**: `~/.config/ai/runtime/.venv/bin/python -m module`
- **Wrapper**: `~/.local/share/chezmoi/bin/mcp-<name>-launcher`

### Paso 4: Secretos y conexión

| Qué | Dónde |
|-----|--------|
| Forma de secretos (paths, `keys_hint`) | Entrada **`secrets`** en **`MANIFEST.yaml`** |
| Valores sensibles | `secrets.sops.yaml` (cifrado) → **`~/.config/mcp-secrets.env` generado** por Chezmoi (no editar a mano) |
| Overrides por stack | Plantillas bajo `dot_config/<proyecto>/` cuando haga falta |

### Paso 5: Recetas y plantillas

Actualiza **`scripts/generate-mcp-configs.py`** si cambian `command` / `args` / `env`. Ejecuta **`make ai-mcp-governance`**. Para escribir plantillas productivas: **`make ai-mcp-generate APPLY=1`** (solo cuando toque regenerar).

## Runtime vs Connection Profile

```
┌─────────────────────┐     ┌─────────────────────────┐
│  MCP Tool (shared)  │     │  Connection profile     │
│  - npx package      │     │  - DSN / endpoint       │
│  - python -m        │ ──▶ │  - Credenciales       │
│  - wrapper script   │     │  - Catalog / schema     │
└─────────────────────┘     └─────────────────────────┘
```

**Regla:** el runtime puede ser compartido y versionado en dotfiles; los **valores** de conexión viven fuera del repo o en configs por stack.

## Archivos clave

| Archivo | Propósito |
|---------|-----------|
| `ai/assets/mcps/MANIFEST.yaml` | Intención canónica por superficie |
| `scripts/validate-mcp-manifest.py` | Validación del manifiesto |
| `scripts/generate-mcp-configs.py` | Render + drift + generate |
| `bin/validate-mcp-governance` | Orquestación validate + render + drift |
| `docs/adr/0001-mcp-governance.md` | ADR formal |
| `docs/MCP_QUICKREF.md` | Referencia operativa |

## Verificar configuración

```bash
cd ~/dotfiles
make ai-mcp-governance    # coherencia repo (PyYAML)
make ai-cursor-check      # readiness local (Cursor/HOME)
```

Para depurar en runtime (cuando OpenCode está instalado):

```bash
opencode mcp list
opencode mcp debug <nombre>
```

No uses `cat` de archivos de secretos en logs compartidos.

## Checklist al añadir MCP

- [ ] Entrada en **`MANIFEST.yaml`** con las tres superficies (o excepción documentada)
- [ ] Recetas en **`generate-mcp-configs.py`** si aplica
- [ ] `make ai-mcp-validate` y `make ai-mcp-governance` en verde
- [ ] Tras tocar plantillas: `make ai-mcp-generate APPLY=1` cuando corresponda → **`chezmoi apply`** → `make ai-cursor-check`
- [ ] No usar `sops -d` ni imprimir secretos en logs
