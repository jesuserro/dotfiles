# Secretos: ejemplos prácticos

Cómo dar de alta o modificar secretos en `secrets.sops.yaml` (SOPS + Age).

**Token GitHub y `gh` CLI:** Ver [TOKEN_GITHUB_GH.md](TOKEN_GITHUB_GH.md) — prioridad del token classic para Projects.

---

## Estructura del archivo

`secrets.sops.yaml` tiene esta forma (los valores se cifran al guardar):

```yaml
mcp:
  github_personal_access_token: "<github-classic-token>"
  postgres_dsn: "postgresql://user:password@localhost:5432/mydb"
  minio_access_key: "minioadmin"
  minio_secret_key: "minioadmin"
```

---

## Dar de alta un token de GitHub

1. **Editar el archivo cifrado:**

   ```bash
   cd ~/dotfiles
   sops secrets.sops.yaml
   ```

2. **Añadir o modificar la clave** bajo `mcp:`:

   ```yaml
   mcp:
     github_personal_access_token: "<github-classic-token>"
   ```

3. **Guardar y salir** (SOPS cifra automáticamente).

4. **Aplicar cambios:**

   ```bash
   make install-dotfiles DOTFILES_APPLY=1
   ```

5. **Verificar:** el script post-apply genera `~/.config/mcp-secrets.env` con `GITHUB_PERSONAL_ACCESS_TOKEN` y `GITHUB_TOKEN`; `~/.secrets/codex.env` queda como adaptador de compatibilidad.
   **Token:** solo classic (`ghp_`), fine-grained deprecado. Ver [TOKEN_GITHUB_GH.md](TOKEN_GITHUB_GH.md).

---

## Dar de alta la DSN de Postgres

1. **Editar:**

   ```bash
   sops secrets.sops.yaml
   ```

2. **Añadir o modificar:**

   ```yaml
   mcp:
     postgres_dsn: "postgresql://usuario:contraseña@localhost:5432/nombre_db"
   ```

   Ejemplo con parámetros extra:

   ```yaml
   postgres_dsn: "postgresql://jesus:secret@192.168.1.10:5432/store_etl?sslmode=disable"
   ```

3. **Guardar** (Ctrl+O, Enter, Ctrl+X en el editor por defecto).

4. **Aplicar:**

   ```bash
   make install-dotfiles DOTFILES_APPLY=1
   ```

5. **Verificar sin mostrar valores** (la línea debe tener contenido tras `=`):

   ```bash
   grep -E '^export POSTGRES_DSN=.' ~/.config/mcp-secrets.env && echo OK
   ```

   `grep -q '^export POSTGRES_DSN='` solo comprueba que existe la clave; **no** detecta DSN vacío.

---

## Valores vacíos en YAML

Si una clave en `secrets.sops.yaml` está vacía o ausente, el script post-apply genera igualmente la variable:

```bash
export POSTGRES_DSN=""
```

- **Postgres MCP:** con DSN vacío, Cursor/Codex reportan `POSTGRES_DSN not set` — es secreto vacío, no contenedor apagado.
- **No edites** `~/.config/mcp-secrets.env` a mano; siempre `sops` + `chezmoi apply -i scripts`.
- **No uses** `sops -d secrets.sops.yaml` en terminal (imprime secretos). Usa `sops secrets.sops.yaml`.

---

## Dar de alta claves MinIO (S3)

1. **Editar:**

   ```bash
   sops secrets.sops.yaml
   ```

2. **Añadir o modificar:**

   ```yaml
   mcp:
     minio_access_key: "tu_access_key"
     minio_secret_key: "tu_secret_key"
   ```

3. **Guardar y aplicar:**

   ```bash
   make install-dotfiles DOTFILES_APPLY=1
   ```

4. **Resultado:** además del archivo canonico `~/.config/mcp-secrets.env`, se crean `~/.secrets/store-etl/minio_access_key` y `minio_secret_key` para compatibilidad con docker-compose.

---

## Añadir un nuevo secreto (genérico)

Si quieres un secreto nuevo que el script aún no procesa:

1. **Editar** `secrets.sops.yaml` y añadir bajo `mcp:` (o nueva sección).
2. **Modificar** `.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl` para que el script genere la variable correspondiente en `~/.config/mcp-secrets.env`.
3. **Aplicar** con `make install-dotfiles DOTFILES_APPLY=1`.

---

## Resumen de comandos

| Acción | Comando |
|--------|---------|
| Editar secretos | `sops secrets.sops.yaml` |
| Aplicar tras editar | `make install-dotfiles DOTFILES_APPLY=1` |
| Validar sin mostrar valores | `grep -E '^export GITHUB_PERSONAL_ACCESS_TOKEN=.' ~/.config/mcp-secrets.env` |
| Validar Postgres (no vacío) | `grep -E '^export POSTGRES_DSN=.' ~/.config/mcp-secrets.env` |
| Listar solo nombres de vars | `cut -d= -f1 ~/.config/mcp-secrets.env \| sort` |

---

## Requisitos previos

- Age instalado y clave en `~/.config/sops/age/keys.txt`
- `.sops.yaml` configurado con tu public key
- Ver [CHEZMOI.md](CHEZMOI.md) para la configuración inicial.

No pegues tokens en chat y evita `sops -d secrets.sops.yaml` en terminal como flujo normal; usa `sops secrets.sops.yaml`, que abre el editor y vuelve a cifrar al guardar.
