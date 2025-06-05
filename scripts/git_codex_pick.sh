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

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
  exit 1
fi

# 📛 Validación de argumentos
if [ -z "$COMMIT_HASH" ]; then
  echo -e "${RED}❗ ERROR: Debes pasar el hash del commit como argumento.${NC}"
  echo "👉 Ejemplo: git codexpick abc1234"
  exit 1
fi

# 🧼 Validación: working directory debe estar limpio
if [[ -n $(git status --porcelain) ]]; then
  echo -e "${RED}❗ Tu working directory no está limpio.${NC}"
  git status
  exit 1
fi

# 🔍 Verificar si el commit existe
if ! git rev-parse --verify "$COMMIT_HASH" >/dev/null 2>&1; then
  echo -e "${RED}❗ El commit '$COMMIT_HASH' no existe.${NC}"
  exit 1
fi

# 🔄 Realizar el cherry-pick
echo -e "${BLUE}🔄 Aplicando cambios del commit '$COMMIT_HASH'...${NC}"
if ! git cherry-pick -n "$COMMIT_HASH"; then
  echo -e "${RED}❗ Error al aplicar el cherry-pick.${NC}"
  echo -e "${YELLOW}💡 Sugerencia: Resuelve los conflictos manualmente si los hay.${NC}"
  exit 1
fi

# 🎉 Éxito
echo -e "${GREEN}✅ Cambios aplicados correctamente.${NC}"
echo -e "${YELLOW}📝 Los cambios están en tu working directory, listos para revisar y commitear.${NC}" 