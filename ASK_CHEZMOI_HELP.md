Hola, necesito ayuda con un problema de chezmoi.

## Problema
Al ejecutar `chezmoi apply` siempre pide confirmación para un archivo que ya no debería existir:
```
.config/store-etl/store-etl.mcp.json has changed since chezmoi last wrote it?
chezmoi: .config/store-etl/store-etl.mcp.json: could not open a new TTY: open /dev/tty: no such device or address
```

## Qué intenté

1. **Eliminar el archivo del filesystem**: Ya no existe `~/.config/store-etl/store-etl.mcp.json`

2. **Eliminar del índice de git de chezmoi**:
   ```bash
   git -C ~/.local/share/chezmoi rm --cached -r dot_config/store-etl
   git -C ~/.local/share/chezmoi rm --cached -r private_proyectos/store-etl
   git -C ~/.local/share/chezmoi commit -m "Remove store-etl from tracking"
   ```

3. **Agregar a .chezmoiignore**:
   ```
   .config/store-etl/
   proyectos/store-etl/
   ```

4. **Limpiar caché**: `rm -rf ~/.cache/chezmoi`

5. **Verificar estado de git en chezmoi**: `git -C ~/.local/share/chezmoi status` muestra los archivos correctos (ya NO aparecen store-etl)

6. **Ejecutar `chezmoi managed`**: Muestra `.config/store-etl/store-etl.mcp.json` como gestionado

7. **Ejecutar `chezmoi re-add`**: No dio error pero el problema persiste

## Estado actual
- El archivo `~/.config/store-etl/store-etl.mcp.json` NO existe en el filesystem
- git en `~/.local/share/chezmoi` NO tiene trackeado ese archivo
- `.chezmoiignore` tiene las exclusiones
- Pero `chezmoi apply` sigue pidiendo confirmación

## Árbol relevante
```
~/.local/share/chezmoi/
├── .chezmoi.toml  (config que apunta a /home/jesus/dotfiles como source)
├── .chezmoiignore
├── .git/
│   └── HEAD = ref: refs/heads/feature/6-adding-gitnexus-mcp
├── aliases
├── dot_codex/config.toml.tmpl
├── dot_config/opencode/opencode.json.tmpl
└── dot_cursor/mcp.json.tmpl

~/.config/store-etl/
└── secrets.env   (solo esto existe)

/home/jesus/dotfiles/
├── dot_config/store-etl/store-etl.mcp.json.tmpl
└── private_proyectos/store-etl/dot_cursor/mcp.json.tmpl
```

## Pregunta
¿Por qué chezmoi sigue pensando que debe gestionar `.config/store-etl/store-etl.mcp.json` si ya no está en el source y el archivo destino no existe? ¿Cómo puedo forzar a chezmoi a olvidar ese archivo completamente?

Gracias!
