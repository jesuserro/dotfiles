# Plans y notepads: nombres con prefijo cronológico

Convención de nombres para archivos de plan y documentos de trabajo bajo `.cursor/plans/` (y equivalentes), para ordenarlos por tiempo y evitar nombres genéricos.

## When to Use

- Crear un nuevo archivo de **plan** (`.plan.md`) en `.cursor/plans/`
- El IDE o la UI sugieren un nombre genérico para un plan: **sustituirlo** por el formato cronológico
- Documentar o revisar la convención en un proyecto que use Cursor / agentes

## Guidelines

### Reglas de gestión de archivos (Plans)

1. **Directorio:** `.cursor/plans/`
2. **Formato obligatorio del nombre de fichero:**

   `YYYY-MM-DD-HHmm_nombre_descriptivo.plan.md`

   - **Fecha y hora (prefijo):** `YYYY-MM-DD-HHmm` en hora local (24 h), sin separador entre fecha y hora más allá de los guiones ya indicados (ej. `2026-03-22-1300`).
   - **Parte descriptiva:** `snake_case`, en minúsculas, separada del prefijo temporal con **un guion bajo** `_`.
   - **Extensión:** `.plan.md`

3. **No usar** el nombre genérico que propone la interfaz al generar un plan: renombrar de inmediato al formato anterior.
4. **Separadores:** guiones `-` en la porción de fecha/hora; guiones bajos `_` entre el prefijo temporal y el slug descriptivo, y dentro del slug.
5. **Opcional:** un sufijo corto de unicidad (ej. hash o id) al final del slug si hace falta evitar colisiones en el mismo minuto:  
   `2026-03-22-1300_dimbook_path_isolation_d034755c.plan.md`

### Notepads

Si creas notas de trabajo en el mismo ámbito (p. ej. documentos auxiliares junto a planes), puedes reutilizar el **mismo prefijo cronológico** y una extensión o sufijo claro (p. ej. `.md`) para mantener coherencia; la regla estricta aplica sobre todo a `.cursor/plans/*.plan.md`.

## Examples

| Situación | Nombre correcto |
|-----------|-----------------|
| 22 mar 2026, 13:00, tema dimbook | `2026-03-22-1300_dimbook_path_isolation.plan.md` |
| Mismo minuto, evitar colisión | `2026-03-22-1300_dimbook_path_isolation_d034755c.plan.md` |
| Incorrecto (genérico UI) | `plan.md`, `cursor-plan-123.plan.md` |

## Checklist

- [ ] Prefijo `YYYY-MM-DD-HHmm` con hora local de 24 h
- [ ] Un `_` entre prefijo y `nombre_descriptivo`
- [ ] Sufijo de archivo `.plan.md`
- [ ] Nombre descriptivo en `snake_case`, no un título vacío o genérico

## Best Practices

- Generar el prefijo con la hora **en el momento de crear** el archivo (no reutilizar una plantilla antigua sin actualizar fecha/hora).
- Mantener el slug descriptivo **corto pero único** (tema + alcance o ticket).
- Si mueves o duplicas un plan, **actualiza** el prefijo temporal solo si representa un documento nuevo; si es el mismo plan, conserva el nombre para no romper enlaces.

## Quality Checklist

- [ ] El archivo vive bajo `.cursor/plans/` (salvo que el proyecto defina otra ruta explícita)
- [ ] El nombre cumple el patrón `YYYY-MM-DD-HHmm_* .plan.md`
- [ ] No queda ningún nombre tipo `plan` / `untitled` / sugerencia por defecto sin renombrar
