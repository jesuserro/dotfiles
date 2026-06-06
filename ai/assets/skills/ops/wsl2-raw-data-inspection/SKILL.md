---
name: wsl2-raw-data-inspection
description: Inspección segura y reproducible de datos raw/locales (CSV, JSON, JSONL, logs) para agentes en WSL2. Prioriza python3 y jq; evita PII, TUI sin TTY y volcados masivos.
---

# Dotfiles WSL2 Raw Data Inspection

Guía operativa para que agentes perfilen ficheros raw o locales de proyectos ETL **sin modificar datos**, **sin volcar PII** y **sin depender de TUI interactiva**.

Complementa [`wsl2-local-tools`](../wsl2-local-tools/SKILL.md) (proyecto, Docker, conectividad). Esta skill es específica para **datos tabulares y logs**.

## When to Use

- Inspeccionar ficheros raw/locales antes de escribir o depurar pipelines ETL.
- Entender estructura de CSV, TSV, JSON, JSONL o logs sin abrir el dataset completo.
- Perfilizar columnas, filas, tamaños, claves o delimitadores de forma reproducible.
- Revisar exports de Goodreads, OpenLibrary, Readwise, Kindle u otras fuentes en `data/raw`.
- Diagnosticar datos o comparar dos exports (conteos, headers) antes de cargar a PostgreSQL u otro destino.
- Preparar una respuesta al usuario sin exponer reviews, notas privadas, emails ni tokens.

## Safety Rules

- **No modificar** datos raw: no borrar, mover, reescribir ni ejecutar pipelines ETL desde esta skill.
- **No imprimir filas completas** si pueden contener PII (reviews, notas, emails, tokens).
- **No volcar** columnas sensibles: p. ej. `My Review`, `Private Notes`, campos de notas personales o credenciales.
- **No usar** `vd -b` sin `-o`; el batch sin archivo de salida vuelca el dataset entero a stdout.
- **No abrir** ficheros grandes en TUI sin revisar tamaño primero (umbral orientativo: > 5 MB o > 50k líneas → solo conteos/header).
- **No usar** TUI interactiva (`vd`, `lnav` sin `-n`) en agentes sin TTY.
- Preferir **headers, conteos, esquemas y muestras acotadas** frente a dumps completos.
- Escribir muestras temporales **solo en `/tmp`** y documentar qué archivo se creó.
- Usar rutas con comillas si hay espacios en nombres de fichero.

## Guidelines

1. **Descubrir** tamaños y extensiones antes de abrir contenido.
2. **CSV:** `file`, `wc -l`, `head -1` (solo header), perfil con `python3` + `csv`.
3. **JSON:** `jq` para tipo, claves y campos anidados; evitar `cat` del fichero entero.
4. **JSONL:** Python línea a línea (muestra de N líneas), no `jq` monolítico sobre el archivo completo.
5. **Logs:** `head`, `rg`, o `lnav -n` (headless); no `lnav` interactivo sin TTY.
6. **VisiData (`vd`):** secundario — humano en terminal o `vd -b -o /tmp/...` con revisión previa de columnas.
7. **No asumir** Parquet, DuckDB ni SQL local; el paquete APT de VisiData no garantiza Parquet.

## Discovery

Sustituye `<project>` por la raíz del repo ETL (p. ej. un proyecto con layout `data/raw/`).

```bash
RAW="<project>/data/raw"

test -d "$RAW" && echo "raw_exists=yes" || echo "raw_exists=no"

find "$RAW" -type f ! -name '.gitkeep' -printf '%s\t%p\n' | sort -n

du -sh "$RAW"

find "$RAW" -type f | awk '
  {
    n=$0
    sub(/^.*\//,"",n)
    if (n ~ /\./) {
      ext=n
      sub(/^.*\./,"",ext)
      print tolower(ext)
    } else {
      print "[no_ext]"
    }
  }
' | sort | uniq -c | sort -nr | head -30
```

Localizar candidatos:

```bash
find "$RAW" -type f ! -name '.gitkeep'
fdfind -e csv . "$RAW"    # binario Debian: fdfind
rg --files -g '*.csv' "$RAW"
rg --files -g '*.json' "$RAW"
```

## Examples

### CSV inspection (safe)

`head -1` es aceptable para el header. **No uses** `head -20` en CSV con columnas de reviews o notas privadas.

```bash
CSV="<project>/data/raw/<source>/<file>.csv"

file "$CSV"
wc -l "$CSV"
head -1 "$CSV"

python3 - "$CSV" <<'PY'
import csv
import sys
from pathlib import Path

path = Path(sys.argv[1])
with path.open("r", encoding="utf-8", errors="replace", newline="") as f:
    sample = f.read(8192)
    f.seek(0)
    try:
        dialect = csv.Sniffer().sniff(sample)
    except csv.Error:
        dialect = csv.excel

    reader = csv.reader(f, dialect)
    header = next(reader, [])
    rows = sum(1 for _ in reader)

print(f"path={path}")
print(f"delimiter={repr(getattr(dialect, 'delimiter', ','))}")
print(f"columns={len(header)}")
print("header=" + repr(header))
print(f"data_rows={rows}")
PY
```

Comparar dos exports (solo conteos, sin imprimir filas):

```bash
python3 - <<'PY'
import csv
from pathlib import Path

def row_count(p):
    with Path(p).open(encoding="utf-8", errors="replace", newline="") as f:
        return sum(1 for _ in f) - 1

p1 = Path("<project>/data/raw/.../export_a.csv")
p2 = Path("<project>/data/raw/.../export_b.csv")
print(f"rows_a={row_count(p1)}")
print(f"rows_b={row_count(p2)}")
PY
```

### JSON inspection

```bash
JSON="<project>/tests/fixtures/<source>/<file>.json"

file "$JSON"
jq 'type' "$JSON"
jq 'if type == "array" then length elif type == "object" then keys else . end' "$JSON" | head -50
jq '.book | keys' "$JSON" 2>/dev/null | head -30
rg -n '"title"' "$JSON" | head -5
```

### JSONL / NDJSON

```bash
JSONL="<project>/data/raw/<file>.jsonl"

python3 - "$JSONL" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
ok = 0
bad = 0
keys = set()

with path.open("r", encoding="utf-8", errors="replace") as f:
    for i, line in zip(range(100), f):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            ok += 1
            if isinstance(obj, dict):
                keys.update(obj.keys())
        except Exception:
            bad += 1

print(f"path={path}")
print(f"sample_ok={ok}")
print(f"sample_bad={bad}")
print("sample_keys=" + repr(sorted(keys)[:50]))
PY
```

### Logs (headless)

`lnav` sin `-n` requiere TTY. En agentes usar `-n` o `head`/`rg`.

```bash
LOG="<project>/tests/logs/<file>.log"

file "$LOG"
wc -l "$LOG"
head -20 "$LOG"
lnav -n "$LOG" | head -50
rg -n 'ERROR|FAILED|Exception' "$LOG" | head -20
```

### VisiData (secondary)

Solo para **humano en terminal** con TTY, o export controlado:

```bash
# Interactivo (humano; cerrar con q)
vd "$CSV"

# Batch controlado — siempre -o en /tmp; nunca a stdout
vd -b -o /tmp/vd_inspect_sample.tsv "$CSV"
```

Reglas `vd`:

- Usar siempre `-o /tmp/...` en batch.
- Revisar header/columnas sensibles antes de exportar.
- No usar como herramienta por defecto de agentes.
- No asumir soporte Parquet en el paquete APT.

## Decision Matrix

| Tarea | Herramienta recomendada |
| --- | --- |
| Contar filas CSV | `wc -l`, Python |
| Ver columnas CSV | `head -1`, Python `csv` |
| Validar JSON | `jq`, Python |
| Inspeccionar JSONL | Python línea a línea |
| Buscar patrones | `rg` |
| Listar candidatos | `find`, `fdfind` |
| Revisar logs headless | `lnav -n`, `head`, `rg` |
| Exploración interactiva tabular | `vd` (humano / TTY) |
| Selección humana de rutas | `fzf` |

## Checklist

- [ ] Comprobé que `data/raw` existe y listé tamaños antes de abrir ficheros.
- [ ] Usé solo header/conteos/esquema; no imprimí reviews ni notas privadas.
- [ ] Elegí `python3` para CSV y `jq` para JSON antes que `vd`.
- [ ] Si usé `vd -b`, redirigí con `-o /tmp/...` y documenté el temporal.
- [ ] No modifiqué, moví ni borré ficheros raw.
- [ ] No ejecuté pipelines ETL ni escribí en bases de datos.

## Best Practices

- Tratar exports Goodreads y similares como **datos personales**: columnas como `My Review` y `Private Notes` están fuera de scope para salida de agente.
- Vigilar ISBN con prefijo `=""` (export Excel); `csv` de Python lo tolera mejor que parsers naive.
- Si `data/raw` solo tiene `.gitkeep`, buscar fixtures en `tests/fixtures/` o logs en `tests/logs/` sin asumir que raw está poblado.
- Repetir discovery cuando aparezcan nuevas fuentes (API, kaggle, scraping) bajo `data/raw`.

## Quality Checklist

- La respuesta del agente resume **estructura** (columnas, filas, tipos), no contenido sensible.
- Los comandos son **no destructivos** y reproducibles en WSL2.
- No se recomienda DuckDB, pgcli ni nuevas herramientas de sistema en esta skill.
- TUI (`vd`, `lnav`) solo se menciona con advertencia de TTY o modo headless.
