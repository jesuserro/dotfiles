#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
INPUT_NAME="$1"                        # Nombre de la feature recibido por parámetro
DEV_BRANCH="dev"                      # Rama de desarrollo
MAIN_BRANCH="main"                    # Rama principal de producción
FEATURE_PREFIX="feature/"            # Prefijo estándar para ramas de features
FEATURE_BRANCH=""                    # Rama feature final a usar (resuelta más abajo)
ARCHIVE_PREFIX="archive/"            # Prefijo para archivar ramas
TAG_SUFFIX="_done"                   # Sufijo para los tags de finalización

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Iniciando flujo de integración de la rama feature '${INPUT_NAME}'...${NC}"

# 📛 Validación de argumentos
if [ -z "$INPUT_NAME" ]; then
  echo -e "${RED}❗ ERROR: Debes pasar el nombre de la rama feature como argumento.${NC}"
  echo "👉 Ejemplo: ./git_merge_feature_to_dev_and_main.sh 1-patata"
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

check_clean_repo

# 🔁 Paso 1: Merge de dev → main (para mantener main actualizado con el trabajo consolidado)
echo -e "${YELLOW}🔁 Paso 1: Merge de '${DEV_BRANCH}' → '${MAIN_BRANCH}'...${NC}"
git checkout "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"
if ! git merge "$DEV_BRANCH" --no-edit; then
  echo -e "${RED}❗ Conflictos detectados entre '${DEV_BRANCH}' y '${MAIN_BRANCH}'${NC}"
  exit 1
fi
git push origin "$MAIN_BRANCH"
echo -e "${GREEN}✅ Merge completado: '${DEV_BRANCH}' → '${MAIN_BRANCH}'${NC}"

# 🔁 Paso 2: Merge de feature → dev (integramos la feature en desarrollo activo)
echo -e "${YELLOW}🔁 Paso 2: Merge de '${FEATURE_BRANCH}' → '${DEV_BRANCH}'...${NC}"
git checkout "$DEV_BRANCH"
git pull origin "$DEV_BRANCH"
if ! git merge "$FEATURE_BRANCH" --no-edit; then
  echo -e "${RED}❗ Conflictos detectados entre '${FEATURE_BRANCH}' y '${DEV_BRANCH}'${NC}"
  exit 1
fi
git push origin "$DEV_BRANCH"
echo -e "${GREEN}✅ Merge completado: '${FEATURE_BRANCH}' → '${DEV_BRANCH}'${NC}"

# 🏷️ Paso 3: Crear un tag para marcar el fin de la feature
TAG_NAME="${FEATURE_BRANCH//\//_}${TAG_SUFFIX}"   # Reemplaza / por _ para nombre de tag
echo -e "${YELLOW}🏷️  Paso 3: Creando tag '${TAG_NAME}'...${NC}"
git tag "$TAG_NAME" "$FEATURE_BRANCH"
git push origin "$TAG_NAME"
echo -e "${GREEN}✅ Tag '${TAG_NAME}' creado y subido.${NC}"

# 📦 Paso 4: Archivar la rama feature para preservar su historial y evitar borrarla completamente
ARCHIVE_BRANCH="${ARCHIVE_PREFIX}${FEATURE_BRANCH}"
echo -e "${YELLOW}📦 Paso 4: Archivando rama '${FEATURE_BRANCH}' como '${ARCHIVE_BRANCH}'...${NC}"
git branch -m "$FEATURE_BRANCH" "$ARCHIVE_BRANCH"   # Renombrado local
git push origin "$ARCHIVE_BRANCH"                   # Subida rama archivada
git push origin --delete "$FEATURE_BRANCH" || true  # Eliminación en remoto (ignora error si no existe)
echo -e "${GREEN}✅ Rama archivada como '${ARCHIVE_BRANCH}' y eliminada la original del remoto.${NC}"

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Proceso completado con éxito!${NC}"
