#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/git_flow_policy.sh
source "${SCRIPT_DIR}/lib/git_flow_policy.sh"

# 📦 Configuración básica
# NOTA: Esta configuración es estándar para TODOS los proyectos.
# Siempre usamos 'main' como rama principal de producción.
VERSION="$1"                     # Versión opcional recibida por parámetro
DEV_BRANCH="dev"                 # Rama de desarrollo
MAIN_BRANCH="main"               # Rama principal de producción
TAG_PREFIX="v"                   # Prefijo para tags de versión
GIT_FLOW_REPO_ROOT=""            # Raíz del repo donde se busca la policy
GIT_FLOW_PRINT_POLICY_ONLY=false # Modo diagnóstico sin operaciones productivas
GIT_FLOW_DRY_RUN=false           # Inspección sin push, merge, PR ni tag

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
		--help | -h)
			echo -e "${BLUE}📖 Uso: git rel [versión]${NC}"
			echo -e "${BLUE}📖 Ejemplos:${NC}"
			echo -e "  git rel                    # Release con versión automática"
			echo -e "  git rel 1.2.3              # Release con versión específica"
			echo -e "${BLUE}📖 Opciones:${NC}"
			echo -e "  --print-policy             # Imprimir la policy efectiva y salir"
			echo -e "  --dry-run                  # Mostrar acciones sin ejecutarlas"
			echo -e "  --help, -h                 # Mostrar esta ayuda"
			exit 0
			;;
		--print-policy)
			GIT_FLOW_PRINT_POLICY_ONLY=true
			shift
			;;
		--dry-run)
			GIT_FLOW_DRY_RUN=true
			shift
			;;
		*)
			if [ -z "$VERSION" ]; then
				VERSION="$1"
			else
				echo -e "${RED}❗ Argumento desconocido: $1${NC}"
				echo -e "${BLUE}💡 Usa 'git rel --help' para ver las opciones${NC}"
				exit 1
			fi
			shift
			;;
		esac
	done
}

load_git_flow_policy() {
	GIT_FLOW_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

	git_flow_policy_set_defaults
	if [[ -f "${GIT_FLOW_REPO_ROOT}/.git-flow-policy.env" ]]; then
		git_flow_policy_load_file "${GIT_FLOW_REPO_ROOT}/.git-flow-policy.env"
	fi
	git_flow_policy_validate

	DEV_BRANCH="$BASE_DEV_BRANCH"
	MAIN_BRANCH="$BASE_MAIN_BRANCH"
}

ensure_supported_flow_mode() {
	case "$FLOW_MODE_TO_MAIN" in
	local | pr)
		return 0
		;;
	*)
		echo -e "${RED}❌ PR mode variant not implemented yet for git rel: FLOW_MODE_TO_MAIN=${FLOW_MODE_TO_MAIN}${NC}"
		exit 1
		;;
	esac
}

run_validation_if_enabled() {
	if [[ "$VALIDATE_TO_MAIN" == "true" ]]; then
		if [[ "$GIT_FLOW_DRY_RUN" == "true" ]]; then
			echo -e "${BLUE}Would run validation: ${VALIDATE_CMD_TO_MAIN}${NC}"
			return 0
		fi
		echo -e "${BLUE}Running validation: ${VALIDATE_CMD_TO_MAIN}${NC}"
		if ! (cd "$GIT_FLOW_REPO_ROOT" && bash -c "$VALIDATE_CMD_TO_MAIN"); then
			echo -e "${RED}❌ Validation failed: ${VALIDATE_CMD_TO_MAIN}${NC}"
			exit 1
		fi
	fi
}

check_gh_cli_for_pr() {
	if ! command -v gh &>/dev/null; then
		echo -e "${RED}ERROR: FLOW_MODE_TO_MAIN=pr requires GitHub CLI (\`gh\`).${NC}"
		exit 1
	fi
}

print_dry_run_rel() {
	echo -e "${BLUE}DRY RUN: git rel policy flow (${FLOW_MODE_TO_MAIN})${NC}"
	run_validation_if_enabled
	if [[ "$FLOW_MODE_TO_MAIN" == "pr" ]]; then
		echo -e "${BLUE}Would switch to '${DEV_BRANCH}'${NC}"
		echo -e "${BLUE}Would pull '${DEV_BRANCH}' from '${REMOTE_NAME}' (ff-only)${NC}"
		echo -e "${BLUE}Would push '${DEV_BRANCH}' to '${REMOTE_NAME}'${NC}"
		echo -e "${BLUE}Would create PR '${DEV_BRANCH}' -> '${MAIN_BRANCH}'${NC}"
		echo -e "${BLUE}Would not create local tag${NC}"
		echo -e "${BLUE}Would not merge locally${NC}"
		echo -e "${BLUE}Would not push '${MAIN_BRANCH}'${NC}"
		if [[ "$OPEN_BROWSER" == "true" ]]; then
			echo -e "${BLUE}Would open browser for the pull request${NC}"
		fi
	else
		echo -e "${BLUE}Would switch to '${DEV_BRANCH}'${NC}"
		echo -e "${BLUE}Would pull '${DEV_BRANCH}' from '${REMOTE_NAME}'${NC}"
		echo -e "${BLUE}Would switch to '${MAIN_BRANCH}'${NC}"
		echo -e "${BLUE}Would pull '${MAIN_BRANCH}' from '${REMOTE_NAME}'${NC}"
		echo -e "${BLUE}Would merge '${DEV_BRANCH}' into '${MAIN_BRANCH}'${NC}"
		echo -e "${BLUE}Would create release tag if configured by legacy flow${NC}"
		echo -e "${BLUE}Would push '${MAIN_BRANCH}' and tags to '${REMOTE_NAME}'${NC}"
	fi
}

run_pr_flow_to_main() {
	local gh_args

	check_gh_cli_for_pr

	echo -e "${YELLOW}Creating pull request for '${DEV_BRANCH}' into '${MAIN_BRANCH}'...${NC}"

	git checkout "$DEV_BRANCH"
	git pull --ff-only "$REMOTE_NAME" "$DEV_BRANCH"

	if ! git push "$REMOTE_NAME" "$DEV_BRANCH"; then
		echo -e "${RED}❌ Error al hacer push de la rama '${DEV_BRANCH}'${NC}"
		exit 1
	fi

	gh_args=(
		pr create
		--base "$MAIN_BRANCH"
		--head "$DEV_BRANCH"
		--fill
	)

	if [[ "$OPEN_BROWSER" == "true" ]]; then
		gh_args+=(--web)
	fi

	if ! gh "${gh_args[@]}"; then
		echo -e "${RED}❌ Error al crear el Pull Request${NC}"
		exit 1
	fi

	echo -e "${GREEN}✅ Pull Request creado para '${DEV_BRANCH}' → '${MAIN_BRANCH}'${NC}"
	exit 0
}

# Procesar argumentos
process_arguments "$@"

load_git_flow_policy

if [[ "$GIT_FLOW_PRINT_POLICY_ONLY" == "true" ]]; then
	git_flow_policy_print
	exit 0
fi

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
	exit 1
fi

# ✅ Validación: debe tener un remoto configurado
if ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
	echo -e "${RED}❌ No hay un remoto '${REMOTE_NAME}' configurado.${NC}"
	echo -e "${YELLOW}💡 Sugerencia: Configura el remoto con: git remote add ${REMOTE_NAME} <url>${NC}"
	exit 1
fi

ensure_supported_flow_mode

if [[ "$GIT_FLOW_DRY_RUN" == "true" ]]; then
	print_dry_run_rel
	exit 0
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

	# Verificar si las ramas están al día
	git fetch "$REMOTE_NAME" "$source_branch" "$target_branch" >/dev/null 2>&1

	# Obtener la lista de archivos modificados en la rama source desde el último merge
	local modified_files
	modified_files=$(git diff --name-only "$target_branch...$source_branch" 2>/dev/null || echo "")
	local target_modified_files
	target_modified_files=$(git diff --name-only "$source_branch...$target_branch" 2>/dev/null || echo "")

	# Si no hay archivos modificados, no hay conflictos potenciales
	if [ -z "$modified_files" ]; then
		echo -e "${GREEN}✅ No se detectaron cambios entre las ramas${NC}"
		return 0
	fi

	# Verificar si hay archivos que podrían causar conflictos
	# Solo considerar archivos que han sido modificados en ambas ramas desde su punto común
	local potential_conflicts=()
	for file in $modified_files; do
		# Verificar si el archivo también ha sido modificado en target desde el último merge
		if printf '%s\n' "$target_modified_files" | grep -Fxq -- "$file"; then
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

	echo -e "${GREEN}✅ No se detectaron conflictos potenciales${NC}"
	return 0
}

# 🔄 Función para hacer merge con manejo de errores (sin abrir editor)
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

	# Guardar configuración actual del editor
	local old_editor
	old_editor=$(git config --get core.editor 2>/dev/null || echo "")
	local old_merge_ff
	old_merge_ff=$(git config --get merge.ff 2>/dev/null || echo "")

	# Configurar temporalmente para evitar editor completamente
	# Usar múltiples métodos para asegurar que no se abra el editor
	export GIT_MERGE_AUTOEDIT=no
	export GIT_EDITOR=true
	export EDITOR=true
	export VISUAL=true

	# Configurar git para no usar editor (a nivel local del repo)
	git config core.editor true 2>/dev/null || true
	# Temporalmente desactivar merge.ff=only para permitir merge commits
	if [ -n "$old_merge_ff" ]; then
		git config merge.ff false 2>/dev/null || true
	fi

	# Intentar el merge sin abrir editor
	# Usar todas las variables de entorno y configuraciones posibles para evitar el editor
	local merge_message="merge(${target_branch}): integrate ${source_branch}"

	# Usar -c core.editor=true directamente en el comando git para forzar la configuración
	# Esto sobrescribe cualquier configuración global o local
	# Cerrar stdin con </dev/null para evitar que git intente leer del terminal
	# Redirigir stderr a /dev/null para evitar mensajes de advertencia
	if ! (GIT_MERGE_AUTOEDIT=no GIT_EDITOR=true EDITOR=true VISUAL=true git -c core.editor=true -c merge.ff=false merge "$source_branch" --no-edit -m "$merge_message" </dev/null 2>/dev/null); then
		# Si falla, intentar sin --no-ff (puede ser fast-forward y no necesita merge commit)
		if ! (GIT_MERGE_AUTOEDIT=no GIT_EDITOR=true EDITOR=true VISUAL=true git -c core.editor=true merge "$source_branch" --no-edit -m "$merge_message" </dev/null 2>/dev/null); then
			# Si aún falla, intentar sin -m (puede que no sea necesario en fast-forward)
			if ! (GIT_MERGE_AUTOEDIT=no GIT_EDITOR=true EDITOR=true VISUAL=true git -c core.editor=true merge "$source_branch" --no-edit </dev/null 2>/dev/null); then
				# Restaurar configuración si falla
				unset GIT_MERGE_AUTOEDIT
				unset GIT_EDITOR
				unset EDITOR
				unset VISUAL
				if [ -n "$old_editor" ]; then
					git config core.editor "$old_editor" 2>/dev/null || true
				else
					git config --unset core.editor 2>/dev/null || true
				fi
				if [ -n "$old_merge_ff" ]; then
					git config merge.ff "$old_merge_ff" 2>/dev/null || true
				else
					git config --unset merge.ff 2>/dev/null || true
				fi

				echo -e "${RED}❗ Conflictos detectados entre '${source_branch}' y '${target_branch}'${NC}"
				echo -e "${YELLOW}💡 Sugerencia: Resuelve los conflictos y luego ejecuta:${NC}"
				echo -e "  git add ."
				echo -e "  git commit -m \"merge: resolve conflicts between ${source_branch} and ${target_branch}\""
				exit 1
			fi
		fi
	fi

	# Restaurar configuración después del merge exitoso
	unset GIT_MERGE_AUTOEDIT
	unset GIT_EDITOR
	unset EDITOR
	unset VISUAL
	if [ -n "$old_editor" ]; then
		git config core.editor "$old_editor" 2>/dev/null || true
	else
		git config --unset core.editor 2>/dev/null || true
	fi
	if [ -n "$old_merge_ff" ]; then
		git config merge.ff "$old_merge_ff" 2>/dev/null || true
	else
		git config --unset merge.ff 2>/dev/null || true
	fi

	# Push de los cambios
	if ! git push "$REMOTE_NAME" "$target_branch"; then
		echo -e "${RED}❗ Error al hacer push a '${target_branch}'${NC}"
		echo -e "${YELLOW}💡 Sugerencia: Asegúrate de tener permisos y que la rama no esté protegida${NC}"
		exit 1
	fi

	echo -e "${GREEN}✅ Merge completado: '${source_branch}' → '${target_branch}'${NC}"
}

# 🏷️ Función para generar versión automática
generate_version() {
	if [ -z "$VERSION" ]; then
		# Generar versión automática con formato profesional: vAAAA.MM.DD_HHMM
		# Ejemplo: v2025.12.07_1023
		VERSION=$(date +"%Y.%m.%d_%H%M")
	else
		# Si se proporciona una versión manual, asegurar que tenga el formato correcto
		# Remover el prefijo 'v' si existe para normalizar
		VERSION="${VERSION#v}"
		# Validar formato básico (debe contener al menos números y puntos/guiones bajos)
		if ! echo "$VERSION" | grep -qE '^[0-9]'; then
			echo -e "${YELLOW}⚠️  Formato de versión no reconocido, usando versión automática${NC}"
			VERSION=$(date +"%Y.%m.%d_%H%M")
		fi
	fi
	# Asegurar que el prefijo 'v' esté presente
	echo "${TAG_PREFIX}${VERSION}"
}

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Iniciando release de ${DEV_BRANCH} a ${MAIN_BRANCH}...${NC}"

# Verificar que las ramas existan localmente
if ! branch_exists "$DEV_BRANCH"; then
	echo -e "${RED}❗ La rama '${DEV_BRANCH}' no existe localmente.${NC}"
	echo -e "${BLUE}💡 Intentando obtener desde remoto...${NC}"
	if git fetch "$REMOTE_NAME" "$DEV_BRANCH" && git checkout -b "$DEV_BRANCH" "${REMOTE_NAME}/$DEV_BRANCH"; then
		echo -e "${GREEN}✅ Rama '${DEV_BRANCH}' creada desde remoto${NC}"
	else
		echo -e "${RED}❌ No se pudo obtener la rama '${DEV_BRANCH}' desde remoto${NC}"
		exit 1
	fi
fi

if ! branch_exists "$MAIN_BRANCH"; then
	echo -e "${RED}❗ La rama '${MAIN_BRANCH}' no existe localmente.${NC}"
	echo -e "${BLUE}💡 Intentando obtener desde remoto...${NC}"
	if git fetch "$REMOTE_NAME" "$MAIN_BRANCH" && git checkout -b "$MAIN_BRANCH" "${REMOTE_NAME}/$MAIN_BRANCH"; then
		echo -e "${GREEN}✅ Rama '${MAIN_BRANCH}' creada desde remoto${NC}"
	else
		echo -e "${RED}❌ No se pudo obtener la rama '${MAIN_BRANCH}' desde remoto${NC}"
		exit 1
	fi
fi

# Verificar que las ramas remotas existan
echo -e "${BLUE}🔍 Verificando ramas remotas...${NC}"
if ! git ls-remote --heads "$REMOTE_NAME" "$DEV_BRANCH" | grep -q "$DEV_BRANCH"; then
	echo -e "${RED}❗ La rama remota '${DEV_BRANCH}' no existe.${NC}"
	exit 1
fi

if ! git ls-remote --heads "$REMOTE_NAME" "$MAIN_BRANCH" | grep -q "$MAIN_BRANCH"; then
	echo -e "${RED}❗ La rama remota '${MAIN_BRANCH}' no existe.${NC}"
	exit 1
fi

echo -e "${GREEN}✅ Todas las ramas verificadas correctamente${NC}"

# Verificar estado del repositorio
check_clean_repo

run_validation_if_enabled

if [[ "$FLOW_MODE_TO_MAIN" == "pr" ]]; then
	run_pr_flow_to_main
fi

# 🔁 Paso 1: Merge de dev → main (igual que git_feat.sh)
echo -e "${YELLOW}🔁 Integrando '${DEV_BRANCH}' en '${MAIN_BRANCH}'...${NC}"

# Asegurar que dev esté actualizada antes del merge
git fetch "$REMOTE_NAME" "$DEV_BRANCH" >/dev/null 2>&1 || true

# Cambiar a main y actualizar
git checkout "$MAIN_BRANCH"
git pull "$REMOTE_NAME" "$MAIN_BRANCH"

# Verificar que HEAD está disponible antes del merge.
git rev-parse HEAD >/dev/null

# Hacer el merge
do_merge "$DEV_BRANCH" "$MAIN_BRANCH"

# 🏷️ Paso 2: Generar nombre de versión para el tag
TAG_NAME=$(generate_version)
echo -e "${YELLOW}🏷️  Creando tag '${TAG_NAME}'...${NC}"

# Verificar que estamos en main antes de crear el tag
if [ "$(git branch --show-current)" != "$MAIN_BRANCH" ]; then
	echo -e "${RED}❗ Error: No estamos en la rama '${MAIN_BRANCH}' para crear el tag${NC}"
	exit 1
fi

# Verificar si el tag ya existe
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
	echo -e "${RED}❗ El tag '${TAG_NAME}' ya existe.${NC}"
	echo -e "${YELLOW}💡 Opciones:${NC}"
	echo -e "  1. Usar una versión diferente"
	echo -e "  2. Eliminar el tag existente y recrearlo"
	echo -e "  3. Continuar sin crear tag"
	echo -e "${YELLOW}¿Qué deseas hacer? (1/2/3)${NC}"
	read -r choice
	case $choice in
	1)
		echo -e "${BLUE}💡 Ingresa una nueva versión (ej: 1.2.4):${NC}"
		read -r new_version
		TAG_NAME="${TAG_PREFIX}${new_version}"
		;;
	2)
		echo -e "${YELLOW}🗑️  Eliminando tag existente...${NC}"
		git tag -d "$TAG_NAME" 2>/dev/null || true
		git push "$REMOTE_NAME" ":refs/tags/$TAG_NAME" 2>/dev/null || true
		;;
	3)
		echo -e "${YELLOW}⚠️  Continuando sin crear tag${NC}"
		TAG_NAME=""
		;;
	*)
		echo -e "${RED}❌ Opción inválida. Saliendo...${NC}"
		exit 1
		;;
	esac
fi

# 🏷️ Paso 3: Crear tag anotado con mensaje básico
if [ -n "$TAG_NAME" ]; then
	echo -e "${BLUE}🏷️  Creando tag anotado '${TAG_NAME}' en el commit actual...${NC}"

	# Mostrar información del commit donde se creará el tag
	current_commit=$(git rev-parse HEAD)
	commit_info=$(git log -1 --pretty=format:"%h - %s (%an)" "$current_commit")
	echo -e "${BLUE}📝 Tag se creará en: ${commit_info}${NC}"

	# Crear mensaje básico para el tag (el changelog completo lo generará GitHub Actions)
	tag_date=$(date +%Y-%m-%d)
	tag_time=$(date +%H:%M)
	TAG_MESSAGE="**Release Date:** ${tag_date} ${tag_time}

Changelog will be generated automatically by GitHub Actions."

	# Crear tag anotado con mensaje básico
	if echo "$TAG_MESSAGE" | git tag -a "$TAG_NAME" -F -; then
		echo -e "${BLUE}📤 Subiendo tag a GitHub...${NC}"
		if git push "$REMOTE_NAME" "$TAG_NAME"; then
			echo -e "${GREEN}✅ Tag anotado '${TAG_NAME}' creado y subido exitosamente a GitHub.${NC}"

			# Verificar que el tag se subió correctamente
			echo -e "${BLUE}🔍 Verificando tag en GitHub...${NC}"
			if git ls-remote --tags "$REMOTE_NAME" | grep -q "$TAG_NAME"; then
				echo -e "${GREEN}✅ Tag '${TAG_NAME}' confirmado en GitHub.${NC}"
			else
				echo -e "${YELLOW}⚠️  No se pudo verificar el tag en GitHub, pero el push fue exitoso${NC}"
			fi
		else
			echo -e "${RED}❌ Error al subir el tag a GitHub${NC}"
			echo -e "${YELLOW}💡 Sugerencia: Verifica permisos y conexión a GitHub${NC}"
			exit 1
		fi
	else
		echo -e "${RED}❌ Error al crear el tag localmente${NC}"
		exit 1
	fi
else
	echo -e "${YELLOW}⚠️  No se creó ningún tag${NC}"
fi

# 🔍 Verificación final: confirmar que estamos en main
echo -e "${BLUE}🔍 Verificación final...${NC}"
if [ "$(git branch --show-current)" = "$MAIN_BRANCH" ]; then
	echo -e "${GREEN}✅ Estamos en la rama correcta: ${MAIN_BRANCH}${NC}"

	# Mostrar los últimos commits en main
	echo -e "${BLUE}📝 Últimos commits en '${MAIN_BRANCH}':${NC}"
	git log --oneline -3 "$MAIN_BRANCH"
else
	echo -e "${RED}❌ Error: No estamos en la rama '${MAIN_BRANCH}'${NC}"
	echo -e "${YELLOW}💡 Rama actual: $(git branch --show-current)${NC}"
fi

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Release completado exitosamente!${NC}"
echo -e "${BLUE}📋 Resumen:${NC}"
echo -e "  • ${DEV_BRANCH} → ${MAIN_BRANCH} ✅"
if [ -n "$TAG_NAME" ]; then
	repo_url=$(git remote get-url "$REMOTE_NAME" | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')
	echo -e "  • Tag anotado creado: ${TAG_NAME} ✅"
	echo -e "  • Tag en GitHub: https://github.com/${repo_url}/releases/tag/${TAG_NAME}"
	echo -e "  • Changelog y release: Se generarán automáticamente por GitHub Actions 🔄"
	echo -e "${YELLOW}💡 Nota: El changelog completo aparecerá en el Release de GitHub, no en el tag${NC}"
	echo -e "${BLUE}   Verifica el workflow en: https://github.com/${repo_url}/actions${NC}"
else
	echo -e "  • Tag: No creado ⚠️"
fi
echo -e "${BLUE}💡 Próximo paso: Deploy a producción${NC}"
