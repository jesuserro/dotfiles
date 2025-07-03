# 📊 Git Diff Statistics Script (`git_diffstat.sh`)

> **Script para mostrar estadísticas detalladas de cambios entre la rama actual y una rama base, con formato visual mejorado.**

## 📋 Tabla de Contenidos

- [🎯 Descripción](#-descripción)
- [✨ Características](#-características)
- [🔧 Instalación](#-instalación)
- [📖 Uso Básico](#-uso-básico)
- [🎛️ Opciones](#️-opciones)
- [📊 Ejemplos de Salida](#-ejemplos-de-salida)
- [⚡ Casos de Uso](#-casos-de-uso)
- [🔧 Configuración](#-configuración)
- [❓ FAQ](#-faq)

## 🎯 Descripción

El script `git_diffstat.sh` proporciona una vista detallada de las estadísticas de cambios entre la rama actual y una rama base especificada. Es útil para revisar el alcance de cambios antes de hacer merge o para generar reportes de desarrollo.

## ✨ Características

- 📊 **Estadísticas detalladas**: Muestra archivos modificados, líneas añadidas/eliminadas
- 🎨 **Output colorido**: Interfaz visual con colores y emojis
- 🔍 **Rama base configurable**: Por defecto usa `dev`, pero permite especificar cualquier rama
- 📈 **Formato mejorado**: Elimina caracteres de control y líneas vacías
- 🛡️ **Validaciones**: Verifica que la rama base existe
- 🎯 **Simplicidad**: Un solo comando para obtener estadísticas completas

## 🔧 Instalación

El script ya está configurado en tu `~/.gitconfig` con el alias:

```bash
diffstat = "!f() { bash ~/dotfiles/scripts/git_diffstat.sh \"$@\"; }; f"
```

## 📖 Uso Básico

### 🎯 Comando Principal

```bash
git diffstat [rama-base]
```

### 📝 Ejemplos de Uso

```bash
git diffstat               # Desde rama 'dev' (por defecto)
git diffstat main          # Desde rama 'main'
git diffstat feature/xyz   # Desde rama 'feature/xyz'
git diffstat v1.2.3        # Desde tag 'v1.2.3'
```

## 🎛️ Opciones

### 🆘 Ayuda

```bash
git diffstat --help
# o
git diffstat -h
```

**Salida:**
```
📖 Uso: git diffstat [rama-base]
📖 Descripción: Muestra estadísticas de cambios desde una rama base
📖 Ejemplos:
  git diffstat               # Desde rama 'dev' (por defecto)
  git diffstat main          # Desde rama 'main'
  git diffstat feature/xyz   # Desde rama 'feature/xyz'
📖 Opciones:
  --help, -h                 # Mostrar esta ayuda
```

## 📊 Ejemplos de Salida

### 🔍 Estadísticas desde `dev`

```bash
git diffstat
```

**Salida:**
```
📊 Estadísticas de cambios desde dev
 src/components/Login.js     | 45 ++++++++++++++++++++++++++++++++++++++++-------
 src/utils/auth.js          | 12 ++++++-----
 tests/login.test.js        | 23 +++++++++++++++++++++++
 3 files changed, 67 insertions(+), 16 deletions(-)
```

### 📈 Estadísticas desde `main`

```bash
git diffstat main
```

**Salida:**
```
📊 Estadísticas de cambios desde main
 src/components/Login.js     | 45 ++++++++++++++++++++++++++++++++++++++++-------
 src/components/Register.js  | 34 +++++++++++++++++++++++++++++++++++++
 src/utils/auth.js          | 12 ++++++-----
 src/utils/validation.js    | 18 +++++++++++++++++++
 tests/login.test.js        | 23 +++++++++++++++++++++++
 tests/register.test.js     | 15 +++++++++++++++
 6 files changed, 147 insertions(+), 16 deletions(-)
```

### 🏷️ Estadísticas desde un tag

```bash
git diffstat v1.2.3
```

**Salida:**
```
📊 Estadísticas de cambios desde v1.2.3
 docs/API.md                | 12 ++++++-----
 src/api/endpoints.js       | 23 +++++++++++++++++++++++
 src/utils/helpers.js       |  8 ++++++++
 3 files changed, 43 insertions(+), 5 deletions(-)
```

## ⚡ Casos de Uso

### 🔍 Revisión de Cambios

```bash
# Antes de hacer merge, revisar cambios
git diffstat dev

# Ver cambios desde el último release
git diffstat v1.2.3
```

### 📊 Reportes de Desarrollo

```bash
# Ver progreso desde main
git diffstat main

# Ver cambios de una feature específica
git checkout feature/login
git diffstat dev
```

### 🏷️ Comparación de Versiones

```bash
# Cambios entre versiones
git diffstat v1.2.0
git diffstat v1.1.0
git diffstat v1.0.0
```

### 🔄 Revisión de Pull Requests

```bash
# Ver cambios de tu rama vs dev
git diffstat dev

# Ver cambios vs main (para PRs a main)
git diffstat main
```

### 📈 Análisis de Alcance

```bash
# Ver qué archivos se han modificado
git diffstat dev | grep "files changed"

# Ver archivos específicos
git diffstat dev | grep "\.js$"
```

## 🔧 Configuración

### 📁 Variables del Script

```bash
# En scripts/git_diffstat.sh
BASE_BRANCH="${1:-dev}"  # Rama base por defecto
```

### 🎨 Personalización

```bash
# Cambiar rama base por defecto
BASE_BRANCH="${1:-main}"

# Añadir más opciones de formato
git diff --stat --color=always --summary "${BASE_BRANCH}..HEAD"
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

### 🤔 ¿Qué rama usa por defecto?

El script usa `dev` como rama base por defecto si no especificas ninguna.

### 📊 ¿Qué información muestra?

- **Archivos modificados**: Lista de archivos con cambios
- **Líneas añadidas**: Número de líneas nuevas (+)
- **Líneas eliminadas**: Número de líneas eliminadas (-)
- **Resumen total**: Total de archivos y líneas modificadas

### 🔍 ¿Cómo interpretar la salida?

```
src/components/Login.js | 45 ++++++++++++++++++++++++++++++++++++++++-------
```

- **45**: Líneas añadidas
- **++++**: Representación visual de líneas añadidas
- **----**: Representación visual de líneas eliminadas

### 🏷️ ¿Puedo usar tags como rama base?

Sí, puedes usar cualquier referencia válida de Git:

```bash
git diffstat v1.2.3        # Tag
git diffstat HEAD~5        # Commit específico
git diffstat abc1234       # Hash de commit
```

### 🔄 ¿Qué pasa si la rama base no existe?

El script muestra un error y sugiere alternativas:

```
❗ La rama 'rama-inexistente' no existe.
💡 Usa: git diffstat <rama-base>
💡 Ejemplo: git diffstat main
💡 O usa: git diffstat --help
```

### 📈 ¿Cómo obtener estadísticas más detalladas?

```bash
# Estadísticas con resumen
git diff --stat --summary dev..HEAD

# Estadísticas con nombres de archivos
git diff --name-only dev..HEAD

# Estadísticas con porcentajes
git diff --stat=80 dev..HEAD
```

### 🎨 ¿Por qué no veo colores?

El script usa `--color=always` para forzar colores. Si no los ves, puede ser que tu terminal no los soporte o esté configurado para no mostrarlos.

### 📊 ¿Cómo comparar con múltiples ramas?

```bash
# Comparar con varias ramas
git diffstat dev
git diffstat main
git diffstat feature/xyz

# O usar comandos Git nativos
git diff --stat dev..main
git diff --stat main..feature/xyz
```

### 🔍 ¿Cómo filtrar por tipo de archivo?

```bash
# Ver solo archivos JavaScript
git diffstat dev | grep "\.js"

# Ver solo archivos de test
git diffstat dev | grep "test"

# Ver solo archivos de documentación
git diffstat dev | grep "\.md"
```

---

## 🎉 ¡Listo para usar!

El script `git_diffstat.sh` te proporciona una vista clara y detallada de los cambios en tu repositorio. ¡Perfecto para revisar código y generar reportes! 📊 