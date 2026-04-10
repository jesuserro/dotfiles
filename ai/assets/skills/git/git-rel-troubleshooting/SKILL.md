---
name: git-rel-troubleshooting
description: Use when an agent must diagnose `git rel` incidents in WSL/Linux repos, especially `/mnt/c` vault or Obsidian repos with line-ending noise, `.gitattributes`, case mismatch, or filename-vs-regex hazards.
---

# Dotfiles Git Rel Troubleshooting

## When to Use

- Cuando `git rel` falla o parece colgarse antes del merge real.
- Cuando el repo objetivo vive en WSL/Linux, especialmente bajo `/mnt/c`.
- Cuando el repo parece tipo vault/Obsidian y hay ruido mecánico de `line endings`, `.gitattributes` o diferencias de casing.
- Cuando necesites distinguir si el problema está en `~/dotfiles/scripts/git_rel.sh` o en el repo que usa el comando.

## Typical Symptoms

- `grep: Invalid back reference`
- Lentitud extrema durante la verificación de conflictos
- Apariencia de cuelgue antes de `git merge`
- Conflictos inesperados en repos con rutas tipo `Projects` vs `projects`
- Cambios masivos por CRLF/LF o reglas de `.gitattributes`

## Quick Diagnosis

1. Confirmar alias y script reales:
   - `git config --get alias.rel`
   - `sed -n '1,220p' ~/dotfiles/scripts/git_rel.sh`
2. Confirmar que la incidencia ocurre antes o durante `git merge`.
3. Inspeccionar la zona sensible:
   - `rg -n 'check_potential_conflicts|grep -Fxq|target_modified_files' ~/dotfiles/scripts/git_rel.sh`
4. Medir si el coste viene de los diffs:
   - `time git diff --name-only "main...dev" >/dev/null`
   - `time git diff --name-only "dev...main" >/dev/null`
5. Revisar si el repo ya está “sucio” por factores mecánicos:
   - `git status --short`
   - `git check-attr --all -- .`

## Script vs Target Repo

Trata primero como problema del script si:

- aparece `Invalid back reference`
- la latencia ocurre en `check_potential_conflicts()`
- el fallo sucede antes del merge real
- el síntoma se reproduce en más de un repo

Trata primero como problema del repo objetivo si:

- el fallo aparece durante `git merge` o después
- hay CRLF/LF mezclados o reglas de `.gitattributes` relevantes
- hay rutas que difieren solo por mayúsculas/minúsculas
- `git diff`, `git status` o `git merge` ya fallan sin usar `git rel`

## WSL Vault Heuristics

- Si el repo está en `/mnt/c`, sospecha primero de casing y `line endings`.
- En vaults/Obsidian, sospecha ruido mecánico antes que lógica del script si hay renames, carpetas manuales o sync externo.
- Si `git status` muestra muchas rutas sucias pero `git diff` y `git diff --cached` están vacíos o casi vacíos, sospecha primero de `line endings`, normalización de texto, case mismatch o ruido mecánico del repo antes de concluir que hay cambios semánticos reales.
- Si ves `Projects` y `projects`, en Linux/WSL eso es distinto aunque en Windows el historial del repo venga contaminado.
- Si el diff explota en muchos archivos Markdown o metadatos, inspecciona `.gitattributes` antes de culpar al merge helper.
- Si el error es exactamente `Invalid back reference`, eso apunta al tratamiento del nombre de archivo como regex y no al vault.

## Safe Actions

- Validar sintaxis del script:
  - `bash -n ~/dotfiles/scripts/git_rel.sh`
- Ejecutar ayuda o traza corta:
  - `bash ~/dotfiles/scripts/git_rel.sh --help`
  - `bash -x ~/dotfiles/scripts/git_rel.sh --help`
- Inspeccionar diffs de ramas sin modificar nada:
  - `git diff --name-only "main...dev"`
  - `git diff --name-only "dev...main"`
- Revisar config de Git relevante:
  - `git config --show-origin --get-regexp 'core.autocrlf|core.ignorecase|merge.ff'`

## Avoid

- No diagnosticar solo desde documentación antigua; comprobar siempre alias y script reales.
- No asumir que un conflicto en vault/Obsidian es culpa de `git rel`.
- No reintroducir regex con nombres de archivo en `check_potential_conflicts()`.
- No recalcular `git diff --name-only ...` dentro del bucle.
- No concluir que “está colgado” sin medir primero el tiempo de los diffs.

## Minimum Commands

```bash
git config --get alias.rel
bash -n ~/dotfiles/scripts/git_rel.sh
rg -n 'check_potential_conflicts|grep -Fxq|target_modified_files' ~/dotfiles/scripts/git_rel.sh
git status --short
git diff --name-only "main...dev"
git diff --name-only "dev...main"
git config --show-origin --get-regexp 'core.autocrlf|core.ignorecase|merge.ff'
git check-attr --all -- .
```

## Known Limits

- El bucle actual basado en `for file in $modified_files` no soporta bien nombres con espacios, tabs o saltos de línea.
- La detección de conflictos potenciales es heurística; no sustituye un merge real.
- Esta skill no resuelve por sí misma problemas de `.gitattributes`, CRLF/LF o casing del repo objetivo.

## Extended Reference

- Nota humana ampliada: `/home/jesus/dotfiles/docs/GIT_REL_INCIDENT.md`
