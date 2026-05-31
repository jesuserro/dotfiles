# Tmux en dotfiles

Tmux actúa como **sesión persistente de trabajo** dentro de Ubuntu/WSL. Windows Terminal sigue siendo el contenedor de la terminal; tmux organiza paneles y ventanas dentro de esa sesión.

## Lanzar el workspace dotfiles

Tras `chezmoi apply`, el comando canónico (en PATH vía `~/.local/bin`):

```bash
tmux-dotfiles
```

Fallback directo al script del repo:

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
DOTFILES_DIR=/ruta/al/repo tmux-dotfiles
```

## Detach y reattach

| Acción | Atajo / comando |
|--------|-----------------|
| Detach (dejar tmux en segundo plano) | `Ctrl+b` luego `d` |
| Reattach | `tmux-dotfiles` |
| Reattach alternativo | `tmux attach-session -t dotfiles` |
| Ayuda | `tmux-dotfiles --help` |

## Cambiar de panel

| Método | Cómo |
|--------|------|
| Teclado | `Ctrl+b` luego `←` / `→` (o `h` / `l` según bindings) |
| Ratón | Click en el panel deseado (`set -g mouse on` en `tmux.conf`) |

## Pegado y clipboard

| Método | Fiabilidad | Notas |
|--------|------------|-------|
| `Ctrl+Shift+V` en Windows Terminal | **Fiable** | Recomendado para pegar desde el portapapeles de Windows |
| Botón derecho | Depende de WT | Configuración de Windows Terminal (`pasteOnRightClick`, etc.) y de `mouse on` en tmux |
| Selección + ratón con `mouse on` | Variable | Tmux puede interceptar clicks; no promete pegado universal con botón derecho |

Copiar **desde** tmux hacia el portapapeles de Windows en WSL puede usar los bindings de `tmux.conf` (por ejemplo `y` en copy-mode cuando `clip.exe` está disponible).

## Configuración actual

- `~/.tmux.conf` es un symlink gestionado por Chezmoi hacia [`tmux.conf`](../tmux.conf) del repo (`symlink_dot_tmux.conf.tmpl`).
- Incluye `mouse on`, índices base 1 y renumber de ventanas.
- `~/.tmux.conf.local` está reservado para overrides locales (`source -q` al final de `tmux.conf`); Chezmoi **no** lo crea todavía — créalo manualmente si lo necesitas.
- `~/.local/bin/tmux-dotfiles` se publica con `run_after_15_link_tmux_dotfiles` tras `chezmoi apply`.

Si ya tienes un `~/.tmux.conf` regular con contenido custom, el hook `run_before_00_backup_rc_files` aborta el apply de forma segura. Para permitir backup y reemplazo: `ZSH_RC_APPLY=1 make install-dotfiles DOTFILES_APPLY=1` (el flag histórico cubre también `.tmux.conf`; ver [CHEZMOI.md](CHEZMOI.md)).

## Alcance de workspaces

Este BUILD entrega solo el workspace moderno **`dotfiles`**.

Workspaces futuros posibles (no implementados aún):

- `store-etl` (casa)
- proyectos IXATU (oficina)
- `jesuserro` / CV

Scripts legacy que permanecen en `tmux/` (`home.sh`, `work.sh`, `common/*`) no forman parte del flujo moderno.
