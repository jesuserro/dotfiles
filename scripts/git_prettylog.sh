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
        echo -e "${BLUE}📖 Uso: git prettylog [rama-base]${NC}"
        echo -e "${BLUE}📖 Descripción: Muestra el historial de commits desde una rama base${NC}"
        echo -e "${BLUE}📖 Ejemplos:${NC}"
        echo -e "  git prettylog              # Desde rama 'dev' (por defecto)"
        echo -e "  git prettylog main         # Desde rama 'main'"
        echo -e "  git prettylog feature/xyz  # Desde rama 'feature/xyz'"
        echo -e "${BLUE}📖 Opciones:${NC}"
        echo -e "  --help, -h                 # Mostrar esta ayuda"
        exit 0
        ;;
      *)
        if [ -z "$BASE_BRANCH" ] || [ "$BASE_BRANCH" = "dev" ]; then
          BASE_BRANCH="$1"
        else
          echo -e "${RED}❗ Argumento desconocido: $1${NC}"
          echo -e "${BLUE}💡 Usa 'git prettylog --help' para ver las opciones${NC}"
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
  echo -e "${BLUE}💡 Usa: git prettylog <rama-base>${NC}"
  echo -e "${BLUE}💡 Ejemplo: git prettylog main${NC}"
  echo -e "${BLUE}💡 O usa: git prettylog --help${NC}"
  exit 1
fi

# 📋 Mostrar historial de commits
echo -e "${BLUE}📋 Historial de commits desde ${BASE_BRANCH}${NC}"

# Ejecutar el comando git log con formato mejorado
git log --color=always \
  --pretty=format:"%C(auto)%h %Cblue%ad %Cgreen%an %C(yellow)%s%Creset" \
  --date=format:"%Y-%m-%d %H:%M" \
  --name-status \
  --numstat \
  "${BASE_BRANCH}..HEAD" | \
  tr -d '\r' | \
  sed '/^$/d' | \
  sed -e 's/^A\t/\x1b[32mA\x1b[0m\t/g' \
      -e 's/^M\t/\x1b[33mM\x1b[0m\t/g' \
      -e 's/^D\t/\x1b[31mD\x1b[0m\t/g' \
      -e 's/^R\([0-9]*\)\t/\x1b[34mR\1\x1b[0m\t/g' \
      -e 's/^C\t/\x1b[34mC\x1b[0m\t/g' 