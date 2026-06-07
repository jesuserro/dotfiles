# Cambiar el token de GitHub (PAT → classic ghp_)

Guía rápida para actualizar el token de GitHub en tus dotfiles (SOPS + Age + Chezmoi).

**Política:** Solo token classic (`ghp_`). El fine-grained (`github_pat_`) está deprecado (sin permisos de Projects).

---

## Resumen del flujo

1. **secrets.sops.yaml** — Archivo cifrado con SOPS que contiene el token.
2. **sops** — Herramienta que descifra/cifra el archivo usando tu clave Age.
3. **make install-dotfiles DOTFILES_APPLY=1** — Regenera `~/.config/mcp-secrets.env` con el nuevo token.
4. **Compatibilidad** — `~/.secrets/codex.env` apunta al archivo canonico para wrappers antiguos.

---

## Pasos

### 1. Editar el archivo cifrado

```bash
cd ~/dotfiles
sops secrets.sops.yaml
```

Se abrirá tu editor (por defecto vim/nano) con el contenido **descifrado**. Verás algo como:

```yaml
mcp:
  github_personal_access_token: "<github-classic-token>"
  postgres_dsn: "..."
  minio_access_key: "..."
  minio_secret_key: "..."
```

### 2. Sustituir el token

Cambia el valor de `github_personal_access_token` por tu nuevo token classic:

```yaml
mcp:
  github_personal_access_token: "<github-classic-token>"
```

### 3. Guardar y salir

- **Vim**: `Esc` → `:wq` → `Enter`
- **Nano**: `Ctrl+O` → `Enter` → `Ctrl+X`

SOPS cifrará automáticamente el archivo al guardar.

### 4. Aplicar los cambios con Chezmoi

```bash
make install-dotfiles DOTFILES_APPLY=1
```

Esto ejecutará el script post-apply que:
- Descifra `secrets.sops.yaml`
- Genera `~/.config/mcp-secrets.env` con `GITHUB_PERSONAL_ACCESS_TOKEN` (para MCP/wrappers)
- Mantiene `~/.secrets/codex.env` como adaptador hacia `~/.config/mcp-secrets.env`
- Puede mantener `~/.config/store-etl/secrets.env` solo como compatibilidad legacy
- **No** exporta `GH_TOKEN` ni `GITHUB_TOKEN` (evita anular `gh auth switch`)

### 5. Verificar

```bash
# Ver que el archivo se generó correctamente (sin mostrar el token)
grep -q '^export GITHUB_PERSONAL_ACCESS_TOKEN=' ~/.config/mcp-secrets.env && echo "Token configurado"

readlink -f ~/.secrets/codex.env
# Debe resolver a: /home/jesus/.config/mcp-secrets.env
```

---

## Requisitos previos

- **Age** instalado (`sudo apt install age` o desde [releases](https://github.com/FiloSottile/age/releases))
- **SOPS** instalado ([releases](https://github.com/getsops/sops/releases))
- Clave Age en `~/.config/sops/age/keys.txt` (la clave privada que corresponde a la public key en `.sops.yaml`)

Si `sops secrets.sops.yaml` falla con error de descifrado, verifica que la clave privada en `~/.config/sops/age/keys.txt` corresponda al recipient Age declarado en `.sops.yaml`. En una maquina nueva con `secrets.sops.yaml` ya cifrado, restaura/importa esa clave privada; no generes una nueva esperando descifrar el archivo actual.

---

## Para store-etl

- **Cursor/Codex**: Al reiniciar Cursor o abrir el proyecto, el wrapper MCP GitHub cargará el token desde `~/.config/mcp-secrets.env` (vía `~/.secrets/codex.env`).
- **Terminal (`gh`)**: Usa `gh auth switch --user jesuserro` (casa) o `gh auth switch --user jesus-ixatu` (oficina). Abre shell nueva tras apply. Ver [TOKEN_GITHUB_GH.md](TOKEN_GITHUB_GH.md).
