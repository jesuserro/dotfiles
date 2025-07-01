#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
BASE_BRANCH="${1:-dev}"  # Rama base por defecto, o la recibida por parámetro

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# 🔍 Procesar argumentos
process_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help|-h)
        echo -e "${BLUE}📖 Uso: git diffstat [rama-base]${NC}"
        echo -e "${BLUE}📖 Descripción: Muestra estadísticas de cambios desde una rama base${NC}"
        echo -e "${BLUE}📖 Ejemplos:${NC}"
        echo -e "  git diffstat               # Desde rama 'dev' (por defecto)"
        echo -e "  git diffstat main          # Desde rama 'main'"
        echo -e "  git diffstat feature/xyz   # Desde rama 'feature/xyz'"
        echo -e "${BLUE}📖 Opciones:${NC}"
        echo -e "  --help, -h                 # Mostrar esta ayuda"
        exit 0
        ;;
      *)
        if [ -z "$BASE_BRANCH" ] || [ "$BASE_BRANCH" = "dev" ]; then
          BASE_BRANCH="$1"
        else
          echo -e "${RED}❗ Argumento desconocido: $1${NC}"
          echo -e "${BLUE}💡 Usa 'git diffstat --help' para ver las opciones${NC}"
          exit 1
        fi
        shift
        ;;
    esac
  done
}

# Procesar argumentos
process_arguments "$@"

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
  exit 1
fi

# 🧠 Verifica si una rama existe
branch_exists() {
  git rev-parse --verify "$1" >/dev/null 2>&1
}

# Verificar que la rama base existe
if ! branch_exists "$BASE_BRANCH"; then
  echo -e "${RED}❗ La rama '${BASE_BRANCH}' no existe.${NC}"
  echo -e "${BLUE}💡 Usa: git diffstat <rama-base>${NC}"
  echo -e "${BLUE}💡 Ejemplo: git diffstat main${NC}"
  echo -e "${BLUE}💡 O usa: git diffstat --help${NC}"
  exit 1
fi

# 📊 Mostrar estadísticas de cambios
echo -e "${BLUE}📊 Estadísticas de cambios desde ${BASE_BRANCH}${NC}"

# Ejecutar el comando git diff con estadísticas
git diff --stat --color=always "${BASE_BRANCH}..HEAD" | \
  tr -d '\r' | \
  sed '/^$/d' 