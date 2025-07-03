# 📋 Git Branch Changelog Script (`git_branch_changelog.sh`)

> **Script para generar changelogs categorizados de la rama actual comparada con una rama base, siguiendo el estándar de Conventional Commits.**

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

El script `git_branch_changelog.sh` genera changelogs detallados para la rama actual, comparándola con una rama base especificada. Categoriza automáticamente los commits según el estándar de Conventional Commits y crea archivos organizados en el directorio `releases/`.

## ✨ Características

- 📋 **Changelogs de ramas**: Genera changelogs para cualquier rama actual
- 📊 **Categorización automática**: Clasifica commits por tipo (feat, fix, docs, etc.)
- 🔍 **Rama base configurable**: Por defecto compara con `dev`, pero permite especificar cualquier rama
- 📁 **Archivos organizados**: Guarda changelogs en `releases/branch_<rama>.md`
- 📈 **Información detallada**: Incluye hashes, fechas, autores y estadísticas
- 🎨 **Formato profesional**: Sigue estándares de changelog
- 🛡️ **Validaciones**: Verifica existencia de ramas y estructura del repositorio

## 🔧 Instalación

El script ya está configurado en tu `~/.gitconfig` con el alias:

```bash
branch-changelog = "!f() { bash ~/dotfiles/scripts/git_branch_changelog.sh \"$@\"; }; f"
```

## 📖 Uso Básico

### 🎯 Comando Principal

```bash
git branch-changelog [opciones]
```

### 📝 Ejemplos de Uso

```bash
git branch-changelog                    # Rama actual vs dev
git branch-changelog --base main        # Rama actual vs main
git branch-changelog -b feature/login   # Rama actual vs feature/login
```

### 📊 Ejemplo de Salida

```
📄 Generando changelog para rama: feature/auth-system
📁 Archivo: releases/branch_feature_auth-system.md
📝 Generando changelog desde dev hasta feature/auth-system...
✅ Changelog generado exitosamente: releases/branch_feature_auth-system.md
📋 Resumen:
  • Rama: feature/auth-system
  • Rama base: dev
  • Total commits: 5
  • Archivo: releases/branch_feature_auth-system.md
```

## 🎛️ Opciones

### 🆘 Ayuda

```bash
git branch-changelog --help
# o
git branch-changelog -h
```

**Salida:**
```
📖 Uso: git branch-changelog [opciones]
📖 Descripción: Genera changelog para la rama actual
📖 Ejemplos:
  git branch-changelog                    # Rama actual vs dev
  git branch-changelog --base main        # Rama actual vs main
  git branch-changelog -b feature/login   # Rama actual vs feature/login
📖 Opciones:
  --base, -b <rama>                       # Rama base para comparar (default: dev)
  --help, -h                              # Mostrar esta ayuda
```

### 🔍 Especificar Rama Base

```bash
# Comparar con main
git branch-changelog --base main

# Comparar con otra feature
git branch-changelog -b feature/login

# Comparar con tag específico
git branch-changelog -b v1.2.3
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
| `chore` | `chore:` | **Technical** | Tareas de mantenimiento |
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

### Technical
- chore: actualizar dependencias
```

## 📁 Estructura de Archivos

### 🗂️ Directorio de Releases

```
proyecto/
├── releases/                 # Directorio de changelogs
│   ├── branch_feature_auth-system.md
│   ├── branch_feature_user-profile.md
│   ├── branch_main.md
│   └── branch_dev.md
└── ...
```

### 📄 Archivo de Changelog de Rama

```markdown
# Changelog: feature/auth-system

**Rama:** feature/auth-system  
**Rama base:** dev  
**Fecha de generación:** 2024-01-15 14:30  
**Total de commits:** 5

## Changes

### Added
- abc1234 2024-01-15 14:25 Jesús Erro feat: añadir sistema de autenticación
- def5678 2024-01-15 14:20 María García feat: implementar login con OAuth

### Fixed
- ghi9012 2024-01-15 14:15 Carlos López fix: corregir bug en validación de formularios

### Documentation
- jkl3456 2024-01-15 14:10 Ana Martín docs: actualizar guía de instalación

### Tests
- mno7890 2024-01-15 14:05 Pedro Sánchez test: añadir tests para autenticación

## Technical Details
- Rama actual: feature/auth-system
- Rama base: dev
- Total commits: 5
- Archivo generado: releases/branch_feature_auth-system.md
```

## ⚡ Casos de Uso

### 🔍 Revisión de Features

```bash
# Generar changelog de feature actual
git checkout feature/login
git branch-changelog

# Comparar con main en lugar de dev
git branch-changelog --base main
```

### 📊 Reportes de Desarrollo

```bash
# Ver progreso de feature vs dev
git branch-changelog

# Ver progreso vs main (para PRs)
git branch-changelog -b main

# Ver cambios desde último release
git branch-changelog -b v1.2.3
```

### 🔄 Comparación de Ramas

```bash
# Comparar feature con otra feature
git branch-changelog -b feature/user-profile

# Comparar con rama de staging
git branch-changelog -b staging

# Comparar con rama de producción
git branch-changelog -b production
```

### 📋 Documentación de Cambios

```bash
# Generar changelog para documentar cambios
git branch-changelog

# Usar para crear notas de release
git branch-changelog -b main > release-notes.md
```

### 🧪 Análisis de Commits

```bash
# Ver qué tipos de commits tienes
git branch-changelog | grep "###"

# Contar commits por categoría
git branch-changelog | grep -c "^-"
```

## 🔧 Configuración

### 📁 Variables del Script

```bash
# En scripts/git_branch_changelog.sh
BASE_BRANCH="dev"                     # Rama base por defecto
CHANGELOG_PREFIX="branch_"            # Prefijo para archivos de changelog
RELEASES_DIR="$PROJECT_ROOT/releases" # Directorio de releases
```

### 🎨 Personalización

```bash
# Cambiar rama base por defecto
BASE_BRANCH="main"

# Cambiar prefijo de archivos
CHANGELOG_PREFIX="changelog_"

# Cambiar directorio de releases
RELEASES_DIR="$PROJECT_ROOT/docs/changelogs"
```

### 🎨 Colores Disponibles

```bash
# Colores del script
GREEN='\033[0;32m'         # ✅ Éxito
YELLOW='\033[1;33m'        # ⚠️ Advertencia
RED='\033[0;31m'           # ❌ Error
BLUE='\033[0;34m'          # 💡 Información
NC='\033[0m'               # Reset color
```

## ❓ FAQ

### 🤔 ¿Qué rama base usa por defecto?

El script usa `dev` como rama base por defecto. Se puede cambiar con `--base` o `-b`.

### 📊 ¿Qué información incluye el changelog?

- **Commits categorizados**: Por tipo (feat, fix, docs, etc.)
- **Hashes de commit**: Para referencia
- **Fechas y autores**: Para trazabilidad
- **Estadísticas**: Total de commits
- **Metadatos**: Rama actual, rama base, fecha de generación

### 📁 ¿Dónde se guardan los archivos?

Los archivos se guardan en `releases/branch_<nombre-rama>.md` con el nombre de la rama sanitizado.

### 🔄 ¿Qué pasa si la rama base no existe?

El script muestra un error y sugiere alternativas:

```
❗ La rama 'rama-inexistente' no existe.
💡 Usa: git branch-changelog --base <rama-válida>
```

### 📊 ¿Cómo se categorizan los commits?

El script busca prefijos en los mensajes de commit:

```bash
feat: nueva funcionalidad     → Added
fix: corregir bug            → Fixed
docs: actualizar README      → Documentation
```

### 🔍 ¿Puedo usar tags como rama base?

Sí, puedes usar cualquier referencia válida de Git:

```bash
git branch-changelog -b v1.2.3
git branch-changelog -b HEAD~5
git branch-changelog -b abc1234
```

### 📋 ¿Cómo ver commits que no se categorizaron?

Los commits que no coinciden con ningún prefijo van a la categoría "Other":

```markdown
### Other
- commit sin prefijo
- otro commit
```

### 🔄 ¿Puedo regenerar un changelog existente?

Sí, el script sobrescribe los archivos existentes:

```bash
git branch-changelog  # Regenera el changelog actual
```

### 📈 ¿Cómo obtener estadísticas del changelog?

```bash
# Ver número de commits por categoría
grep -c "^- " releases/branch_feature_auth-system.md

# Ver total de commits
grep "Total commits:" releases/branch_feature_auth-system.md
```

### 🏷️ ¿Cómo personalizar las categorías?

Edita la función `categorize_commits()` en el script:

```bash
# Añadir nueva categoría
"- perf"*)
  echo "$line" >> "$perf_file" ;;
```

### 📝 ¿Cómo cambiar el formato del changelog?

Modifica las funciones de generación en el script:

```bash
# Cambiar formato de fecha
local current_date=$(date +"%B %d, %Y")

# Cambiar estructura del archivo
cat > "$changelog_file" << EOF
# Changelog: ${branch_name}

**Generated:** ${current_date}

## Changes

${categorized_content}
EOF
```

---

## 🎉 ¡Listo para usar!

El script `git_branch_changelog.sh` genera changelogs detallados para cualquier rama. ¡Perfecto para documentar cambios y generar reportes de desarrollo! 📋 