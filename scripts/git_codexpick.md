# 🧬 Git CodexPick Script (`git_codexpick.sh`)

> **Script para aplicar (cherry-pick) un commit específico de cualquier rama, con validaciones y mensajes visuales.**

## 📋 Tabla de Contenidos

- [🎯 Descripción](#-descripción)
- [✨ Características](#-características)
- [🔧 Instalación](#-instalación)
- [📖 Uso Básico](#-uso-básico)
- [🎛️ Opciones](#️-opciones)
- [📊 Ejemplo de Salida](#-ejemplo-de-salida)
- [⚡ Casos de Uso](#-casos-de-uso)
- [🔧 Configuración](#-configuración)
- [❓ FAQ](#-faq)

## 🎯 Descripción

El script `git_codexpick.sh` permite aplicar (cherry-pick) un commit específico de cualquier rama, asegurando que el working directory esté limpio y validando el hash del commit. Es ideal para traer cambios puntuales de otras ramas o repositorios.

## ✨ Características

- 🧬 **Cherry-pick seguro**: Aplica un commit específico a tu rama actual
- 🛡️ **Validaciones**: Verifica que el working directory esté limpio y que el hash sea válido
- 🔍 **Detección de hash abreviado**: Muestra el hash completo si se usa uno corto
- 🎨 **Output colorido**: Mensajes claros y visuales
- 📝 **No hace commit automático**: Los cambios quedan en staging para revisión
- 🚦 **Manejo de conflictos**: Informa si hay conflictos y sugiere resolución

## 🔧 Instalación

El script ya está configurado en tu `~/.gitconfig` con el alias:

```bash
codexpick = "!bash ~/dotfiles/scripts/git_codexpick.sh"
```

## 📖 Uso Básico

### 🎯 Comando Principal

```bash
git codexpick <commit-hash>
```

### 📝 Ejemplo de Uso

```bash
git codexpick abc1234
```

## 🎛️ Opciones

No tiene opciones adicionales. Si no se pasa un hash, muestra un mensaje de error y ejemplo de uso.

## 📊 Ejemplo de Salida

### ✅ Cherry-pick Exitoso

```
🔄 Applying changes from commit 'abc1234'...
✅ Changes applied successfully.
📝 Changes are in your working directory, ready to review and commit.
```

### ℹ️ Hash Abreviado

```
ℹ️  Abbreviated hash detected. Full hash: 1234567890abcdef...
```

### ❌ Error: Working Directory Sucio

```
❗ Your working directory is not clean.
On branch feature/login
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   src/components/Login.js
```

### ❌ Error: Hash Inválido

```
❗ Commit 'xyz' does not exist.
```

### ❌ Error: Hash Muy Corto

```
❗ ERROR: Commit hash must be at least 4 characters long.
👉 Example: git codexpick abc1
```

### ❌ Error: Sin Hash

```
❗ ERROR: You must provide a commit hash as an argument.
👉 Example: git codexpick abc1234
```

## ⚡ Casos de Uso

### 🚀 Traer un cambio puntual

```bash
# Traer un commit de otra rama
git codexpick 1234abcd
# Revisar y hacer commit manualmente
```

### 🔄 Sincronizar cambios entre ramas

```bash
# Aplicar un hotfix de main a dev
git checkout dev
git codexpick abcdef12
```

### 🧪 Probar un cambio experimental

```bash
# Probar un commit experimental en tu rama
git codexpick 9876fedc
```

### 📝 Recuperar un commit perdido

```bash
# Recuperar un commit eliminado accidentalmente
git codexpick 1234dead
```

## 🔧 Configuración

### 📁 Variables del Script

```bash
# En scripts/git_codexpick.sh
MIN_HASH_LENGTH=4 # Longitud mínima del hash
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

### 🤔 ¿Qué pasa si el working directory no está limpio?

El script no permite cherry-pick si tienes cambios pendientes. Haz commit o stash antes de continuar.

### 📝 ¿Hace commit automáticamente?

No, los cambios quedan en staging para que los revises y hagas commit manualmente.

### 🔄 ¿Qué pasa si hay conflictos?

El script informa del conflicto y debes resolverlo manualmente antes de hacer commit.

### 🏷️ ¿Puedo usar hashes abreviados?

Sí, pero deben tener al menos 4 caracteres. El script muestra el hash completo si es abreviado.

### 🔍 ¿Cómo saber el hash de un commit?

```bash
git log --oneline
```

### 📝 ¿Puedo cherry-pick de otro repositorio?

Solo si el commit existe en tu repo local (por fetch, pull, etc.).

### 📦 ¿Qué pasa si el commit ya está en la rama?

Git lo detecta y no aplica cambios duplicados.

---

## 🎉 ¡Listo para usar!

El script `git_codexpick.sh` facilita el cherry-pick seguro y visual de cualquier commit. ¡Perfecto para flujos de trabajo colaborativos y recuperación de cambios! 🧬 