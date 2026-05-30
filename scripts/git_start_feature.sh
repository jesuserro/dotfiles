#!/bin/bash

set -e

# ✅ Config por defecto
BASE_BRANCH="dev"
RAW_NAME="$1"
FEATURE_PREFIX="feature/"

# 🎨 Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Validar que estamos en un repo Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
	exit 1
fi

# Validar nombre de la nueva rama
if [ -z "$RAW_NAME" ]; then
	echo -e "${RED}❗ Debes proporcionar un nombre para la nueva rama feature.${NC}"
	echo "👉 Uso: ./git_start_feature.sh auth-login"
	exit 1
fi

# Añadir prefijo si no viene incluido
if [[ "$RAW_NAME" == feature/* ]]; then
	FEATURE_BRANCH="$RAW_NAME"
else
	FEATURE_BRANCH="${FEATURE_PREFIX}${RAW_NAME}"
fi

# Validar que el base branch existe
if ! git show-ref --verify --quiet refs/heads/$BASE_BRANCH; then
	echo -e "${RED}❗ La rama base '${BASE_BRANCH}' no existe localmente.${NC}"
	exit 1
fi

# Verificar si hay cambios sin guardar
if [[ -n $(git status --porcelain) ]]; then
	echo -e "${RED}❗ Tienes cambios sin guardar. Haz commit o stash antes de continuar.${NC}"
	git status
	exit 1
fi

# Actualizar rama base
echo -e "${YELLOW}🔄 Cambiando a la rama base '${BASE_BRANCH}' y actualizándola...${NC}"
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"

# Crear y publicar nueva rama
echo -e "${YELLOW}🌱 Creando nueva rama: '${FEATURE_BRANCH}' desde '${BASE_BRANCH}'...${NC}"
git checkout -b "$FEATURE_BRANCH"
git push --set-upstream origin "$FEATURE_BRANCH"

echo -e "${GREEN}✅ Rama '${FEATURE_BRANCH}' creada y publicada en remoto.${NC}"
echo -e "${GREEN}🚀 ¡Listo para desarrollar!${NC}"
