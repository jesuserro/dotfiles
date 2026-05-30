# Tmux en dotfiles

Tmux actúa como **sesión persistente de trabajo** dentro de Ubuntu/WSL. Windows Terminal sigue siendo el contenedor de la terminal; tmux organiza paneles y ventanas dentro de esa sesión.

## Lanzar el workspace dotfiles

```bash
~/dotfiles/bin/tmux-dotfiles
```

El comando:

- Crea la sesión `dotfiles` si no existe.
- Reabre la sesión existente si ya está creada (idempotente).
- Abre la ventana `main` con **dos columnas**.
- Deja **ambos paneles** en el directorio del repo dotfiles (`~/dotfiles` por defecto).

Override del repo:

```bash
DOTFILES_DIR=/ruta/al/repo ~/dotfiles/bin/tmux-dotfiles
```

## Detach y reattach

| Acción | Atajo / comando |
|--------|-----------------|
| Detach (dejar tmux en segundo plano) | `Ctrl+b` luego `d` |
| Reattach | `~/dotfiles/bin/tmux-dotfiles` |
| Reattach alternativo | `tmux attach-session -t dotfiles` |

## Cambiar de panel

| Método | Cómo |
|--------|------|
| Teclado | `Ctrl+b` luego `←` / `→` (o `h` / `l` según bindings) |
| Ratón | Click en el panel deseado (`set -g mouse on` en `tmux.conf`) |

## Pegado y clipboard

| Método | Fiabilidad | Notas |
|--------|------------|-------|
| `Ctrl+Shift+V` en Windows Terminal | **Fiable** | Recomendado para pegar desde el portapapeles de Windows |
| Botón derecho | Depende de WT | Configuración de Windows Terminal (`pasteOnRightClick`, etc.) |
| Selección + ratón con `mouse on` | Variable | Tmux puede interceptar clicks; no promete pegado universal con botón derecho |

Copiar **desde** tmux hacia el portapapeles de Windows en WSL puede usar los bindings de `tmux.conf` (por ejemplo `y` en copy-mode cuando `clip.exe` está disponible).

## Configuración actual

- `~/.tmux.conf` apunta al [`tmux.conf`](../tmux.conf) del repo (symlink manual hoy).
- Incluye `mouse on`, índices base 1 y renumber de ventanas.
- Chezmoi **no** gobierna aún tmux; la materialización formal puede venir en una fase posterior.

## Alcance de workspaces

Este BUILD entrega solo el workspace moderno **`dotfiles`**.

Workspaces futuros posibles (no implementados aún):

- `store-etl` (casa)
- proyectos IXATU (oficina)
- `jesuserro` / CV

Scripts legacy que permanecen en `tmux/` (`home.sh`, `work.sh`, `common/*`) no forman parte del flujo moderno.
