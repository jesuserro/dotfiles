#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
INPUT_NAME="$1"                        # Nombre de la feature recibido por parámetro
DEV_BRANCH="dev"                      # Rama de desarrollo
FEATURE_PREFIX="feature/"            # Prefijo estándar para ramas de features
FEATURE_BRANCH=""                    # Rama feature final a usar (resuelta más abajo)
ARCHIVE_PREFIX="archive/"            # Prefijo para archivar ramas

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
  exit 1
fi

# 🧼 Validación: working directory debe estar limpio
check_clean_repo() {
  if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}❗ Tu working directory no está limpio.${NC}"
    git status
    exit 1
  fi
}

# 🧠 Verifica si una rama existe
branch_exists() {
  git rev-parse --verify "$1" >/dev/null 2>&1
}

# 🔍 Verifica conflictos potenciales
check_potential_conflicts() {
  local source_branch="$1"
  local target_branch="$2"
  
  echo -e "${BLUE}🔍 Verificando conflictos potenciales entre '${source_branch}' y '${target_branch}'...${NC}"
  
  # Obtener la lista de archivos modificados
  local modified_files=$(git diff --name-only $target_branch...$source_branch)
  
  # Verificar si hay archivos que podrían causar conflictos
  local potential_conflicts=()
  for file in $modified_files; do
    if git diff --name-only $target_branch | grep -q "^$file$"; then
      potential_conflicts+=("$file")
    fi
  done
  
  if [ ${#potential_conflicts[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Archivos que podrían causar conflictos:${NC}"
    for file in "${potential_conflicts[@]}"; do
      echo -e "  ${YELLOW}•${NC} $file"
    done
    echo -e "${YELLOW}💡 Sugerencia: Considera resolver estos conflictos antes de continuar${NC}"
    return 1
  fi
  
  return 0
}

# 🔄 Función para hacer merge con manejo de errores
do_merge() {
  local source_branch="$1"
  local target_branch="$2"
  
  echo -e "${YELLOW}🔁 Haciendo merge de '${source_branch}' → '${target_branch}'...${NC}"
  
  # Verificar conflictos potenciales
  if ! check_potential_conflicts "$source_branch" "$target_branch"; then
    echo -e "${YELLOW}⚠️  Se detectaron posibles conflictos. ¿Deseas continuar? (s/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
      exit 1
    fi
  fi
  
  # Intentar el merge
  if ! git merge "$source_branch" --no-edit; then
    echo -e "${RED}❗ Conflictos detectados entre '${source_branch}' y '${target_branch}'${NC}"
    echo -e "${YELLOW}💡 Sugerencia: Resuelve los conflictos y luego ejecuta:${NC}"
    echo -e "  git add ."
    echo -e "  git commit -m \"merge: resolve conflicts between ${source_branch} and ${target_branch}\""
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

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Integrando feature '${INPUT_NAME}' en dev...${NC}"

# 📛 Validación de argumentos
if [ -z "$INPUT_NAME" ]; then
  echo -e "${RED}❗ ERROR: Debes pasar el nombre de la rama feature como argumento.${NC}"
  echo "👉 Ejemplo: ./finish_feature.sh adding-dbt"
  echo "👉 O usar: git feat adding-dbt"
  exit 1
fi

# 🔍 Detección automática: resuelve si la rama tiene o no prefijo
if branch_exists "$INPUT_NAME"; then
  FEATURE_BRANCH="$INPUT_NAME"
elif branch_exists "${FEATURE_PREFIX}${INPUT_NAME}"; then
  FEATURE_BRANCH="${FEATURE_PREFIX}${INPUT_NAME}"
else
  echo -e "${RED}❗ La rama '${INPUT_NAME}' ni '${FEATURE_PREFIX}${INPUT_NAME}' existe localmente.${NC}"
  exit 1
fi

# Verificar estado del repositorio
check_clean_repo

# 🔁 Merge de feature → dev
echo -e "${YELLOW}🔁 Integrando '${FEATURE_BRANCH}' en '${DEV_BRANCH}'...${NC}"
git checkout "$DEV_BRANCH"
git pull origin "$DEV_BRANCH"
do_merge "$FEATURE_BRANCH" "$DEV_BRANCH"

# 📦 Archivar la rama feature
ARCHIVE_BRANCH="${ARCHIVE_PREFIX}${FEATURE_BRANCH}"
echo -e "${YELLOW}📦 Archivando rama '${FEATURE_BRANCH}' como '${ARCHIVE_BRANCH}'...${NC}"
git branch -m "$FEATURE_BRANCH" "$ARCHIVE_BRANCH"   # Renombrado local
git push origin "$ARCHIVE_BRANCH"                   # Subida rama archivada
git push origin --delete "$FEATURE_BRANCH" || true  # Eliminación en remoto (ignora error si no existe)
echo -e "${GREEN}✅ Rama archivada como '${ARCHIVE_BRANCH}' y eliminada la original del remoto.${NC}"

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Feature '${INPUT_NAME}' integrada exitosamente en dev!${NC}"
echo -e "${BLUE}💡 Próximo paso: Cuando dev esté listo para producción, ejecuta 'git rel'${NC}" 