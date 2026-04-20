# Instalación

Guía paso a paso para configurar estos dotfiles en una máquina nueva.

---

## Requisitos previos

Para el inventario declarativo de paquetes base del sistema y su chequeo/instalación por `apt`, ver [SYSTEM_DEPENDENCIES.md](SYSTEM_DEPENDENCIES.md). Esta guía mantiene solo el flujo general de bootstrap.

| Herramienta | Instalación |
|-------------|-------------|
| **Chezmoi** | [Releases](https://github.com/twpayne/chezmoi/releases) o `go install github.com/twpayne/chezmoi/v2@latest` |
| **Age** | `sudo apt install age` o [releases](https://github.com/FiloSottile/age/releases) |
| **SOPS** | [Releases](https://github.com/getsops/sops/releases) |
| **RCM** | `sudo apt install rcm` (para zsh, tmux, vim) |

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
