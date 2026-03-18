# Global Commands Architecture

Documentacion del sistema de commands globales en dotfiles.

## Resumen

El sistema queda separado en cuatro piezas:

1. **Canónico**: `ai/assets/commands/`
2. **Adapters**: `ai/adapters/`
3. **Build efímero**: `build/commands/`
4. **Runtime final**: `~/.config/opencode/commands/`, `~/.cursor/commands/`, `~/.codex/prompts/`

La idea principal es que el repo ya no muestre un `sos.md` por plataforma como parte del diseño estable. Esos archivos son derivados y viven fuera del árbol estable del repo.

## Capas

| Capa | Ruta | Rol | Se edita |
|------|------|-----|----------|
| Canónica | `ai/assets/commands/` | Fuente única de verdad | Sí |
| Adapters | `ai/adapters/` | Reglas por plataforma | A veces |
| Build | `build/commands/` | Artefactos generados y efímeros | No |
| Runtime | `~/.config/...`, `~/.cursor/...`, `~/.codex/...` | Destino final consumido por cada agente | No |

## Flujo

```text
ai/assets/commands/...
        |
        |  ./scripts/generate-commands.sh
        v
build/commands/{opencode,cursor,codex}/<id>.md
        |
        |  ./scripts/materialize-commands.sh
        |  o bien chezmoi apply
        v
~/.config/opencode/commands/<id>.md
~/.cursor/commands/<id>.md
~/.codex/prompts/<id>.md
```

## Edicion y generacion

Se edita solo aqui:

- `ai/assets/commands/registry.yaml`
- `ai/assets/commands/<id>/COMMAND.md`

Se genera aqui:

- `build/commands/opencode/<id>.md`
- `build/commands/cursor/<id>.md`
- `build/commands/codex/<id>.md`

Los adapters siguen siendo explicitos:

- `ai/adapters/opencode/TEMPLATE.md`
- `ai/adapters/cursor/TEMPLATE.md`
- `ai/adapters/codex/TEMPLATE.md`

## Materializacion

El script principal de publicacion es:

```bash
./scripts/materialize-commands.sh
```

Comportamiento:

- usa `HOME` por defecto
- acepta override con `COMMANDS_HOME_ROOT`
- genera `build/commands/` antes de sincronizar, salvo que se pida reutilizar el build existente
- publica solo a las superficies gestionadas del sistema

Ejemplo para tests/debug:

```bash
COMMANDS_HOME_ROOT=/tmp/commands-home ./scripts/materialize-commands.sh
```

Chezmoi solo orquesta:

- hook: `.chezmoiscripts/run_after_12_materialize_ai_commands.sh.tmpl`
- accion: invocar `scripts/materialize-commands.sh`

## Politica de limpieza

La limpieza de obsoletos es precisa:

- solo inspecciona `~/.config/opencode/commands/`, `~/.cursor/commands/` y `~/.codex/prompts/`
- no borra directorios completos
- no toca archivos manuales ajenos
- elimina solo `.md` con marcador de gestion del sistema que ya no formen parte del conjunto esperado

Marcador usado:

```text
managed-by: dotfiles-global-commands
```

Esto permite distinguir artefactos gestionados de archivos manuales o futuros.

## Validacion

La validacion estructural vive en:

```bash
./scripts/validate-commands-structure.sh
```

Valida:

- existencia y validez de `registry.yaml`
- estructura de cada command canónico
- existencia de adapters
- formato de `build/commands/...` solo si el build ya existe

Importante:

- que `build/commands/` no exista todavia **no es un error estructural**

## Invocacion por plataforma

| Plataforma | Runtime | Invocacion |
|-----------|---------|------------|
| OpenCode | `~/.config/opencode/commands/<id>.md` | `/<command>` |
| Cursor | `~/.cursor/commands/<id>.md` | `/<command>` |
| Codex | `~/.codex/prompts/<id>.md` | `/prompts:<command>` |

## Comandos utiles

```bash
./scripts/generate-commands.sh
./scripts/validate-commands-structure.sh
./scripts/materialize-commands.sh
COMMANDS_HOME_ROOT=/tmp/commands-home ./scripts/materialize-commands.sh
make test-commands
```
