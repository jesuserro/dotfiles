#!/bin/bash

set -e

# 📦 Config
INPUT_NAME="$1"
DEV_BRANCH="dev"
MAIN_BRANCH="main"
FEATURE_PREFIX="feature/"
FEATURE_BRANCH=""
ARCHIVE_PREFIX="archive/"
TAG_SUFFIX="_done"

# 🎨 Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Validar que estamos en un repo Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
  exit 1
fi

check_clean_repo() {
  if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}❗ Tu working directory no está limpio.${NC}"
    git status
    exit 1
  fi
}

branch_exists() {
  git rev-parse --verify "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}🚀 Iniciando flujo de integración de la rama feature '${INPUT_NAME}'...${NC}"

if [ -z "$INPUT_NAME" ]; then
  echo -e "${RED}❗ ERROR: Debes pasar el nombre de la rama feature como argumento.${NC}"
  echo "👉 Ejemplo: ./git_merge_feature_to_dev_and_main.sh 1-patata"
  exit 1
fi

if branch_exists "$INPUT_NAME"; then
  FEATURE_BRANCH="$INPUT_NAME"
elif branch_exists "${FEATURE_PREFIX}${INPUT_NAME}"; then
  FEATURE_BRANCH="${FEATURE_PREFIX}${INPUT_NAME}"
else
  echo -e "${RED}❗ La rama '${INPUT_NAME}' ni '${FEATURE_PREFIX}${INPUT_NAME}' existe localmente.${NC}"
  exit 1
fi

check_clean_repo

# Paso 1: Merge dev → main
echo -e "${YELLOW}🔁 Paso 1: Merge de '${DEV_BRANCH}' → '${MAIN_BRANCH}'...${NC}"
git checkout "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"
if ! git merge "$DEV_BRANCH" --no-edit; then
  echo -e "${RED}❗ Conflictos detectados entre '${DEV_BRANCH}' y '${MAIN_BRANCH}'${NC}"
  exit 1
fi
git push origin "$MAIN_BRANCH"
echo -e "${GREEN}✅ Merge completado: '${DEV_BRANCH}' → '${MAIN_BRANCH}'${NC}"

# Paso 2: Merge feature → dev
echo -e "${YELLOW}🔁 Paso 2: Merge de '${FEATURE_BRANCH}' → '${DEV_BRANCH}'...${NC}"
git checkout "$DEV_BRANCH"
git pull origin "$DEV_BRANCH"
if ! git merge "$FEATURE_BRANCH" --no-edit; then
  echo -e "${RED}❗ Conflictos detectados entre '${FEATURE_BRANCH}' y '${DEV_BRANCH}'${NC}"
  exit 1
fi
git push origin "$DEV_BRANCH"
echo -e "${GREEN}✅ Merge completado: '${FEATURE_BRANCH}' → '${DEV_BRANCH}'${NC}"

# Paso 3: Crear un tag
TAG_NAME="${FEATURE_BRANCH//\//_}${TAG_SUFFIX}"
echo -e "${YELLOW}🏷️  Paso 3: Creando tag '${TAG_NAME}'...${NC}"
git tag "$TAG_NAME" "$FEATURE_BRANCH"
git push origin "$TAG_NAME"
echo -e "${GREEN}✅ Tag '${TAG_NAME}' creado y subido.${NC}"

# Paso 4: Archivar la rama
ARCHIVE_BRANCH="${ARCHIVE_PREFIX}${FEATURE_BRANCH}"
echo -e "${YELLOW}📦 Paso 4: Archivando rama '${FEATURE_BRANCH}' como '${ARCHIVE_BRANCH}'...${NC}"
git branch -m "$FEATURE_BRANCH" "$ARCHIVE_BRANCH"
git push origin "$ARCHIVE_BRANCH"
git push origin --delete "$FEATURE_BRANCH" || true

echo -e "${GREEN}✅ Rama archivada como '${ARCHIVE_BRANCH}' y eliminada la original del remoto.${NC}"

echo -e "${GREEN}🎉 ¡Proceso completado con éxito!${NC}"
