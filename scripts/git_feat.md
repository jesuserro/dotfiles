# 🌟 Git Feature Integration Script (`git_feat.sh`)

> **Script automatizado para integrar ramas de features en `dev` y archivarlas automáticamente.**

## 📋 Tabla de Contenidos

- [🎯 Descripción](#-descripción)
- [✨ Características](#-características)
- [🔧 Instalación](#-instalación)
- [📖 Uso Básico](#-uso-básico)
- [🎛️ Opciones](#️-opciones)
- [🔄 Flujo de Trabajo](#-flujo-de-trabajo)
- [📦 Sistema de Archivo](#-sistema-de-archivo)
- [📝 Changelog Automático](#-changelog-automático)
- [⚡ Casos de Uso](#-casos-de-uso)
- [🛠️ Resolución de Conflictos](#️-resolución-de-conflictos)
- [🔧 Configuración](#-configuración)
- [❓ FAQ](#-faq)

## 🎯 Descripción

El script `git_feat.sh` automatiza el proceso de integración de ramas de features en la rama de desarrollo (`dev`). Incluye detección automática de prefijos, gestión de conflictos y archivo automático de ramas integradas.

## ✨ Características

- 🔍 **Detección automática**: Resuelve automáticamente si la rama tiene prefijo `feature/` o no
- 🔄 **Merge inteligente**: Maneja conflictos potenciales antes del merge
- 📝 **Changelog automático**: Genera changelog de la feature después del merge exitoso
- 📦 **Archivo automático**: Mueve ramas integradas a `archive/` y las elimina del remoto
- 🛡️ **Validaciones**: Verifica estado del repositorio y existencia de ramas
- 🎨 **Output colorido**: Interfaz visual con colores y emojis
- 🔒 **Seguridad**: Confirma antes de continuar con conflictos detectados

## 🔧 Instalación

El script ya está configurado en tu `~/.gitconfig` con el alias:

```bash
feat = "!bash ~/dotfiles/scripts/git_feat.sh"
```

## 📖 Uso Básico

### 🎯 Comando Principal

```bash
git feat <nombre-feature>
```

**Ejemplos:**
```bash
git feat mi-nueva-funcionalidad     # Rama 'feature/mi-nueva-funcionalidad'
git feat feature/login-system       # Rama 'feature/login-system'
git feat login-system               # Rama 'feature/login-system'
```

### 📊 Ejemplo de Salida

```
🚀 Integrando feature 'login-system' en dev...
🔁 Integrando 'feature/login-system' en 'dev'...
🔍 Verificando conflictos potenciales entre 'feature/login-system' y 'dev'...
✅ No se detectaron conflictos potenciales
🔁 Haciendo merge de 'feature/login-system' → 'dev'...
✅ Merge completado: 'feature/login-system' → 'dev'
📝 Generando changelog de la feature después del merge...
✅ Changelog de feature generado: releases/branch_feature_login-system.md
📊 Estadísticas:
  • Commits exclusivos: 5
  • Rama base: dev
  • Archivo: releases/branch_feature_login-system.md
📦 Archivando rama 'feature/login-system' como 'archive/feature/login-system'...
✅ Rama archivada como 'archive/feature/login-system' y eliminada la original del remoto.
🎉 ¡Feature 'login-system' integrada exitosamente en dev!
💡 Próximo paso: Cuando dev esté listo para producción, ejecuta 'git rel'
```

## 🎛️ Opciones

### 🆘 Ayuda

```bash
git feat --help
# o
git feat -h
```

**Salida:**
```
📖 Uso: git feat <nombre-feature>
📖 Descripción: Integra una rama feature en dev y la archiva
📖 Ejemplos:
  git feat mi-nueva-funcionalidad     # Rama 'feature/mi-nueva-funcionalidad'
  git feat feature/login-system       # Rama 'feature/login-system'
  git feat login-system               # Rama 'feature/login-system'
📖 Opciones:
  --no-changelog                      # No generar changelog automáticamente
  --help, -h                          # Mostrar esta ayuda
📖 Flujo:
  1. Se mueve a rama 'dev'
  2. Hace merge de tu feature en dev
  3. Genera changelog de la feature después del merge (opcional)
  4. Archiva tu rama feature
  5. Termina en rama 'dev'
```

## 🔄 Flujo de Trabajo

El script sigue este orden específico para evitar conflictos con archivos sin rastrear:

1. **Validación**: Verifica que estás en un repo Git y que el working directory está limpio
2. **Detección**: Resuelve automáticamente el nombre de la rama (con o sin prefijo `feature/`)
3. **Preparación**: Cambia a `dev`, hace pull y guarda el commit base antes del merge
4. **Merge**: Realiza el merge de la feature en `dev` (con verificación de conflictos)
5. **Changelog**: Genera el changelog **después** del merge exitoso (usando el commit base guardado)
6. **Archivo**: Archiva la rama feature y la elimina del remoto

```mermaid
graph TD
    A[🚀 git feat <nombre>] --> B[✅ Validar repo]
    B --> C[🔍 Detectar rama]
    C --> D{¿Existe rama?}
    D -->|❌ No| E[💥 Error: Rama no existe]
    D -->|✅ Sí| F[🔁 Cambiar a dev]
    F --> G[🔄 Pull origin dev]
    G --> H[💾 Guardar commit base]
    H --> I[🔍 Verificar conflictos]
    I --> J{¿Conflictos?}
    J -->|⚠️ Sí| K[❓ ¿Continuar?]
    K -->|❌ No| L[🛑 Abortar]
    K -->|✅ Sí| M[🔁 Hacer merge]
    J -->|✅ No| M
    M --> N{¿Merge exitoso?}
    N -->|❌ No| O[🛠️ Resolver conflictos]
    N -->|✅ Sí| P[📝 Generar changelog]
    P --> Q[📦 Archivar rama]
    Q --> R[🗑️ Eliminar del remoto]
    R --> S[🎉 Feature integrada]
```

> **💡 Nota importante**: El changelog se genera **después** del merge para evitar conflictos con archivos sin rastrear que Git detectaría durante el merge.

## 📦 Sistema de Archivo

### 🏷️ Prefijos Automáticos

El script maneja automáticamente los prefijos:

| 📝 Input | 🔍 Búsqueda | 📦 Rama Final |
|----------|-------------|---------------|
| `login-system` | `feature/login-system` | `archive/feature/login-system` |
| `feature/auth` | `feature/auth` | `archive/feature/auth` |
| `bugfix/123` | `bugfix/123` | `archive/bugfix/123` |

### 📁 Estructura de Archivo

```
Ramas originales:
├── feature/login-system
├── feature/user-profile
└── bugfix/issue-123

Después de git feat:
├── archive/feature/login-system
├── archive/feature/user-profile
└── archive/bugfix/issue-123
```

## 📝 Changelog Automático

### 🎯 Generación Automática

El script genera automáticamente un changelog de la feature **después del merge exitoso**, capturando todos los commits exclusivos de la feature. El changelog se genera después del merge para evitar conflictos con archivos sin rastrear que Git detectaría durante el merge:

```
📝 Generando changelog de la feature después del merge...
✅ Changelog de feature generado: releases/branch_feature_login-system.md
📊 Estadísticas:
  • Commits exclusivos: 5
  • Rama base: dev
  • Archivo: releases/branch_feature_login-system.md
```

> **🔧 Detalles técnicos**: El script guarda el commit base de `dev` antes del merge, y luego usa ese commit para calcular los commits exclusivos de la feature después de que el merge se complete exitosamente.

### 📁 Ubicación de Changelogs

Los changelogs se guardan en el directorio `releases/` del proyecto:

```
proyecto/
├── releases/
│   ├── branch_feature_login-system.md
│   ├── branch_feature_user-profile.md
│   └── branch_bugfix_issue-123.md
└── ...
```

### 🚫 Desactivar Changelog Automático

Si no quieres generar el changelog automáticamente:

```bash
git feat mi-feature --no-changelog
```

### 📄 Formato del Changelog

El changelog incluye:
- **Commits exclusivos** de la feature (calculados usando el commit base guardado antes del merge)
- **Información técnica** (rama, commits, fecha)
- **Estado de integración** (marcado como integrado)

### ⚠️ Orden de Ejecución

El changelog se genera **después del merge** por diseño:
- ✅ Evita conflictos con archivos sin rastrear durante el merge
- ✅ Asegura que el merge se complete exitosamente antes de generar documentación
- ✅ Mantiene el working directory limpio durante el merge

## ⚡ Casos de Uso

### 🚀 Integración Normal

```bash
# 1. Trabajar en tu feature
git checkout feature/mi-feature
# ... hacer cambios ...
git commit -m "feat: añadir nueva funcionalidad"

# 2. Integrar en dev (con changelog automático)
git feat mi-feature

# 3. ¡Listo! La feature está en dev, archivada y con changelog
```

### 🔄 Múltiples Features

```bash
# Integrar varias features secuencialmente
git feat feature-1
git feat feature-2
git feat feature-3

# Todas quedan archivadas con sus changelogs
```

### 🏷️ Con Diferentes Prefijos

```bash
# Features
git feat login-system
git feat feature/auth

# Bugfixes
git feat bugfix/issue-123

# Hotfixes
git feat hotfix/critical-fix
```

## 🛠️ Resolución de Conflictos

### 🔍 Detección Inteligente

El script detecta conflictos potenciales antes del merge:

```
🔍 Verificando conflictos potenciales entre 'feature/login' y 'dev'...
⚠️  Archivos que podrían causar conflictos:
  • src/auth/login.js
  • tests/auth.test.js
💡 Sugerencia: Considera resolver estos conflictos antes de continuar
⚠️  Se detectaron posibles conflictos. ¿Deseas continuar? (s/N)
```

### ⚠️ Conflictos Reales

Si hay conflictos reales durante el merge:

```
❗ Conflictos detectados entre 'feature/login' y 'dev'
💡 Sugerencia: Resuelve los conflictos y luego ejecuta:
  git add .
  git commit -m "merge: resolve conflicts between feature/login and dev"
```

### 🛠️ Pasos de Resolución

1. **Resolver conflictos manualmente** en los archivos marcados
2. **Añadir cambios**: `git add .`
3. **Completar merge**: `git commit -m "merge: resolve conflicts"`
4. **Continuar**: El script continuará automáticamente

## 🔧 Configuración

### 📁 Variables del Script

```bash
# En scripts/git_feat.sh
DEV_BRANCH="dev"                    # Rama de desarrollo
FEATURE_PREFIX="feature/"           # Prefijo estándar para features
ARCHIVE_PREFIX="archive/"           # Prefijo para archivar ramas
GENERATE_CHANGELOG=true             # Generar changelog automáticamente
```

### 🎨 Personalización

```bash
# Cambiar prefijos
FEATURE_PREFIX="feat/"
ARCHIVE_PREFIX="archived/"

# Cambiar rama de desarrollo
DEV_BRANCH="develop"

# Desactivar changelog por defecto
GENERATE_CHANGELOG=false
```

## ❓ FAQ

### 🤔 ¿Qué pasa si la rama no existe?

El script busca automáticamente con y sin prefijo `feature/`:

```bash
git feat login-system
# Busca: login-system → feature/login-system
```

### 🔄 ¿Qué pasa si no se puede hacer fast-forward?

El script maneja automáticamente merges no fast-forward y continúa.

### 📦 ¿Dónde van las ramas archivadas?

Las ramas se mueven a `archive/` localmente y se eliminan del remoto para mantener limpio el repositorio.

### 📝 ¿Dónde se guardan los changelogs?

Los changelogs se guardan en `releases/branch_<nombre-feature>.md` y contienen todos los commits exclusivos de la feature. Se generan **después del merge exitoso** para evitar conflictos con archivos sin rastrear.

### 🚫 ¿Puedo desactivar el changelog automático?

Sí, usa la opción `--no-changelog`:

```bash
git feat mi-feature --no-changelog
```

### 🛠️ ¿Qué hacer si hay conflictos?

1. Resuelve los conflictos manualmente
2. Ejecuta `git add .`
3. Ejecuta `git commit -m "merge: resolve conflicts"`
4. El script continuará automáticamente

### 🔍 ¿Cómo ver ramas archivadas?

```bash
# Ver todas las ramas archivadas
git branch | grep archive/

# Ver ramas archivadas remotas (si existen)
git branch -r | grep archive/
```

### 🗑️ ¿Cómo eliminar ramas archivadas?

```bash
# Eliminar rama archivada local
git branch -D archive/feature/old-feature

# Eliminar rama archivada remota (si existe)
git push origin --delete archive/feature/old-feature
```

### 🔄 ¿Puedo integrar sin archivar?

No, el script siempre archiva las ramas integradas para mantener el repositorio limpio. Si necesitas mantener la rama, haz el merge manualmente.

---

## 🎉 ¡Listo para usar!

El script `git_feat.sh` está diseñado para hacer la integración de features de forma segura y automática, incluyendo la generación de changelogs precisos después del merge exitoso. El orden de ejecución (merge primero, changelog después) evita conflictos con archivos sin rastrear y garantiza un flujo de trabajo más eficiente. ¡Disfruta! 🌟