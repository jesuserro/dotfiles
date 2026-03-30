# Cursor: dónde va `git.path` (git-ai-wrapper)

Los scripts `scripts/git-set-ai-enable.sh` y `scripts/git-set-ai-disable.sh` escriben la clave **`git.path`** del **editor Cursor** para que Source Control use `git-ai-wrapper`.

**Flujo completo de la feature** (uso, Chezmoi, validación, contrato): [GIT_AI_AUTHOR.md](GIT_AI_AUTHOR.md). Este documento se limita a **rutas de `User/settings.json` y overrides**.

## Tres configuraciones distintas (no las mezcles)

| Qué es | Ruta típica (ejemplos) | Uso |
|--------|------------------------|-----|
| **Cursor CLI** (agente en terminal) | `~/.cursor/cli-config.json` | Permisos, modelo, red, *no* integración Git del IDE |
| **Legado / ruta incorrecta asumida** | `~/.cursor/settings.json` | **No** es el `User/settings.json` del editor; no uses esto para `git.path` |
| **Editor — User Settings** | Ver tabla por plataforma abajo | Aquí es donde VS Code/Cursor leen `git.path` para la UI |

Referencia upstream de ubicaciones de settings: [VS Code: User settings file locations](https://code.visualstudio.com/docs/getstarted/settings#_settings-file-locations).

## User Settings del editor por entorno

### Linux nativo (Cursor instalado en Linux)

- `${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json`

### macOS

- `~/Library/Application Support/Cursor/User/settings.json`

### Windows (Cursor instalado en Windows)

- `%APPDATA%\Cursor\User\settings.json`
- Ejemplo: `C:\Users\<usuario>\AppData\Roaming\Cursor\User\settings.json`

### WSL + Cursor instalado en **Windows** (flujo habitual)

El proceso del editor es **Windows**. Los User Settings que afectan a la ventana de Cursor están en el perfil de Windows, accesibles desde WSL como:

- `/mnt/c/Users/<usuario Windows>/AppData/Roaming/Cursor/User/settings.json`

Equivale a la ruta que a veces se muestra como `/C:/Users/.../AppData/Roaming/...` (estilo Git Bash/MSYS): es el **mismo archivo** visto desde otro estilo de ruta.

Los scripts detectan WSL (`/proc/version` con Microsoft/WSL) y, si existe el montaje `/mnt/c`, resuelven `<usuario Windows>` con `cmd.exe` (`%USERNAME%`) y usan esa ruta.

### WSL sin acceso al disco C: o sin `cmd.exe`

Se hace **fallback** a la ruta Linux nativa bajo `~/.config/Cursor/User/settings.json` (por si usas Cursor solo en Linux dentro de WSL).

## Anulación manual

Si la detección automática no coincide con tu instalación:

```bash
export CURSOR_USER_SETTINGS_PATH="/ruta/absoluta/a/User/settings.json"
./scripts/git-set-ai-enable.sh
```

Misma variable para inspeccionar qué fichero tocarán los scripts:

```bash
source scripts/lib/git-ai-cursor-path.sh
cursor_editor_user_settings_path
```

## Valor de `git.path`

Debe ser la ruta **en el sistema donde se ejecuta Git** (en WSL suele ser algo como `/home/.../.local/bin/git-ai-wrapper`), no una ruta `C:\...` de Windows, porque el wrapper se invoca desde el entorno Linux del repo.

## Validación rápida (terminal)

```bash
~/.local/bin/git-ai-wrapper commit -m "mensaje"
```

Con `GIT_AI_WRAPPER_DEBUG=1` el wrapper imprime en stderr argv y decisiones de filtrado.

## Chezmoi y materialización de binarios

El **`git.path`** apunta al wrapper bajo `~/.local/bin/`; esos enlaces los crea **`chezmoi apply`** mediante `run_after_13` (ver [GIT_AI_AUTHOR.md](GIT_AI_AUTHOR.md)). Los scripts enable/disable **no** sustituyen a Chezmoi: solo editan el `settings.json` del editor.
