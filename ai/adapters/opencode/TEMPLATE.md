# OpenCode Adapter

Adapter para generar commands personalizados en OpenCode.

## Formato Esperado

OpenCode reconoce commands personalizados en `~/.config/opencode/commands/` como archivos Markdown con frontmatter YAML al inicio.

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
4. **Encoding**: UTF-8, sin caracteres especiales problemáticos

## Ubicación del Artefacto Generado

```
dot_config/opencode/commands/<command-id>.md
```

## Invocación

El command se invoca en OpenCode TUI como:
```
/<command-id>
```

Ejemplo: `/sos`

## Notas de Implementación

- El frontmatter DEBE empezar en la primera línea
- No incluir headers HTML ni comentarios antes del frontmatter
- El separador `---` marca el fin del frontmatter
