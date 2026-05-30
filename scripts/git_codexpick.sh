#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# 📦 Configuración básica
COMMIT_HASH="$1"  # Hash del commit recibido por parámetro
MIN_HASH_LENGTH=4 # Longitud mínima del hash

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo -e "${RED}❌ You are not inside a Git repository.${NC}"
	exit 1
fi

# 📛 Validación de argumentos
if [ -z "$COMMIT_HASH" ]; then
	echo -e "${RED}❗ ERROR: You must provide a commit hash as an argument.${NC}"
	echo "👉 Example: git codexpick abc1234"
	exit 1
fi

# 📏 Validación de longitud mínima del hash
if [ ${#COMMIT_HASH} -lt $MIN_HASH_LENGTH ]; then
	echo -e "${RED}❗ ERROR: Commit hash must be at least $MIN_HASH_LENGTH characters long.${NC}"
	echo "👉 Example: git codexpick abc1"
	exit 1
fi

# 🧼 Validación: working directory debe estar limpio
if [[ -n $(git status --porcelain) ]]; then
	echo -e "${RED}❗ Your working directory is not clean.${NC}"
	git status
	exit 1
fi

# 🔍 Verificar si el commit existe y obtener el hash completo
FULL_HASH=$(git rev-parse --verify "$COMMIT_HASH" 2>/dev/null)
if [ $? -ne 0 ]; then
	echo -e "${RED}❗ Commit '$COMMIT_HASH' does not exist.${NC}"
	exit 1
fi

# Si el hash proporcionado es abreviado, mostrar el hash completo
if [ "$COMMIT_HASH" != "$FULL_HASH" ]; then
	echo -e "${BLUE}ℹ️  Abbreviated hash detected. Full hash: ${YELLOW}$FULL_HASH${NC}"
fi

# 🔄 Realizar el cherry-pick
echo -e "${BLUE}🔄 Applying changes from commit '$FULL_HASH'...${NC}"
if ! git cherry-pick -n "$FULL_HASH"; then
	echo -e "${RED}❗ Error applying cherry-pick.${NC}"
	echo -e "${YELLOW}💡 Suggestion: Resolve conflicts manually if any.${NC}"
	exit 1
fi

# 🎉 Éxito
echo -e "${GREEN}✅ Changes applied successfully.${NC}"
echo -e "${YELLOW}📝 Changes are in your working directory, ready to review and commit.${NC}"
