# Secretos: ejemplos prácticos

Cómo dar de alta o modificar secretos en `secrets.sops.yaml` (SOPS + Age).

---

## Estructura del archivo

`secrets.sops.yaml` tiene esta forma (los valores se cifran al guardar):

```yaml
mcp:
  github_personal_access_token: "ghp_xxxxxxxxxxxxxxxxxxxx"
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
     github_personal_access_token: "ghp_TuTokenRealAqui1234567890abcdef"
   ```

3. **Guardar y salir** (SOPS cifra automáticamente).

4. **Aplicar cambios:**

   ```bash
   chezmoi --source=$HOME/dotfiles apply
   ```

5. **Verificar:** el script post-apply genera `~/.config/store-etl/secrets.env` con `GITHUB_PERSONAL_ACCESS_TOKEN` y `GITHUB_TOKEN`.

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
   chezmoi --source=$HOME/dotfiles apply
   ```

5. **Verificar:** `~/.config/store-etl/secrets.env` contendrá `export POSTGRES_DSN="..."`.

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
   chezmoi --source=$HOME/dotfiles apply
   ```

4. **Resultado:** además de `secrets.env`, se crean `~/.secrets/store-etl/minio_access_key` y `minio_secret_key` para compatibilidad con docker-compose.

---

## Añadir un nuevo secreto (genérico)

Si quieres un secreto nuevo que el script aún no procesa:

1. **Editar** `secrets.sops.yaml` y añadir bajo `mcp:` (o nueva sección).
2. **Modificar** `.chezmoiscripts/run_after_00_gen_secrets.sh.tmpl` para que el script genere la variable correspondiente en `secrets.env`.
3. **Aplicar** con `chezmoi apply`.

---

## Resumen de comandos

| Acción | Comando |
|--------|---------|
| Editar secretos | `sops secrets.sops.yaml` |
| Aplicar tras editar | `chezmoi --source=$HOME/dotfiles apply` |
| Ver secretos (descifrado) | `sops -d secrets.sops.yaml` |

---

## Requisitos previos

- Age instalado y clave en `~/.config/sops/age/keys.txt`
- `.sops.yaml` configurado con tu public key
- Ver [CHEZMOI.md](CHEZMOI.md) para la configuración inicial.
