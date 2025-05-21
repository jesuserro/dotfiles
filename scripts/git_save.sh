#!/bin/bash

# Script para hacer git add, commit y push con mensajes mejorados
# Uso: git-save [tipo] [scope] [descripción]
#      git-save [tipo] [descripción]
#      git-save [descripción]
#      git-save            # Sin parámetros, usa mensaje por defecto
# Ejemplo: git-save chore save "workflow checkpoint"

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tipos de commit permitidos
ALLOWED_TYPES=("feat" "fix" "docs" "style" "refactor" "perf" "test" "build" "ci" "chore" "revert")

# Mostrar ayuda
show_help() {
  echo -e "${BLUE}Uso de git-save:${NC}"
  echo "  git-save                               # Commit rápido con mensaje por defecto"
  echo "  git-save <descripción>                 # Commit rápido con tipo 'chore'"
  echo "  git-save <tipo> <descripción>          # Commit con tipo específico"
  echo "  git-save <tipo> <scope> <descripción>  # Commit con tipo y scope específicos"
  echo ""
  echo -e "${YELLOW}Tipos permitidos:${NC}"
  printf "  %s\n" "${ALLOWED_TYPES[@]}"
  echo ""
  echo -e "${BLUE}Ejemplos:${NC}"
  echo "  git-save"
  echo "  git-save \"actualizar configuración\""
  echo "  git-save feat \"agregar login con Google\""
  echo "  git-save fix api \"corregir error en endpoint de usuarios\""
}

# Validar tipo de commit
validate_type() {
  local type="$1"
  for allowed in "${ALLOWED_TYPES[@]}"; do
    if [[ "$type" == "$allowed" ]]; then
      return 0
    fi
  done
  
  echo -e "${RED}❌ Error: Tipo de commit '$type' no válido${NC}"
  echo -e "${YELLOW}Tipos permitidos:${NC} ${ALLOWED_TYPES[*]}"
  return 1
}

# Verificar si hay cambios en el stage
check_staged_changes() {
  if git diff --staged --quiet; then
    return 1  # No hay cambios en stage
  else
    return 0  # Hay cambios en stage
  fi
}

# Función para mostrar los archivos modificados
show_modified_files() {
  echo -e "${BLUE}📝 Archivos modificados:${NC}"
  git diff --name-status | while read status file; do
    case $status in
      A) echo -e "  ${GREEN}A${NC} $file" ;;  # Added
      M) echo -e "  ${YELLOW}M${NC} $file" ;;  # Modified
      D) echo -e "  ${RED}D${NC} $file" ;;  # Deleted
      R*) echo -e "  ${BLUE}R${NC} $file" ;;  # Renamed
      C*) echo -e "  ${BLUE}C${NC} $file" ;;  # Copied
      *) echo -e "  $status $file" ;;
    esac
  done
}

# Main
if [[ $# -eq 0 ]]; then
  # Caso 0: git-save (sin argumentos)
  TYPE="chore"
  SCOPE="save"
  DESCRIPTION="workflow checkpoint"
  COMMIT_MSG="${TYPE}(${SCOPE}): ${DESCRIPTION}"
elif [[ $# -eq 1 ]]; then
  # Caso 1: git-save <descripción>
  TYPE="chore"
  SCOPE="save"
  DESCRIPTION="$1"
  COMMIT_MSG="${TYPE}(${SCOPE}): ${DESCRIPTION}"
elif [[ $# -eq 2 ]]; then
  # Caso 2: git-save <tipo> <descripción>
  TYPE="$1"
  DESCRIPTION="$2"
  
  # Validar tipo
  if ! validate_type "$TYPE"; then
    exit 1
  fi
  
  COMMIT_MSG="${TYPE}: ${DESCRIPTION}"
elif [[ $# -eq 3 ]]; then
  # Caso 3: git-save <tipo> <scope> <descripción>
  TYPE="$1"
  SCOPE="$2"
  DESCRIPTION="$3"
  
  # Validar tipo
  if ! validate_type "$TYPE"; then
    exit 1
  fi
  
  # Validar que la descripción comience con minúscula
  if [[ ! "$DESCRIPTION" =~ ^[a-z] ]]; then
    echo -e "${RED}❌ Error: La descripción debe comenzar con minúscula${NC}"
    exit 1
  fi
  
  COMMIT_MSG="${TYPE}(${SCOPE}): ${DESCRIPTION}"
else
  echo -e "${RED}❌ Error: Demasiados argumentos${NC}"
  show_help
  exit 1
fi

# Obtener la rama actual
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")

# Verificar si hay cambios en el stage
if check_staged_changes; then
  echo -e "${BLUE}📦 Hay cambios en el stage. Haciendo commit solo de estos cambios...${NC}"
else
  echo -e "${BLUE}🔄 No hay cambios en el stage. Agregando todos los cambios...${NC}"
  git add -A
fi

echo -e "${BLUE}🔄 Haciendo commit con mensaje:${NC} $COMMIT_MSG"
# Mostrar archivos modificados antes del commit
show_modified_files
# Usar --no-template para ignorar la plantilla gitmessage
if ! git commit -m "$COMMIT_MSG" --no-template; then
  echo -e "${RED}❌ Error al hacer commit${NC}"
  exit 1
fi

echo -e "${BLUE}🔄 Enviando cambios a $BRANCH...${NC}"
# Usar --porcelain para obtener una salida más limpia y mejor detección de errores
if ! git push origin HEAD --porcelain; then
  echo -e "${RED}❌ Error al hacer push a $BRANCH${NC}"
  echo -e "Prueba haciendo: ${YELLOW}git pull origin $BRANCH${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Cambios guardados y enviados con éxito:${NC}"
echo -e "  Mensaje: ${YELLOW}$COMMIT_MSG${NC}"
echo -e "  Rama: ${YELLOW}$BRANCH${NC}" # Test comment
