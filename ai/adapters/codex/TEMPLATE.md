# Codex Adapter

Adapter para generar prompts personalizados en Codex.

## Formato Esperado

Codex reconoce prompts personalizados en `~/.codex/prompts/` como archivos Markdown con frontmatter YAML al inicio.

## Estructura del Output

```markdown
---
description: <descripción del command>
---

<contenido del COMMAND.md original>
```

## Reglas de Adaptación

1. **Frontmatter**: Obligatorio al inicio del archivo
2. **Campos**:
   - `description`: Descripción breve del command (tomada del registry)
3. **Contenido**: El contenido del COMMAND.md original se inserta después del frontmatter
4. **Encoding**: UTF-8

## Ubicación del Artefacto Generado

```
build/commands/codex/<command-id>.md
```

## Runtime Final

```
~/.codex/prompts/<command-id>.md
```

## Invocación

El command se invoca en Codex como:
```
/prompts:<command-id>
```

Ejemplo: `/prompts:sos`

**Nota importante**: Codex usa el prefijo `prompts:` en la invocación. Esto es comportamiento de plataforma, no configurable.

## Notas de Implementación

- El frontmatter DEBE empezar en la primera línea
- No incluir headers HTML ni comentarios antes del frontmatter
- El separador `---` marca el fin del frontmatter
- Codex requiere reiniciar sesión para cargar nuevos prompts
- Tras el frontmatter se permite un marcador de gestión del sistema
