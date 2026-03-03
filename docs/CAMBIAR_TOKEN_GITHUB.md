# Cambiar el token de GitHub (PAT → classic ghp_)

Guía rápida para actualizar el token de GitHub en tus dotfiles (SOPS + Age + Chezmoi).

**Política:** Solo token classic (`ghp_`). El fine-grained (`github_pat_`) está deprecado (sin permisos de Projects).

---

## Resumen del flujo

1. **secrets.sops.yaml** — Archivo cifrado con SOPS que contiene el token.
2. **sops** — Herramienta que descifra/cifra el archivo usando tu clave Age.
3. **chezmoi apply** — Regenera `~/.config/store-etl/secrets.env` con el nuevo token.
4. **store-etl** — Usa `~/.secrets/codex.env` (symlink a `secrets.env`), así que verá el token nuevo tras aplicar.

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
  github_personal_access_token: "ghp_xxxxxxxxxxxxxxxxxxxx"   # ← token actual
  postgres_dsn: "..."
  minio_access_key: "..."
  minio_secret_key: "..."
```

### 2. Sustituir el token

Cambia el valor de `github_personal_access_token` por tu nuevo token classic (ghp_...):

```yaml
mcp:
  github_personal_access_token: "ghp_TuNuevoTokenClassicAqui..."
```

### 3. Guardar y salir

- **Vim**: `Esc` → `:wq` → `Enter`
- **Nano**: `Ctrl+O` → `Enter` → `Ctrl+X`

SOPS cifrará automáticamente el archivo al guardar.

### 4. Aplicar los cambios con Chezmoi

```bash
chezmoi --source=$HOME/dotfiles apply
```

Esto ejecutará el script post-apply que:
- Descifra `secrets.sops.yaml`
- Genera `~/.config/store-etl/secrets.env` con `GITHUB_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN` y `GH_TOKEN`
- Mantiene el symlink `~/.secrets/codex.env` → `~/.config/store-etl/secrets.env`

### 5. Verificar

```bash
# Ver que el archivo se generó correctamente (sin mostrar el token)
grep -q GITHUB_PERSONAL_ACCESS_TOKEN ~/.config/store-etl/secrets.env && echo "✅ Token configurado"

# store-etl usa ~/.secrets/codex.env (symlink)
readlink -f ~/.secrets/codex.env
# Debe mostrar: /home/jesus/.config/store-etl/secrets.env
```

---

## Requisitos previos

- **Age** instalado (`sudo apt install age` o desde [releases](https://github.com/FiloSottile/age/releases))
- **SOPS** instalado ([releases](https://github.com/getsops/sops/releases))
- Clave Age en `~/.config/sops/age/keys.txt` (la clave privada que corresponde a la public key en `.sops.yaml`)

Si `sops secrets.sops.yaml` falla con error de descifrado, verifica que la clave privada en `~/.config/sops/age/keys.txt` sea la correcta para `age1mq3cp26nx4tt7cqyf33004kkcc87g4nv4dlcw57l29xedue3s5gq4pzp4s`.

---

## Para store-etl

- **Cursor/Codex**: Al reiniciar Cursor o abrir el proyecto, cargará el nuevo token desde `~/.secrets/codex.env`.
- **Terminal**: Si tienes una sesión abierta, haz `source ~/.secrets/codex.env` para recargar las variables.
