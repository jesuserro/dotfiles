#!/bin/bash

# Script para hacer git add, commit y push con mensajes mejorados
# Uso: git-save [tipo] [scope] [descripción]
# Ejemplo: git-save chore save "workflow checkpoint"

# Función para validar el formato del mensaje
validate_commit_format() {
  local type="$1"
  local scope="$2"
  local description="$3"
  
  # Tipos permitidos
  local allowed_types=("feat" "fix" "docs" "style" "refactor" "test" "chore")
  
  # Validar tipo
  if [[ ! " ${allowed_types[*]} " =~ " ${type} " ]]; then
    echo "❌ Error: Tipo de commit no válido. Tipos permitidos: ${allowed_types[*]}"
    return 1
  fi
  
  # Validar descripción
  if [[ -z "$description" ]]; then
    echo "❌ Error: La descripción no puede estar vacía"
    return 1
  fi
  
  # Validar que la descripción comience con minúscula
  if [[ ! "$description" =~ ^[a-z] ]]; then
    echo "❌ Error: La descripción debe comenzar con minúscula"
    return 1
  fi
  
  return 0
}

# Si se proporcionan los tres argumentos, usarlos
if [ "$#" -eq 3 ]; then
  TYPE="$1"
  SCOPE="$2"
  DESCRIPTION="$3"
  COMMIT_MSG="${TYPE}(${SCOPE}): ${DESCRIPTION}"
  
  # Validar el formato
  if ! validate_commit_format "$TYPE" "$SCOPE" "$DESCRIPTION"; then
    exit 1
  fi
else
  # Si no hay argumentos, mostrar ayuda
  if [ "$#" -eq 0 ]; then
    echo "Uso: git-save [tipo] [scope] [descripción]"
    echo "Ejemplo: git-save chore save \"workflow checkpoint\""
    echo "Tipos permitidos: feat, fix, docs, style, refactor, test, chore"
    exit 1
  fi
  
  # Si solo se proporciona un argumento, asumir que es la descripción
  if [ "$#" -eq 1 ]; then
    TYPE="chore"
    SCOPE="save"
    DESCRIPTION="$1"
    COMMIT_MSG="${TYPE}(${SCOPE}): ${DESCRIPTION}"
  else
    echo "❌ Error: Número incorrecto de argumentos"
    echo "Uso: git-save [tipo] [scope] [descripción]"
    exit 1
  fi
fi

# Obtener la rama actual
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")

# Ejecutar los comandos git
git add -A
git commit -m "$COMMIT_MSG"
git push origin HEAD

echo "✅ Cambios guardados y enviados con el mensaje: $COMMIT_MSG a $BRANCH" 