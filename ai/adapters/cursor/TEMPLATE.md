# Cursor Adapter

Adapter para generar commands personalizados en Cursor IDE.

## Formato Esperado

Cursor reconoce commands personalizados en `~/.cursor/commands/` como archivos Markdown simples, sin frontmatter.

## Estructura del Output

```markdown
# Cursor Commands

<contenido del COMMAND.md original>
```

## Reglas de Adaptación

1. **Sin frontmatter**: Cursor NO espera frontmatter
2. **Header inicial**: Opcionalmente, incluir `# Cursor Commands\n\n` como prefijo visual
3. **Contenido**: El contenido del COMMAND.md original se inserta después del header
4. **Encoding**: UTF-8

## Ubicación del Artefacto Generado

```
dot_config/cursor/commands/<command-id>.md
```

## Invocación

El command se invoca en Cursor AI Chat como:
```
/<command-id>
```

Ejemplo: `/sos`

## Notas de Implementación

- Cursor no parsea frontmatter
- El archivo es Markdown puro
- Puede contener el título original del COMMAND.md
