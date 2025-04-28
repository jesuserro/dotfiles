#!/bin/bash

# Script para hacer git add, commit y push con mensajes mejorados
# Uso: git-save [mensaje personalizado]

# Si se proporciona un argumento, úsalo como mensaje
if [ "$1" != "" ]; then
  COMMIT_MSG="$1"
else
  # Si no hay argumentos, intentar leer de VSCode/Cursor (interfaz básica)
  echo "Escribe tu mensaje de commit (deja vacío para mensaje predeterminado):"
  read -r COMMIT_MSG
  
  # Si sigue vacío, usar el mensaje predeterminado
  if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="chore(save): workflow checkpoint"
  fi
fi

# Obtener la rama actual
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")

# Ejecutar los comandos git
git add -A
git commit -m "$COMMIT_MSG"
git push origin HEAD

echo "✅ Cambios guardados y enviados con el mensaje: $COMMIT_MSG a $BRANCH" 