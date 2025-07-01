#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
DEV_BRANCH="dev"                      # Rama de desarrollo
MAIN_BRANCH="main"                    # Rama principal de producción
TAG_PREFIX="v"                        # Prefijo para tags de versión

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
        echo -e "${BLUE}📖 Uso: git rel-resolve [opciones]${NC}"
        echo -e "${BLUE}📖 Descripción: Resuelve conflictos de git rel y genera changelog${NC}"
        echo -e "${BLUE}📖 Opciones:${NC}"
        echo -e "  --help, -h                 # Mostrar esta ayuda"
        echo -e "  --skip-merge               # Saltar el merge (solo generar tag y changelog)"
        echo -e "  --tag <tag-name>           # Usar tag específico en vez de generar automático"
        exit 0
        ;;
      --skip-merge)
        SKIP_MERGE=true
        shift
        ;;
      --tag)
        CUSTOM_TAG="$2"
        shift 2
        ;;
      *)
        echo -e "${RED}❗ Argumento desconocido: $1${NC}"
        echo -e "${BLUE}💡 Usa 'git rel-resolve --help' para ver las opciones${NC}"
        exit 1
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

# 🧼 Validación: working directory debe estar limpio
check_clean_repo() {
  if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}❗ Tu working directory no está limpio.${NC}"
    git status
    exit 1
  fi
}

# 🏷️ Función para generar versión automática
generate_version() {
  if [ -n "$CUSTOM_TAG" ]; then
    echo "$CUSTOM_TAG"
  else
    # Generar versión automática con formato vAAAA.MM.DD_HHMM
    VERSION=$(date +"%Y.%m.%d_%H%M")
    echo "${TAG_PREFIX}${VERSION}"
  fi
}

# 🔄 Función para hacer merge con manejo de errores
do_merge() {
  local source_branch="$1"
  local target_branch="$2"
  
  echo -e "${YELLOW}🔁 Haciendo merge de '${source_branch}' → '${target_branch}'...${NC}"
  
  # Intentar el merge
  if ! git merge "$source_branch" --no-edit; then
    echo -e "${RED}❗ Conflictos detectados entre '${source_branch}' y '${target_branch}'${NC}"
    echo -e "${YELLOW}💡 Resuelve los conflictos manualmente y luego ejecuta:${NC}"
    echo -e "  git add ."
    echo -e "  git commit -m \"merge: resolve conflicts between ${source_branch} and ${target_branch}\""
    echo -e "${YELLOW}💡 Después ejecuta este script nuevamente con --skip-merge${NC}"
    exit 1
  fi
  
  # Push de los cambios
  if ! git push origin "$target_branch"; then
    echo -e "${RED}❗ Error al hacer push a '${target_branch}'${NC}"
    echo -e "${YELLOW}💡 Sugerencia: Asegúrate de tener permisos y que la rama no esté protegida${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Merge completado: '${source_branch}' → '${target_branch}'${NC}"
}

# 🧹 Función para limpiar archivos problemáticos
cleanup_problematic_files() {
  echo -e "${BLUE}🧹 Verificando archivos problemáticos...${NC}"
  
  # Verificar si hay archivos no rastreados que puedan causar conflictos
  local untracked_files=$(git status --porcelain | grep "^??" | cut -c4-)
  
  if [ -n "$untracked_files" ]; then
    echo -e "${YELLOW}⚠️  Archivos no rastreados detectados:${NC}"
    echo "$untracked_files"
    echo -e "${YELLOW}💡 ¿Deseas eliminarlos para evitar conflictos? (s/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Ss]$ ]]; then
      echo "$untracked_files" | xargs rm -rf
      echo -e "${GREEN}✅ Archivos no rastreados eliminados${NC}"
    fi
  fi
}

# 📝 Función para generar changelog
generate_changelog() {
  local tag_name="$1"
  
  echo -e "${YELLOW}📝 Generando changelogs...${NC}"
  if bash ~/dotfiles/scripts/git_changelog.sh "$tag_name"; then
    echo -e "${GREEN}✅ Changelogs generados exitosamente${NC}"
  else
    echo -e "${YELLOW}⚠️  Error generando changelogs, pero el release se completó${NC}"
  fi
}

# 🚀 Función principal
main() {
  echo -e "${YELLOW}🚀 Iniciando resolución de conflictos de git rel...${NC}"
  
  # Verificar que las ramas existan
  if ! branch_exists "$DEV_BRANCH"; then
    echo -e "${RED}❗ La rama '${DEV_BRANCH}' no existe.${NC}"
    exit 1
  fi
  
  if ! branch_exists "$MAIN_BRANCH"; then
    echo -e "${RED}❗ La rama '${MAIN_BRANCH}' no existe.${NC}"
    exit 1
  fi
  
  # Verificar estado del repositorio
  check_clean_repo
  
  # Limpiar archivos problemáticos
  cleanup_problematic_files
  
  # Paso 1: Merge de dev → main (si no se especifica saltar)
  if [ "$SKIP_MERGE" != true ]; then
    echo -e "${YELLOW}🔁 Integrando '${DEV_BRANCH}' en '${MAIN_BRANCH}'...${NC}"
    git checkout "$MAIN_BRANCH"
    git pull origin "$MAIN_BRANCH"
    do_merge "$DEV_BRANCH" "$MAIN_BRANCH"
  else
    echo -e "${YELLOW}⚠️  Saltando merge (--skip-merge especificado)${NC}"
  fi
  
  # Paso 2: Crear tag de versión
  TAG_NAME=$(generate_version)
  echo -e "${YELLOW}🏷️  Creando tag '${TAG_NAME}'...${NC}"
  git tag "$TAG_NAME"
  git push origin "$TAG_NAME"
  echo -e "${GREEN}✅ Tag '${TAG_NAME}' creado y subido.${NC}"
  
  # Paso 3: Generar changelogs
  generate_changelog "$TAG_NAME"
  
  # 🎉 Fin del proceso
  echo -e "${GREEN}🎉 ¡Resolución de conflictos completada exitosamente!${NC}"
  echo -e "${BLUE}📋 Resumen:${NC}"
  if [ "$SKIP_MERGE" != true ]; then
    echo -e "  • ${DEV_BRANCH} → ${MAIN_BRANCH} ✅"
  else
    echo -e "  • Merge saltado (--skip-merge) ⚠️"
  fi
  echo -e "  • Tag creado: ${TAG_NAME} ✅"
  echo -e "  • Changelogs generados ✅"
  echo -e "${BLUE}💡 Próximo paso: Deploy a producción${NC}"
}

# Ejecutar función principal
main 