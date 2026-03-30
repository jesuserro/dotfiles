# Git: autor IA y wrapper (`git-set-ai-author` / `git-ai-wrapper`)

Herramientas para que los commits hechos desde **Cursor Source Control** (u otro cliente que use el mismo `git`) puedan llevar **autor** de agente IA mientras el **committer** sigue siendo tu identidad humana.

## Qué hace

- **`git-set-ai-author`** (CLI): en el repo actual escribe o borra el fichero de estado **`.git/ai-author/current`** (una línea: `Nombre <email>`).
- **`git-ai-wrapper`**: binario que Cursor invoca como `git` vía **`git.path`**. Si el comando es un **`commit`** y no hay `--author` explícito, aplica la identidad leída de `.git/ai-author/current` como `GIT_AUTHOR_*`; el committer sigue fijado a tu identidad humana en el script.

## Camino oficial de materialización (Chezmoi)

La forma **oficial** de dejar los binarios en `PATH` es:

```bash
chezmoi apply
```

Tras el apply, el script [`run_after_13_link_git_ai_wrapper.sh.tmpl`](../.chezmoiscripts/run_after_13_link_git_ai_wrapper.sh.tmpl) enlaza el source tree de Chezmoi con **`~/.local/bin/`** (symlinks).

### Checklist rápido

```bash
chezmoi apply
command -v git-set-ai-author
command -v git-ai-wrapper
ls -l "${HOME}/.local/bin/git-ai-wrapper" "${HOME}/.local/bin/git-set-ai-author"
```

Deberías ver symlinks hacia `local/bin/git-ai-wrapper` y `scripts/git-set-ai-author.sh` dentro de tu árbol de dotfiles gestionado por Chezmoi.

### Camino secundario (compatibilidad)

[`scripts/install-git-ai-wrapper.sh`](../scripts/install-git-ai-wrapper.sh) hace la **misma** materialización (`ln -sf` vía [`scripts/lib/git-ai-common.sh`](../scripts/lib/git-ai-common.sh)) cuando no puedes o no quieres ejecutar `chezmoi apply` en ese momento. No sustituye al flujo principal; solo reutiliza la misma lógica.

```bash
DOTFILES_ROOT="$HOME/dotfiles" ./scripts/install-git-ai-wrapper.sh
```

(Ajusta `DOTFILES_ROOT` si tu clone del repo vive en otra ruta.)

## Cómo se usa

En un clon Git:

```bash
cd /ruta/al/repo
git-set-ai-author cursor    # o codex, opencode
# ... commits con el wrapper como git ...
git-set-ai-author human     # quita el autor IA para este repo
git-set-ai-author status
git-set-ai-author list
```

## Activación en Cursor

1. Asegura los binarios (checklist anterior).
2. Ejecuta **`scripts/git-set-ai-enable.sh`**: escribe **`git.path`** en el **User `settings.json`** del editor Cursor (ruta según SO; ver [GIT_AI_CURSOR_SETTINGS.md](GIT_AI_CURSOR_SETTINGS.md)).
3. Recarga la ventana de Cursor si Source Control sigue usando otro `git`.

## Validación

- Terminal (misma ruta que usará el IDE):

  ```bash
  ~/.local/bin/git-ai-wrapper commit -m "smoke"
  ```

- Depuración:

  ```bash
  GIT_AI_WRAPPER_DEBUG=1 ~/.local/bin/git-ai-wrapper commit -m "smoke"
  ```

- Tests del repo: `make test-fast` (incluye `tests/bats/git-ai-author.bats`).

## Cómo se desactiva

- **`scripts/git-set-ai-disable.sh`**: quita `git.path` de los settings resueltos, opcionalmente restaura backup, y elimina el wrapper en `~/.local/bin/git-ai-wrapper` (el symlink o fichero en esa ruta). Vuelve a ejecutar **`chezmoi apply`** si quieres recrear los symlinks oficiales.

## Papel de Chezmoi

- Los scripts y el wrapper viven en el **repo de dotfiles**.
- **`chezmoi apply`** + **`run_after_13`** es el mecanismo **oficial** para publicar `git-ai-wrapper` y `git-set-ai-author` en `~/.local/bin/`.

## Contrato congelado (post–validación)

Comportamiento que **no** se pretende cambiar sin una nueva ronda explícita de diseño:

- **Autor vs committer**: el **autor** del commit puede ser el agente IA leído de `.git/ai-author/current` cuando aplica; el **committer** permanece como la identidad humana definida en el wrapper.
- **Solo `commit`**: para el resto de subcomandos, el wrapper hace **passthrough** al `git` real (`GIT_REAL`).
- **`git.path`**: la integración con Cursor es **vía** `git.path` apuntando al wrapper en el entorno donde corre Git (p. ej. WSL), no una ruta Windows `C:\...` para el binario Linux.
- **WSL + Cursor en Windows**: flujo **validado**; la resolución del `settings.json` del editor en el host Windows está descrita en [GIT_AI_CURSOR_SETTINGS.md](GIT_AI_CURSOR_SETTINGS.md).

## Limitaciones deliberadas

- Identidades humanas y de agente están **fijadas en el wrapper** para el strip de `--author` duplicado; cambiar de humano implica editar el wrapper o el flujo acordado.
- Otros editores/IDES no están integrados salvo que configuren un `git` equivalente al wrapper.
- Si `git.path` apunta mal o falta el symlink tras un apply, Source Control no usará el wrapper.

## Archivos relevantes

| Pieza | Ubicación |
|-------|-----------|
| Wrapper | [`local/bin/git-ai-wrapper`](../local/bin/git-ai-wrapper) |
| CLI autor IA | [`scripts/git-set-ai-author.sh`](../scripts/git-set-ai-author.sh) |
| Lib compartida | [`scripts/lib/git-ai-common.sh`](../scripts/lib/git-ai-common.sh) |
| Rutas Cursor `settings.json` | [`scripts/lib/git-ai-cursor-path.sh`](../scripts/lib/git-ai-cursor-path.sh) |
| Materialización Chezmoi | [`run_after_13_link_git_ai_wrapper.sh.tmpl`](../.chezmoiscripts/run_after_13_link_git_ai_wrapper.sh.tmpl) |
| Estado por repo | `.git/ai-author/current` (una línea) |

## Dónde está el `settings.json` del editor (por plataforma)

Ver **[GIT_AI_CURSOR_SETTINGS.md](GIT_AI_CURSOR_SETTINGS.md)** (Linux nativo, WSL + Cursor Windows, override manual, legado `~/.cursor/settings.json`).
