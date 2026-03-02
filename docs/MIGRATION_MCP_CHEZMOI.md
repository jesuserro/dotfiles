# Migración MCP a Chezmoi + SOPS + Age

Este documento describe la migración de la gestión de MCPs (Cursor/Codex) a **Chezmoi** con secretos cifrados con **SOPS** y **Age**, manteniendo **rcup** para el resto de dotfiles.

## Restricciones

- **NO** se ha tocado rcup, zsh, tmux, vim, git.
- **Solo** se gestionan con Chezmoi:
  - `~/.cursor/mcp.json` (MCPs globales: excalidraw, context7, docker, github, fetch)
  - `~/.codex/config.toml`
  - Symlink `~/.secrets/codex.env` → `~/.config/store-etl/secrets.env`
- Los servidores MCP Python están en `~/dotfiles/mcp/servers/**`; runtime en `~/.config/mcp/`.
- Secreto canónico: `~/.config/store-etl/secrets.env` (generado desde `secrets.sops.yaml`).

---

## Requisitos

- **Chezmoi**: instalado en `~/dotfiles/bin/chezmoi` (o en PATH).
- **Age**: para claves de cifrado.
- **SOPS**: para cifrar `secrets.sops.yaml`.
- **yq** o **python3 + PyYAML**: para que el script genere `secrets.env` desde SOPS.

### Instalación de Age y SOPS (si no están)

```bash
# Age (binario oficial si no está en apt)
sudo apt install -y age
# o: https://github.com/FiloSottile/age/releases

# SOPS (binario oficial)
# https://github.com/getsops/sops/releases
# Ejemplo: curl -LO https://github.com/getsops/sops/releases/download/v3.12.1/sops-v3.12.1.linux.amd64 && mv sops-v3.12.1.linux.amd64 ~/bin/sops && chmod +x ~/bin/sops
```

---

## Uso de Chezmoi

Siempre usar el repo dotfiles como source:

```bash
export PATH="$HOME/dotfiles/bin:$PATH"   # si chezmoi está en dotfiles/bin
chezmoi --source=/home/jesus/dotfiles status
chezmoi --source=/home/jesus/dotfiles apply
```

O configurar el source por defecto en `~/.config/chezmoi/chezmoi.toml`:

```toml
[source]
    path = "/home/jesus/dotfiles"
```

Luego:

```bash
chezmoi status
chezmoi apply
```

---

## Configuración de Age + SOPS (una vez)

1. **Generar clave Age**

   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   grep "public key:" ~/.config/sops/age/keys.txt
   ```

2. **Editar `.sops.yaml`** en el repo dotfiles: reemplazar `AGE_PUBLIC_KEY_AQUI` por la public key obtenida.

3. **Cifrar secretos**

   ```bash
   cd ~/dotfiles
   sops secrets.sops.yaml
   ```

   Rellenar los valores reales en el YAML y guardar (SOPS cifrará al salir).

4. **Aplicar**

   ```bash
   chezmoi --source=/home/jesus/dotfiles apply
   ```

   Se generará `~/.config/store-etl/secrets.env` desde `secrets.sops.yaml` y el symlink `~/.secrets/codex.env` apuntará a ese archivo.

---

## Estructura de secretos

- **`secrets.sops.yaml`** (en el repo, cifrado): contiene `mcp.github_personal_access_token`, `mcp.postgres_dsn`, `mcp.minio_access_key`, `mcp.minio_secret_key`.
- **`~/.config/store-etl/secrets.env`**: generado por el script de Chezmoi al hacer `apply` (desencriptando con SOPS). No versionar.
- **`~/.secrets/codex.env`**: symlink a `~/.config/store-etl/secrets.env` para compatibilidad con Codex/Cursor.

---

## MCPs globales vs proyecto Store ETL

- **Global** (`~/.cursor/mcp.json`): excalidraw, context7, docker, github, fetch. Cualquier repo solo ve estos.
- **Store ETL** (`/home/jesus/proyectos/store-etl/.cursor/mcp.json`): postgres, trino, dagster, minio, tempo, loki, prometheus, store_etl_ops. Solo al abrir Cursor en ese proyecto.

---

## Validación

1. `chezmoi --source=$HOME/dotfiles apply`
2. Abrir Cursor en otro repo → solo MCP global.
3. Abrir Cursor en store-etl → MCPs específicos del proyecto.
4. Comprobar: GitHub MCP, Postgres MCP, MinIO MCP, Dagster.

---

## No hacer

- `~/.codex/mcp` es symlink a `~/.config/mcp`; postgres/trino/docker siguen ahí (runtime).
- No eliminar rcup.
- No tocar zsh, tmux, vim.
- No mover los servidores MCP de dotfiles.
