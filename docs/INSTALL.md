# Instalación

Guía paso a paso para configurar estos dotfiles en una máquina nueva.

---

## Requisitos previos

Para el inventario declarativo de paquetes base del sistema y su chequeo/instalación por `apt`, ver [SYSTEM_DEPENDENCIES.md](SYSTEM_DEPENDENCIES.md). Esta guía mantiene solo el flujo general de bootstrap.

| Herramienta | Instalación |
|-------------|-------------|
| **Chezmoi** | [Releases](https://github.com/twpayne/chezmoi/releases) o `go install github.com/twpayne/chezmoi/v2@latest` |
| **Age** | `sudo apt install age` (en APT en Ubuntu/Debian) o [releases](https://github.com/FiloSottile/age/releases) |
| **SOPS** | `make install-sops` (opt-in, idempotente, sin sudo) o [releases](https://github.com/getsops/sops/releases). No está en APT de Ubuntu. |
| **RCM** | `sudo apt install rcm` (para zsh, tmux, vim) |

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
make install-sops    # descarga sops oficial (getsops/sops v3.9.4) a ~/.local/bin
make install-uv      # uv (Astral) en ~/.local/bin
make install-zsh-stack   # Oh My Zsh + Powerlevel10k + plugins (no toca ~/.zshrc)

# 5. Configurar la ruta real del vault de Obsidian (no se fuerza por defecto)
#    Editar ~/.config/chezmoi/chezmoi.toml:
#        [data.ai]
#            obsidian_vault_path = "/ruta/real/del/vault"

# 6. Publicar dotfiles (chezmoi apply) — opt-in con DOTFILES_APPLY=1
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
age-keygen -o ~/.config/sops/age/keys.txt
grep "public key:" ~/.config/sops/age/keys.txt
```

Copiar la public key y editar `~/.config/sops/age/keys.txt` en `.sops.yaml` del repo (reemplazar `AGE_PUBLIC_KEY_AQUI`).

### 3. Crear secretos (opcional)

Si usas MCPs que requieren tokens (GitHub, Postgres, MinIO):

```bash
cd ~/dotfiles
sops secrets.sops.yaml
```

Añadir valores bajo `mcp:`. Ver [SECRETS_EXAMPLES.md](SECRETS_EXAMPLES.md).

### 4. Aplicar dotfiles

```bash
chezmoi --source=$HOME/dotfiles apply
```

### 5. Aplicar RCM (zsh, tmux, vim)

```bash
rcup -v
source ~/.zshrc
```

---

## Resumen en una línea

```bash
git clone https://github.com/jesuserro/dotfiles.git ~/dotfiles && \
cd ~/dotfiles && \
chezmoi --source=$HOME/dotfiles apply && \
rcup -v && source ~/.zshrc
```

*(Requiere Age, SOPS y Chezmoi instalados previamente.)*

---

## Verificación

```bash
# MCPs funcionan
~/.config/ai/runtime/.venv/bin/python -m trino_mcp --help

# Chezmoi status
chezmoi --source=$HOME/dotfiles status
```

Ver [GUIA_MCP_AI.md](GUIA_MCP_AI.md) para más comandos.
