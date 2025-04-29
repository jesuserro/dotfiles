#!/bin/bash

# Script para generar commits con formato convencional
# Diseñado para funcionar bien con IDEs y desde terminal
# Uso: git-commit-conv [tipo] [scope] [descripción]
# Ejemplo: git-commit-conv feat auth "agregar login con Google"

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
  echo -e "${BLUE}Uso de git-commit-conv:${NC}"
  echo "  git-commit-conv <tipo> <descripción>"
  echo "  git-commit-conv <tipo> <scope> <descripción>"
  echo ""
  echo -e "${YELLOW}Tipos permitidos:${NC}"
  printf "  %s\n" "${ALLOWED_TYPES[@]}"
  echo ""
  echo -e "${BLUE}Ejemplos:${NC}"
  echo "  git-commit-conv feat \"nueva funcionalidad de login\""
  echo "  git-commit-conv fix api \"corregir error en endpoint de usuarios\""
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

# Main
if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

# Caso 1: git-commit-conv <tipo> <descripción>
if [[ $# -eq 2 ]]; then
  TYPE="$1"
  DESC="$2"
  
  # Validar tipo
  if ! validate_type "$TYPE"; then
    exit 1
  fi
  
  # Crear mensaje
  COMMIT_MSG="${TYPE}: ${DESC}"
  
# Caso 2: git-commit-conv <tipo> <scope> <descripción>
elif [[ $# -eq 3 ]]; then
  TYPE="$1"
  SCOPE="$2"
  DESC="$3"
  
  # Validar tipo
  if ! validate_type "$TYPE"; then
    exit 1
  fi
  
  # Crear mensaje
  COMMIT_MSG="${TYPE}(${SCOPE}): ${DESC}"

# Caso de error: número incorrecto de argumentos
else
  echo -e "${RED}❌ Error: Número incorrecto de argumentos${NC}"
  show_help
  exit 1
fi

# Realizar commit
echo -e "${BLUE}🔄 Haciendo commit con mensaje:${NC} $COMMIT_MSG"
if git commit -m "$COMMIT_MSG" --no-template; then
  echo -e "${GREEN}✅ Commit realizado con éxito${NC}"
else
  echo -e "${RED}❌ Error al hacer commit${NC}"
  exit 1
fi 