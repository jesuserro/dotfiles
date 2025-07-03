# 💾 Git Save Script (`git_save.sh`)

> **Script automatizado para hacer commits y push con mensajes estructurados siguiendo Conventional Commits, incluyendo validación de tipos y visualización de cambios.**

## 📋 Tabla de Contenidos

- [🎯 Descripción](#-descripción)
- [✨ Características](#-características)
- [🔧 Instalación](#-instalación)
- [📖 Uso Básico](#-uso-básico)
- [🎛️ Opciones](#️-opciones)
- [🏷️ Tipos de Commit](#-tipos-de-commit)
- [📊 Ejemplos de Salida](#-ejemplos-de-salida)
- [⚡ Casos de Uso](#-casos-de-uso)
- [🔧 Configuración](#-configuración)
- [❓ FAQ](#-faq)

## 🎯 Descripción

El script `git_save.sh` automatiza el proceso de commit y push con mensajes estructurados que siguen el estándar de Conventional Commits. Incluye validación de tipos de commit, visualización de archivos modificados y manejo inteligente del staging area.

## ✨ Características

- 📝 **Mensajes estructurados**: Sigue el formato `type(scope): description`
- 🏷️ **Validación de tipos**: Verifica que el tipo de commit sea válido
- 📊 **Visualización de cambios**: Muestra archivos modificados con colores
- 🔄 **Manejo inteligente**: Detecta si hay cambios en staging o working directory
- 🚀 **Push automático**: Hace push inmediatamente después del commit
- 🎨 **Output colorido**: Interfaz visual con colores y emojis
- 🛡️ **Validaciones**: Verifica estado del repositorio y argumentos

## 🔧 Instalación

El script ya está configurado en tu `~/.gitconfig` con el alias:

```bash
save = "!bash ~/dotfiles/scripts/git_save.sh"
```

## 📖 Uso Básico

### 🎯 Comando Principal

```bash
git save [tipo] [scope] [descripción]
```

### 📝 Ejemplos de Uso

```bash
git save                                    # Commit rápido con mensaje por defecto
git save "actualizar configuración"         # Commit con tipo 'chore' por defecto
git save feat "agregar login con Google"    # Commit con tipo específico
git save fix api "corregir error en endpoint" # Commit con tipo y scope
```

### 📊 Ejemplo de Salida

```
📦 Hay cambios en el stage. Haciendo commit solo de estos cambios...
🔄 Haciendo commit con mensaje: feat(auth): agregar login con Google
📝 Archivos modificados:
  M src/components/Login.js
  A src/utils/auth.js
  M tests/login.test.js
🔄 Enviando cambios a feature/login...
✅ Cambios guardados y enviados con éxito:
  Mensaje: feat(auth): agregar login con Google
  Rama: feature/login
```

## 🎛️ Opciones

### 🆘 Ayuda

```bash
git save --help
# o
git save -h
```

**Salida:**
```
Uso de git save:
  git save                               # Commit rápido con mensaje por defecto
  git save <descripción>                 # Commit rápido con tipo 'chore'
  git save <tipo> <descripción>          # Commit con tipo específico
  git save <tipo> <scope> <descripción>  # Commit con tipo y scope específicos

Tipos permitidos:
  feat fix docs style refactor perf test build ci chore revert

Ejemplos:
  git save
  git save "actualizar configuración"
  git save feat "agregar login con Google"
  git save fix api "corregir error en endpoint de usuarios"
```

## 🏷️ Tipos de Commit

### 📋 Tipos Soportados

El script valida que el tipo de commit sea uno de los siguientes:

| 🏷️ Tipo | 💡 Descripción | 📝 Ejemplo |
|---------|----------------|------------|
| `feat` | Nueva funcionalidad | `feat: agregar sistema de autenticación` |
| `fix` | Corrección de bug | `fix: corregir error en login` |
| `docs` | Documentación | `docs: actualizar README` |
| `style` | Formato de código | `style: aplicar prettier` |
| `refactor` | Refactorización | `refactor: simplificar función auth` |
| `perf` | Mejoras de rendimiento | `perf: optimizar consulta de base de datos` |
| `test` | Tests | `test: añadir tests para login` |
| `build` | Build system | `build: actualizar webpack` |
| `ci` | CI/CD | `ci: configurar GitHub Actions` |
| `chore` | Tareas de mantenimiento | `chore: actualizar dependencias` |
| `revert` | Revertir cambios | `revert: revertir commit anterior` |

### 📝 Formatos de Mensaje

```bash
# Formato básico
git save feat "nueva funcionalidad"

# Formato con scope
git save feat auth "agregar login con Google"

# Formato por defecto (sin argumentos)
git save
# Resultado: chore(save): workflow checkpoint
```

## 📊 Ejemplos de Salida

### 🔄 Commit con Cambios en Staging

```bash
git save feat "agregar validación de formularios"
```

**Salida:**
```
📦 Hay cambios en el stage. Haciendo commit solo de estos cambios...
🔄 Haciendo commit con mensaje: feat: agregar validación de formularios
📝 Archivos modificados:
  M src/components/Form.js
  A src/utils/validation.js
  M tests/form.test.js
🔄 Enviando cambios a feature/validation...
✅ Cambios guardados y enviados con éxito:
  Mensaje: feat: agregar validación de formularios
  Rama: feature/validation
```

### 🔄 Commit con Todos los Cambios

```bash
git save fix "corregir bug en API"
```

**Salida:**
```
🔄 No hay cambios en el stage. Agregando todos los cambios...
🔄 Haciendo commit con mensaje: fix: corregir bug en API
📝 Archivos modificados:
  M src/api/endpoints.js
  D src/utils/old-helper.js
🔄 Enviando cambios a main...
✅ Cambios guardados y enviados con éxito:
  Mensaje: fix: corregir bug en API
  Rama: main
```

### ⚠️ Error de Validación

```bash
git save invalid "mensaje"
```

**Salida:**
```
❌ Error: Tipo de commit 'invalid' no válido
Tipos permitidos: feat fix docs style refactor perf test build ci chore revert
```

## ⚡ Casos de Uso

### 🚀 Desarrollo Rápido

```bash
# Commit rápido sin especificar tipo
git save "actualizar configuración"

# Commit con tipo específico
git save feat "agregar nueva funcionalidad"
```

### 🔧 Trabajo con Features

```bash
# Desarrollo de feature
git save feat auth "implementar login con OAuth"
git save test auth "añadir tests para OAuth"
git save docs auth "documentar flujo de OAuth"
```

### 🐛 Corrección de Bugs

```bash
# Identificar y corregir bug
git save fix api "corregir error 500 en endpoint usuarios"
git save test api "añadir test para caso edge"
```

### 📚 Documentación

```bash
# Actualizar documentación
git save docs "actualizar guía de instalación"
git save docs api "documentar nuevos endpoints"
```

### 🔄 Refactorización

```bash
# Mejorar código existente
git save refactor auth "simplificar lógica de autenticación"
git save perf db "optimizar consultas de base de datos"
```

### 🧹 Mantenimiento

```bash
# Tareas de mantenimiento
git save chore "actualizar dependencias"
git save chore "limpiar código no utilizado"
```

## 🔧 Configuración

### 📁 Variables del Script

```bash
# En scripts/git_save.sh
ALLOWED_TYPES=("feat" "fix" "docs" "style" "refactor" "perf" "test" "build" "ci" "chore" "revert")
```

### 🎨 Personalización

```bash
# Añadir nuevos tipos de commit
ALLOWED_TYPES=("feat" "fix" "docs" "style" "refactor" "perf" "test" "build" "ci" "chore" "revert" "wip" "hotfix")

# Cambiar mensaje por defecto
TYPE="chore"
SCOPE="save"
DESCRIPTION="workflow checkpoint"
```

### 🎨 Colores Disponibles

```bash
# Colores del script
RED='\033[0;31m'           # ❌ Error
GREEN='\033[0;32m'         # ✅ Éxito
YELLOW='\033[0;33m'        # ⚠️ Advertencia
BLUE='\033[0;34m'          # 💡 Información
NC='\033[0m'               # Reset color
```

## ❓ FAQ

### 🤔 ¿Qué pasa si no especifico el tipo de commit?

El script usa `chore` como tipo por defecto:

```bash
git save "mensaje"
# Resultado: chore(save): mensaje
```

### 📊 ¿Cómo se muestran los archivos modificados?

El script muestra archivos con códigos de color:
- **A** (Verde): Archivo añadido
- **M** (Amarillo): Archivo modificado
- **D** (Rojo): Archivo eliminado
- **R** (Azul): Archivo renombrado

### 🔄 ¿Qué pasa si hay conflictos en el push?

El script muestra un error y sugiere hacer pull:

```
❌ Error al hacer push a feature/login
Prueba haciendo: git pull origin feature/login
```

### 🏷️ ¿Puedo usar tipos de commit personalizados?

No, el script valida contra una lista predefinida. Para añadir nuevos tipos, edita la variable `ALLOWED_TYPES` en el script.

### 📝 ¿Cómo funciona el scope?

El scope es opcional y va entre paréntesis:

```bash
git save feat auth "login con Google"
# Resultado: feat(auth): login con Google
```

### 🔍 ¿Qué pasa si la descripción empieza con mayúscula?

El script valida que la descripción empiece con minúscula:

```
❌ Error: La descripción debe comenzar con minúscula
```

### 📦 ¿Cómo maneja el staging area?

- **Si hay cambios en staging**: Hace commit solo de esos cambios
- **Si no hay cambios en staging**: Añade todos los cambios (`git add -A`)

### 🚀 ¿Puedo usar el script sin hacer push?

No, el script siempre hace push después del commit. Para solo commit, usa `git commit` directamente.

### 🔄 ¿Qué pasa si estoy en detached HEAD?

El script detecta y muestra la situación:

```bash
git save "mensaje"
# Rama: HEAD detached
```

### 📊 ¿Cómo ver el historial de commits?

```bash
# Ver commits recientes
git log --oneline -10

# Ver commits con formato detallado
git log --pretty=format:"%h %s (%an)" -10
```

---

## 🎉 ¡Listo para usar!

El script `git_save.sh` simplifica el proceso de commit y push con mensajes estructurados. ¡Perfecto para mantener un historial de commits limpio y profesional! 💾 