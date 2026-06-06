# Instalación

Guía paso a paso para **bootstrap** en una máquina nueva. Para operación diaria (secretos, MCPs, `make update`, troubleshooting), ver **[OPERATIONS.md](OPERATIONS.md)**.

> **`make install` ≠ `chezmoi apply`.** El Makefile instala paquetes y orquesta el plan; la materialización en HOME (MCPs, symlinks RC, `mcp-secrets.env`) requiere **`make install-dotfiles DOTFILES_APPLY=1`** o `chezmoi --source=$HOME/dotfiles apply`.

---

## Requisitos previos

Para el inventario declarativo de paquetes base del sistema y su chequeo/instalación por `apt`, ver [SYSTEM_DEPENDENCIES.md](SYSTEM_DEPENDENCIES.md). Esta guía mantiene solo el flujo general de bootstrap.

| Herramienta | Instalación |
|-------------|-------------|
| **Chezmoi** | `make install-chezmoi` (opt-in, idempotente, sin sudo) o fallback `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"` / [releases](https://github.com/twpayne/chezmoi/releases) |
| **Age** | `sudo apt install age` (en APT en Ubuntu/Debian) o [releases](https://github.com/FiloSottile/age/releases) |
| **SOPS** | `make install-sops` (opt-in, idempotente, sin sudo) o [releases](https://github.com/getsops/sops/releases). No está en APT de Ubuntu. |

> Chezmoi es el único gestor activo de dotfiles. RCM (`rcup`) ya no forma parte del bootstrap y no se instala desde aquí; las referencias históricas se conservan únicamente como contexto en `docs/CHEZMOI.md`.

---

## Secuencia recomendada (máquina nueva / PC empresa)

Flujo seguro y opt-in, sin sorpresas en máquinas corporativas:

```bash
# 1. Diagnóstico no-destructivo (puede salir PASS_WITH_WARNINGS, es normal)
make install-check

# 2. Dry-run del bootstrap completo (sin sudo, sin apt-get)
make install DRY_RUN=1

# 3. Bootstrap APT-only, sin dependencias externas
make install SKIP_EXTERNAL=1

# 4. Instaladores opt-in (uno por uno, idempotentes, soportan DRY_RUN=1)
make install-chezmoi # chezmoi (twpayne/chezmoi) en ~/.local/bin (sin Go, sin sudo)
make install-sops    # descarga sops oficial (getsops/sops v3.9.4) a ~/.local/bin
make install-node-stack  # Node.js LTS vía NodeSource (sudo/apt; requerido para MCPs npx)
make install-agent-tools # ast-grep, actionlint, osv-scanner (opt-in corporativo)
make install-uv      # uv (Astral) en ~/.local/bin
make install-zsh-stack   # Oh My Zsh + Powerlevel10k + plugins (no toca ~/.zshrc)
# zoxide (salto de directorios, reemplaza plugin OMZ z): make deps-install DEPS_INSTALL_ARGS=--include-optional
# fzf (fuzzy finder, integración shell en zsh/26-fzf.zsh), lnav (logs) y visidata/vd (CSV/JSON): make deps-install DEPS_INSTALL_ARGS=--include-optional
make install-fonts   # MesloLGS NF para Powerlevel10k en Linux/WSL (no configura Windows Terminal)
make install-mattpocock-skills # fallback externo opt-in: catálogo Matt completo
make install-git-hooks # hooks Git locales de este checkout; no forma parte de make install/update

# 5. Configurar rutas AI por máquina (vault Obsidian, workspace Excalidraw)
#    Editar ~/.config/chezmoi/chezmoi.toml (mínimo: obsidian_vault_path).
#    Si Excalidraw no vive en <vault>/excalidraw, añade excalidraw_workspace_host.
#        [data.ai]
#            obsidian_vault_path = "/ruta/real/del/vault"
#            excalidraw_workspace_host = "/ruta/real/excalidraw"   # opcional

# 6. Publicar dotfiles (chezmoi apply) — opt-in con DOTFILES_APPLY=1
#    Crea/actualiza también los symlinks ~/.zshrc, ~/.p10k.zsh y ~/.aliases.
#    Si esos ficheros existen con contenido custom, añade ZSH_RC_APPLY=1
#    para permitir backup con timestamp + reemplazo. Si solo hay un stub
#    trivial (vacío o `. "$HOME/.local/bin/env"`) el backup es automático.
make install-dotfiles DOTFILES_APPLY=1

# 7. Validar Cursor/MCPs/skills/commands (no-mutante)
make ai-cursor-check
```

> **DRY_RUN convention.** Usa `DRY_RUN=1` (con guion bajo). El instalador
> aborta fast con mensaje claro si pasas `DRY-RUN=1`, `dry-run=1`,
> `Dry-Run=1` o `DRYRUN=1`, para evitar instalaciones reales accidentales en
> bootstrap de máquina nueva.
>
> **Test/lint tooling.** `make install` instala también las herramientas de
> validación (`bats`, `shellcheck`, `shfmt`) vía APT para que `make test-fast`
> funcione sin pasos adicionales en una máquina nueva. Un preflight
> (`make test-deps-check`, integrado en `test-fast` / `test-bats` / `test`)
> falla rápido con mensaje accionable si alguna falta.
>
> **`make install-verify`.** Tras `make install`, comprueba versiones sin mutar.
> `zsh`, `git`, `age` y `rg` son requisitos base (`FAIL` si faltan).
> `chezmoi` y `sops` son opt-in: si no están instalados, el script emite `WARN`
> con el target correspondiente (`make install-chezmoi`, `make install-sops`)
> y no cuenta como `FAIL`. `STRICT=1` solo hace fallar el paso ante `FAIL`
> reales, no por herramientas opt-in ausentes.
> MesloLGS NF se verifica como `WARN` si falta; instálala con
> `make install-fonts`. Si los iconos se ven mal en Windows Terminal o VS Code,
> selecciona `MesloLGS NF` como fuente en la aplicación host.

### Hooks Git locales (opt-in)

`make install-git-hooks` configura únicamente este checkout con
`core.hooksPath=.githooks`. El pre-commit ejecuta `treegen` antes de cada commit;
si regenera `STRUCTURE.md`, stagea automáticamente solo ese fichero y deja
continuar el commit. No stagea otros cambios del workspace. El post-commit refresca GitNexus con
`--force --skip-agents-md`, incluso si detecta MCP/lock activo; tiene timeout de
30 segundos, es best-effort y nunca invalida el commit. Si falla o expira,
ejecuta manualmente `gitnexus analyze --force .`.

Escapes puntuales: `DOTFILES_SKIP_HOOKS=1`, `DOTFILES_SKIP_TREEGEN=1` y
`DOTFILES_SKIP_GITNEXUS=1`.

---

## Pasos

### 1. Clonar el repositorio

```bash
git clone https://github.com/jesuserro/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Configurar Age (para secretos cifrados)

```bash
mkdir -p ~/.config/sops/age
test -f ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Si `secrets.sops.yaml` ya viene cifrado en el repo, restaura/importa la clave privada Age correspondiente al recipient de `.sops.yaml`; no generes una clave nueva esperando descifrar el archivo actual. La clave privada queda en `~/.config/sops/age/keys.txt` y nunca se versiona.

Para rotar a otra clave, genera una nueva clave, actualiza `.sops.yaml` con su public key y re-encripta con `sops updatekeys secrets.sops.yaml`.

### 3. Crear secretos (opcional)

Si usas MCPs que requieren tokens (GitHub, Postgres, MinIO):

```bash
cd ~/dotfiles
sops secrets.sops.yaml
```

Añadir valores bajo `mcp:`. Ver [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md).

### 4. Aplicar dotfiles

```bash
make install-dotfiles DOTFILES_APPLY=1
```

Esto crea/actualiza también los symlinks `~/.zshrc`, `~/.p10k.zsh` y `~/.aliases` apuntando al repo. Si ya existen con contenido custom, ejecuta:

```bash
ZSH_RC_APPLY=1 make install-dotfiles DOTFILES_APPLY=1
```

para permitir backup con timestamp (`~/.zshrc.backup.YYYYMMDD-HHMMSS`) + reemplazo. Stubs triviales (vacíos o solo `. "$HOME/.local/bin/env"`) se respaldan automáticamente sin necesidad del flag.

### 5. Recargar la sesión

```bash
exec zsh -l
# o, en la sesión actual:
source ~/.zshrc
```

> El paso histórico `rcup -v` (RCM) ha sido retirado del flujo activo: Chezmoi gestiona ahora los RC files de la zsh stack.

### 6. (Opcional) Convertir zsh en la shell por defecto

`make install` y `make install-zsh-stack` no cambian la shell de login: esa es una decisión personal (cambia el comportamiento de Bash/WSL). Hay dos caminos, ambos opt-in:

**Camino preferido — `chsh` (persistente, vale para cualquier terminal):**

```bash
chsh -s "$(command -v zsh)"
# cierra y reabre la terminal
echo "$SHELL"          # debe imprimir .../zsh
ps -p $$ -o comm=      # debe imprimir zsh
```

Si `chsh` rechaza la shell con "non-standard", añade primero la ruta a `/etc/shells`:

```bash
echo "$(command -v zsh)" | sudo tee -a /etc/shells
```

**Fallback WSL — bloque idempotente en `~/.bashrc`** (sin `sudo`, útil cuando la terminal no respeta `/etc/passwd` o no quieres tocar `chsh`):

```bash
# >>> dotfiles zsh-fallback >>>
if [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
fi
# <<< dotfiles zsh-fallback <<<
```

**Helper opt-in del repo** que orquesta lo anterior con backups (no se ejecuta dentro de `make install`):

```bash
make set-default-shell-zsh                          # sólo informa, no muta
APPLY=1 make set-default-shell-zsh                  # ejecuta `chsh -s`
ZSH_BASHRC_FALLBACK=1 make set-default-shell-zsh    # añade el bloque a ~/.bashrc con backup
```

Soporta `DRY_RUN=1`, es idempotente y nunca usa `sudo`.

---

## Resumen en una línea

```bash
git clone https://github.com/jesuserro/dotfiles.git ~/dotfiles && \
cd ~/dotfiles && \
make install-dotfiles DOTFILES_APPLY=1 && \
exec zsh -l
```

*(Requiere Age, SOPS, Chezmoi y la zsh stack — `make install-zsh-stack` — instalados previamente.)*

---

## Verificación

```bash
# MCPs funcionan
~/.config/ai/runtime/.venv/bin/python -m trino_mcp --help

# Chezmoi status
chezmoi --source=$HOME/dotfiles status
```

Ver [GUIA_MCP_AI.md](GUIA_MCP_AI.md) para más comandos.

## Relacionado

| Doc | Uso |
|-----|-----|
| [OPERATIONS.md](OPERATIONS.md) | Flujos completos tras el bootstrap |
| [CHEZMOI.md](CHEZMOI.md) | Chezmoi, scripts, `ZSH_RC_APPLY` |
| [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md) | Dar de alta secretos |
