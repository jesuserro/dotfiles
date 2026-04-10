# `git rel`: incidencia real y mantenimiento operativo

Nota breve para mantenimiento humano y agentes sobre el comando `git rel`, con foco en la incidencia corregida en `check_potential_conflicts()` y en el debugging rápido del comando en WSL/Linux.

## Qué hace

`git rel` automatiza el release de `dev` a `main` y crea un tag de versión. Antes del merge valida el repo, revisa conflictos potenciales y después hace `push` de la rama objetivo y del tag.

## Dónde vive realmente

Fuente de verdad en este repo:

- Alias Git: [`gitconfig`](/home/jesus/dotfiles/gitconfig)
- Script ejecutado por el alias: [`scripts/git_rel.sh`](/home/jesus/dotfiles/scripts/git_rel.sh)

Alias actual:

```ini
[alias]
  rel = "!bash ~/dotfiles/scripts/git_rel.sh"
```

Implicaciones operativas:

- En WSL/Linux se ejecuta con `bash` desde `~/dotfiles/scripts/git_rel.sh`.
- Para depurar el comportamiento real, usa el script y el alias anterior como referencia, no resúmenes antiguos en otra documentación.
- El bit ejecutable del script no es crítico para el alias actual porque Git invoca `bash` explícitamente.

## Incidencia corregida

Durante un release real de `dev` a `main` aparecieron dos fallos en `check_potential_conflicts()`.

### 1. `grep: Invalid back reference`

Qué falló:

- El script comparaba nombres de archivo usando `grep` con una expresión regular construida a partir del propio nombre de archivo.

Causa técnica:

- Un path de archivo no es seguro como regex.
- Si el nombre contiene secuencias interpretables por `grep` como backreferences o metacaracteres, `grep` intenta evaluarlas y falla con `Invalid back reference`.

Parche mínimo aplicado:

```bash
printf '%s\n' "$target_modified_files" | grep -Fxq -- "$file"
```

Por qué corrige el problema:

- `-F` fuerza coincidencia literal, no regex.
- `-x` exige coincidencia de línea completa.
- `-q` evita ruido en stdout.
- `--` blinda el nombre de archivo aunque empiece por `-`.

### 2. Lentitud extrema o apariencia de cuelgue

Qué falló:

- El script recalculaba `git diff --name-only "$source_branch...$target_branch"` dentro del bucle que iteraba los archivos de la otra rama.

Causa técnica:

- El mismo diff se ejecutaba una vez por cada archivo.
- En repos grandes o con muchos cambios, el coste crecía innecesariamente y la ejecución parecía quedarse colgada.

Parche mínimo aplicado:

- Calcular la lista de archivos modificados en target una sola vez.
- Reutilizar esa lista cacheada dentro del bucle.

Patrón correcto:

```bash
local modified_files=$(git diff --name-only "$target_branch...$source_branch" 2>/dev/null || echo "")
local target_modified_files=$(git diff --name-only "$source_branch...$target_branch" 2>/dev/null || echo "")

for file in $modified_files; do
  if printf '%s\n' "$target_modified_files" | grep -Fxq -- "$file"; then
    potential_conflicts+=("$file")
  fi
done
```

## Limitaciones fuera de alcance

Estas no quedaron resueltas con este parche y conviene tenerlas presentes:

- El bucle `for file in $modified_files` separa por whitespace. Nombres de archivo con espacios, tabs o saltos de línea no están bien soportados en esa ruta.
- La detección de conflictos potenciales es heurística. Detecta archivos tocados en ambas ramas, no garantiza que el merge vaya a fallar ni que vaya a ser limpio.
- Problemas de `line endings`, `.gitattributes` o colisiones de mayúsculas/minúsculas como `Projects` vs `projects` pertenecen al repositorio objetivo, no al script en sí.

## Validación rápida

Comprobaciones mínimas para verificar el comando sin recontar toda la lógica:

```bash
git config --get alias.rel
bash ~/dotfiles/scripts/git_rel.sh --help
bash -n ~/dotfiles/scripts/git_rel.sh
```

Para validar la zona corregida:

```bash
rg -n 'check_potential_conflicts|grep -Fxq|target_modified_files' /home/jesus/dotfiles/scripts/git_rel.sh
```

Si quieres ver la ejecución paso a paso:

```bash
bash -x ~/dotfiles/scripts/git_rel.sh --help
```

## Cómo distinguir script vs repo objetivo

Suele ser problema del script si:

- aparece `grep: Invalid back reference`
- la lentitud ocurre antes del merge real, durante la fase de chequeo de conflictos
- el mismo síntoma se reproduce en distintos repos con estructura similar

Suele ser problema del repo objetivo si:

- el merge falla por contenido real, conflictos de fin de línea o reglas de `.gitattributes`
- hay diferencias de casing entre rutas en un entorno case-sensitive como Linux/WSL
- `git diff`, `git status` o `git merge` ya muestran anomalías sin pasar por `git rel`

Regla práctica:

- Si falla antes de `git merge`, inspecciona primero el script.
- Si falla durante o después de `git merge`, inspecciona primero el estado y la configuración del repo objetivo.

## Comandos útiles de diagnóstico

Alias y script reales:

```bash
git config --get alias.rel
sed -n '1,220p' ~/dotfiles/scripts/git_rel.sh
```

Inspección de la fase de conflictos:

```bash
source_branch=dev
target_branch=main
git diff --name-only "$target_branch...$source_branch"
git diff --name-only "$source_branch...$target_branch"
```

Perfil rápido de la zona sospechosa:

```bash
time git diff --name-only "main...dev" >/dev/null
time git diff --name-only "dev...main" >/dev/null
```

Estado del repo objetivo:

```bash
git status --short
git config --show-origin --get-regexp 'core.autocrlf|core.filemode|merge.ff'
git check-attr --all -- .
```

Caso WSL/Linux:

```bash
uname -a
git config --show-origin --get core.ignorecase
```

## Mantenimiento futuro

Si vuelve a tocarse `check_potential_conflicts()`:

- no interpolar nombres de archivo en regex
- no recalcular `git diff` dentro del bucle
- preferir comparaciones literales y listas precalculadas
- si se quiere soportar espacios en nombres de archivo, rehacer el bucle con separadores nulos
