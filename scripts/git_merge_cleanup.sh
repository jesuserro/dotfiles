#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
INPUT_NAME="$1"           # Nombre de la feature recibido por parámetro
DEV_BRANCH="dev"          # Rama de desarrollo
MAIN_BRANCH="main"        # Rama principal de producción
FEATURE_PREFIX="feature/" # Prefijo estándar para ramas de features
FEATURE_BRANCH=""         # Rama feature final a usar (resuelta más abajo)
ARCHIVE_PREFIX="archive/" # Prefijo para archivar ramas
TAG_SUFFIX="_done"        # Sufijo para los tags de finalización

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

# 🔍 Verifica permisos de archivos
check_file_permissions() {
	local problematic_files=()

	# Verificar archivos modificados
	while IFS= read -r file; do
		if [ ! -w "$file" ] && [ -e "$file" ]; then
			problematic_files+=("$file")
		fi
	done < <(git diff --name-only)

	if [ ${#problematic_files[@]} -gt 0 ]; then
		echo -e "${YELLOW}⚠️  Archivos con problemas de permisos:${NC}"
		for file in "${problematic_files[@]}"; do
			echo -e "  ${YELLOW}•${NC} $file"
		done
		echo -e "${YELLOW}💡 Sugerencia: Ejecuta 'sudo chown -R \$(whoami) .' para corregir permisos${NC}"
		return 1
	fi

	return 0
}

# 🔍 Verifica conflictos potenciales
check_potential_conflicts() {
	local source_branch="$1"
	local target_branch="$2"

	echo -e "${BLUE}🔍 Verificando conflictos potenciales entre '${source_branch}' y '${target_branch}'...${NC}"

	# Obtener la lista de archivos modificados
	local modified_files
	modified_files=$(git diff --name-only $target_branch...$source_branch)

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

# 🔍 Verifica archivos no trackeados que podrían causar conflictos
check_untracked_conflicts() {
	local target_branch="$1"

	# Obtener archivos no trackeados
	local untracked_files
	untracked_files=$(git ls-files --others --exclude-standard)

	# Verificar si alguno de estos archivos existe en la rama objetivo
	local potential_conflicts=()
	for file in $untracked_files; do
		if git ls-tree -r --name-only $target_branch | grep -q "^$file$"; then
			potential_conflicts+=("$file")
		fi
	done

	if [ ${#potential_conflicts[@]} -gt 0 ]; then
		echo -e "${YELLOW}⚠️  Archivos no trackeados que podrían causar conflictos:${NC}"
		for file in "${potential_conflicts[@]}"; do
			echo -e "  ${YELLOW}•${NC} $file"
		done
		echo -e "${YELLOW}💡 Sugerencia: Considera agregar estos archivos a .gitignore o hacer commit de ellos${NC}"
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

	# Verificar archivos no trackeados
	if ! check_untracked_conflicts "$target_branch"; then
		echo -e "${YELLOW}⚠️  Se detectaron archivos no trackeados que podrían causar conflictos. ¿Deseas continuar? (s/N)${NC}"
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

# Verificar permisos y estado del repositorio
check_clean_repo
check_file_permissions

# 🔁 Paso 1: Merge de dev → main
echo -e "${YELLOW}🔁 Paso 1: Merge de '${DEV_BRANCH}' → '${MAIN_BRANCH}'...${NC}"
git checkout "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"
do_merge "$DEV_BRANCH" "$MAIN_BRANCH"

# 🔁 Paso 2: Merge de feature → dev
echo -e "${YELLOW}🔁 Paso 2: Merge de '${FEATURE_BRANCH}' → '${DEV_BRANCH}'...${NC}"
git checkout "$DEV_BRANCH"
git pull origin "$DEV_BRANCH"
do_merge "$FEATURE_BRANCH" "$DEV_BRANCH"

# 🏷️ Paso 3: Crear un tag para marcar el fin de la feature
TAG_NAME="${FEATURE_BRANCH//\//_}${TAG_SUFFIX}" # Reemplaza / por _ para nombre de tag
echo -e "${YELLOW}🏷️  Paso 3: Creando tag '${TAG_NAME}'...${NC}"
git tag "$TAG_NAME" "$FEATURE_BRANCH"
git push origin "$TAG_NAME"
echo -e "${GREEN}✅ Tag '${TAG_NAME}' creado y subido.${NC}"

# 📦 Paso 4: Archivar la rama feature
ARCHIVE_BRANCH="${ARCHIVE_PREFIX}${FEATURE_BRANCH}"
echo -e "${YELLOW}📦 Paso 4: Archivando rama '${FEATURE_BRANCH}' como '${ARCHIVE_BRANCH}'...${NC}"
git branch -m "$FEATURE_BRANCH" "$ARCHIVE_BRANCH"  # Renombrado local
git push origin "$ARCHIVE_BRANCH"                  # Subida rama archivada
git push origin --delete "$FEATURE_BRANCH" || true # Eliminación en remoto (ignora error si no existe)
echo -e "${GREEN}✅ Rama archivada como '${ARCHIVE_BRANCH}' y eliminada la original del remoto.${NC}"

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Proceso completado con éxito!${NC}"
