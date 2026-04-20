---
name: wsl2-local-tools
description: Guía breve para usar herramientas locales de WSL2 al inspeccionar proyectos, Docker y conectividad.
---

# Dotfiles WSL2 Local Tools

## When to Use
- Cuando necesites inspeccionar rápidamente la estructura de un proyecto (por ejemplo con `tree`) o encontrar archivos/fragmentos de texto (por ejemplo con `fdfind` y `rg`).
- Cuando necesites inspeccionar el estado y/o networking de servicios locales en Docker, especialmente para comprobar salud de Postgres con `docker inspect` + `jq`.
- Cuando quieras diagnosticar problemas de conectividad (por ejemplo con `nc`).

## Guidelines
- Usa `rg` y `fdfind` antes que búsquedas manuales lentas.
- Para estructura, usa `tree -L <N>` para no inundar la salida.
- Para Docker + JSON, encadena `docker inspect ... | jq ...` y filtra estrictamente el campo que te interesa (salud, IP interna, etc.).
- Para tooling Python de calidad (por ejemplo `ruff`), prefiere ejecutar el binario con el entorno del proyecto (regla general: `uv run ...`), no con venvs externos.

## Checklist
- [ ] Ejecuté `tree -L 2 .` (o el path del proyecto) si necesito un mapa rápido.
- [ ] Busqué lo relevante con `rg` si busco texto/ocurrencias.
- [ ] Localicé archivos con `fdfind` si necesito rutas concretas.
- [ ] Si el problema involucra Docker, verifiqué salud y/o IP interna con `docker inspect ... | jq ...`.
- [ ] No imprimí secretos en logs ni incluí rutas/credenciales sensibles.

## Examples
### Estructura de proyecto (limitada a 2 niveles)
- `tree -L 2 .`

### Búsqueda de texto rápida
- `rg "Health.Status" .`
- `rg --files "Dockerfile|docker-compose"` .`

### Localización de archivos
- `fdfind -i "docker-compose" .`

### Salud de Postgres en Docker (container `postgres`)
- `docker inspect postgres | jq -r '.[0].State.Health.Status // "no-health"'`

### IP interna del contenedor (por redes Docker)
- `docker inspect postgres | jq -r '.[0].NetworkSettings.Networks | to_entries[] | "\(.key): \(.value.IPAddress)"'`

### Conectividad básica (puerto)
- `nc -vz <host> <port>`

### Ruff desde el entorno del proyecto con uv (regla general)
- `uv run --group dev --no-sync ruff check .`

## Best Practices
- Mantén el output corto usando `tree -L`, `jq -r` y filtros específicos.
- Cuando inspecciones Docker, confirma el *container name* correcto (por ejemplo `postgres`) antes de interpretar resultados.
- Evita dependencia de entornos “globales” (como venv de otro repo). Usa el entorno del proyecto cuando sea posible.

## Quality Checklist
- El comando usa herramientas locales rápidas (`rg`, `fdfind`, `tree`, `jq`, `nc`).
- Los ejemplos no contienen secretos.
- Los ejemplos Docker usan `jq` para extraer solo campos relevantes.
