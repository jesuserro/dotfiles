# 📝 Git Changelog Generator Script (`git_changelog.sh`)

> **Script automatizado para generar changelogs categorizados y organizados, siguiendo el estándar de Conventional Commits.**

## 📋 Tabla de Contenidos

- [🎯 Descripción](#-descripción)
- [✨ Características](#-características)
- [🔧 Instalación](#-instalación)
- [📖 Uso Básico](#-uso-básico)
- [🎛️ Opciones](#️-opciones)
- [📊 Categorización](#-categorización)
- [📁 Estructura de Archivos](#-estructura-de-archivos)
- [⚡ Casos de Uso](#-casos-de-uso)
- [🔧 Configuración](#-configuración)
- [❓ FAQ](#-faq)

## 🎯 Descripción

El script `git_changelog.sh` automatiza la generación de changelogs profesionales para releases de software. Categoriza automáticamente los commits según el estándar de Conventional Commits, genera archivos individuales por release y mantiene un CHANGELOG.md principal actualizado.

## ✨ Características

- 📝 **Categorización automática**: Clasifica commits por tipo (feat, fix, docs, etc.)
- 📁 **Archivos organizados**: Genera changelogs individuales y un archivo principal
- 🏷️ **Detección automática**: Encuentra automáticamente el tag anterior
- 📊 **Estadísticas**: Incluye número de commits y fechas
- 🎨 **Formato profesional**: Sigue estándares de changelog
- 🔄 **Mantenimiento**: Mantiene solo las últimas N releases en el archivo principal
- 🛡️ **Validaciones**: Verifica tags y estructura del repositorio

## 🔧 Instalación

El script ya está configurado en tu `~/.gitconfig` con el alias:

```bash
changelog = "!f() { bash ~/dotfiles/scripts/git_changelog.sh \"$@\"; }; f"
```

## 📖 Uso Básico

### 🎯 Comando Principal

```bash
git changelog <tag-actual> [tag-anterior]
```

### 📝 Ejemplos de Uso

```bash
git changelog v1.2.3                    # Genera changelog para v1.2.3
git changelog v1.2.3 v1.2.2             # Desde v1.2.2 hasta v1.2.3
git changelog v2.0.0                    # Release mayor (desde último tag)
```

### 📊 Ejemplo de Salida

```
🚀 Iniciando generación de changelogs para v1.2.3...
🔍 Tag anterior detectado automáticamente: v1.2.2
📁 Creando directorio de releases...
📄 Generando changelog individual: releases/v1.2.3.md
✅ Changelog individual generado: releases/v1.2.3.md
📋 Actualizando CHANGELOG.md principal...
✅ CHANGELOG.md principal actualizado
🎉 ¡Changelogs generados exitosamente!
📋 Resumen:
  • Changelog individual: releases/v1.2.3.md ✅
  • CHANGELOG.md principal actualizado ✅
  • Releases mantenidos: 5 ✅
```

## 🎛️ Opciones

### 🆘 Ayuda

```bash
git changelog --help
# o
git changelog -h
```

**Salida:**
```
📖 Uso: git changelog <tag-actual> [tag-anterior]
📖 Descripción: Genera changelogs para un release
📖 Ejemplos:
  git changelog v1.2.3                    # Genera changelog para v1.2.3
  git changelog v1.2.3 v1.2.2             # Desde v1.2.2 hasta v1.2.3
📖 Opciones:
  --help, -h                              # Mostrar esta ayuda
```

## 📊 Categorización

### 🏷️ Tipos de Commits Soportados

El script categoriza automáticamente los commits según estos prefijos:

| 🏷️ Tipo | 📝 Prefijo | 📊 Categoría | 💡 Descripción |
|---------|------------|--------------|----------------|
| `feat` | `feat:` | **Added** | Nuevas funcionalidades |
| `feature` | `feature:` | **Added** | Nuevas funcionalidades |
| `fix` | `fix:` | **Fixed** | Correcciones de bugs |
| `docs` | `docs:` | **Documentation** | Cambios en documentación |
| `style` | `style:` | **Style** | Cambios de formato |
| `refactor` | `refactor:` | **Refactored** | Refactorización de código |
| `test` | `test:` | **Tests** | Añadir o modificar tests |
| `chore` | `chore:` | **Chores** | Tareas de mantenimiento |
| Otros | Cualquier otro | **Other** | Otros cambios |

### 📋 Ejemplo de Categorización

**Commits originales:**
```
feat: añadir sistema de autenticación
fix: corregir bug en login
docs: actualizar README
test: añadir tests para auth
chore: actualizar dependencias
```

**Changelog generado:**
```markdown
### Added
- feat: añadir sistema de autenticación

### Fixed
- fix: corregir bug en login

### Documentation
- docs: actualizar README

### Tests
- test: añadir tests para auth

### Chores
- chore: actualizar dependencias
```

## 📁 Estructura de Archivos

### 🗂️ Directorio de Releases

```
proyecto/
├── CHANGELOG.md              # Archivo principal (últimas 5 releases)
├── releases/                 # Directorio de changelogs individuales
│   ├── v1.2.3.md
│   ├── v1.2.2.md
│   ├── v1.2.1.md
│   └── v1.2.0.md
└── ...
```

### 📄 Archivo Individual de Release

```markdown
# Release v1.2.3

**Fecha:** 2024-01-15

## Changes

### Added
- feat: añadir sistema de autenticación (Jesús Erro)
- feat: implementar login con OAuth (María García)

### Fixed
- fix: corregir bug en validación de formularios (Carlos López)

### Documentation
- docs: actualizar guía de instalación (Ana Martín)

## Technical Details
- Tag: v1.2.3
- Previous tag: v1.2.2
- Total commits: 4
```

### 📋 CHANGELOG.md Principal

```markdown
# Changelog

Este archivo contiene las últimas 5 releases. Para el historial completo, consulta los archivos en el directorio `releases/`.

## [v1.2.3] - 2024-01-15

### Added
- feat: añadir sistema de autenticación
- feat: implementar login con OAuth

### Fixed
- fix: corregir bug en validación de formularios

### Documentation
- docs: actualizar guía de instalación

## [v1.2.2] - 2024-01-10

### Added
- feat: añadir validación de formularios

### Fixed
- fix: corregir error en API
```

## ⚡ Casos de Uso

### 🚀 Release Normal

```bash
# 1. Crear tag
git tag v1.2.3
git push origin v1.2.3

# 2. Generar changelog
git changelog v1.2.3

# 3. ¡Listo! Changelog generado automáticamente
```

### 🔄 Release con Tag Anterior Específico

```bash
# Generar changelog desde un tag específico
git changelog v1.2.3 v1.0.0

# Útil para releases mayores o saltos de versión
```

### 🏷️ Release Mayor

```bash
# Para releases mayores (v1.x.x → v2.0.0)
git changelog v2.0.0

# El script detectará automáticamente v1.9.9 como tag anterior
```

### 📊 Regenerar Changelog

```bash
# Si necesitas regenerar un changelog
git changelog v1.2.3 v1.2.2

# Sobrescribe los archivos existentes
```

### 🔄 Integración con git rel

El script se ejecuta automáticamente después de `git rel`:

```bash
git rel v1.2.3
# → Hace merge, crea tag, y ejecuta git changelog automáticamente
```

## 🔧 Configuración

### 📁 Variables del Script

```bash
# En scripts/git_changelog.sh
MAX_RECENT_RELEASES=5                # Número de releases en CHANGELOG.md
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"
RELEASES_DIR="$PROJECT_ROOT/releases"
```

### 🎨 Personalización

```bash
# Cambiar número de releases mantenidos
MAX_RECENT_RELEASES=10

# Cambiar ubicación de archivos
CHANGELOG_FILE="$PROJECT_ROOT/docs/CHANGELOG.md"
RELEASES_DIR="$PROJECT_ROOT/docs/releases"

# Añadir más categorías
# Editar la función categorize_commits()
```

### 🏷️ Configuración de Tags

```bash
# Crear tag anotado (recomendado)
git tag -a v1.2.3 -m "Release v1.2.3"

# Crear tag simple
git tag v1.2.3

# Subir tag al remoto
git push origin v1.2.3
```

## ❓ FAQ

### 🤔 ¿Qué pasa si no especifico el tag anterior?

El script detecta automáticamente el tag anterior usando `git describe`:

```bash
git changelog v1.2.3
# Busca automáticamente v1.2.2
```

### 📊 ¿Cómo se categorizan los commits?

El script busca prefijos en los mensajes de commit:

```bash
feat: nueva funcionalidad     → Added
fix: corregir bug            → Fixed
docs: actualizar README      → Documentation
```

### 📁 ¿Dónde se guardan los archivos?

- **CHANGELOG.md**: En la raíz del proyecto
- **Archivos individuales**: En el directorio `releases/`

### 🔄 ¿Qué pasa si el directorio releases/ no existe?

El script lo crea automáticamente:

```
📁 Creando directorio de releases...
```

### 📋 ¿Cuántas releases mantiene el archivo principal?

Por defecto mantiene las últimas 5 releases. Se puede configurar con `MAX_RECENT_RELEASES`.

### 🏷️ ¿Puedo usar tags que no sigan semver?

Sí, el script funciona con cualquier formato de tag:

```bash
git changelog v1.2.3
git changelog release-2024-01-15
git changelog beta-1.2.3
```

### 📊 ¿Cómo obtener estadísticas del changelog?

```bash
# Ver número de commits por categoría
grep -c "^- " releases/v1.2.3.md

# Ver total de commits
grep "Total commits:" releases/v1.2.3.md
```

### 🔄 ¿Puedo regenerar un changelog existente?

Sí, el script sobrescribe los archivos existentes:

```bash
git changelog v1.2.3  # Regenera v1.2.3.md
```

### 📝 ¿Cómo personalizar las categorías?

Edita la función `categorize_commits()` en el script:

```bash
# Añadir nueva categoría
"- perf"*)
  echo "$line" >> "$perf_file" ;;
```

### 🎨 ¿Cómo cambiar el formato del changelog?

Modifica las funciones de generación en el script:

```bash
# Cambiar formato de fecha
local tag_date=$(git log -1 --format="%ad" --date=format:"%B %d, %Y" "$tag")

# Cambiar estructura del archivo
cat > "$release_file" << EOF
# Release ${tag}

**Released:** ${tag_date}

## What's New

${categorized_content}
EOF
```

### 🔍 ¿Cómo ver commits que no se categorizaron?

Los commits que no coinciden con ningún prefijo van a la categoría "Other":

```markdown
### Other
- commit sin prefijo
- otro commit
```

---

## 🎉 ¡Listo para usar!

El script `git_changelog.sh` genera changelogs profesionales automáticamente. ¡Perfecto para mantener documentación actualizada de tus releases! 📝 