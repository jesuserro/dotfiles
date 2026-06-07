#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/git_flow_policy.sh
source "${SCRIPT_DIR}/lib/git_flow_policy.sh"

# 📦 Configuración básica
DEV_BRANCH="dev"                 # Rama de desarrollo
FEATURE_PREFIX="feature/"        # Prefijo estándar para ramas de features
FEATURE_BRANCH=""                # Rama feature final a usar (resuelta más abajo)
ARCHIVE_PREFIX="archive/"        # Prefijo para archivar ramas
GENERATE_CHANGELOG=true          # Generar changelog automáticamente
GIT_FLOW_REPO_ROOT=""            # Raíz del repo donde se busca la policy
GIT_FLOW_PRINT_POLICY_ONLY=false # Modo diagnóstico sin operaciones productivas
GIT_FLOW_DRY_RUN=false           # Inspección sin push, merge, PR ni changelog
INPUT_NAME=""                    # Nombre de feature recibido por argumento

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
			echo -e "${BLUE}📖 Uso: git feat [nombre-feature] [opciones]${NC}"
			echo -e "${BLUE}📖 Descripción: Integra una rama feature en dev y la archiva${NC}"
			echo -e "${BLUE}📖 Ejemplos:${NC}"
			echo -e "  git feat                         # Usa la rama feature actual"
			echo -e "  git feat mi-nueva-funcionalidad     # Rama 'feature/mi-nueva-funcionalidad'"
			echo -e "  git feat feature/login-system       # Rama 'feature/login-system'"
			echo -e "  git feat login-system               # Rama 'feature/login-system'"
			echo -e "${BLUE}📖 Opciones:${NC}"
			echo -e "  --no-changelog                      # No generar changelog automáticamente"
			echo -e "  --print-policy                      # Imprimir la policy efectiva y salir"
			echo -e "  --dry-run                           # Mostrar acciones sin ejecutarlas"
			echo -e "  --help, -h                          # Mostrar esta ayuda"
			echo -e "${BLUE}📖 Flujo:${NC}"
			echo -e "  1. Resuelve la rama feature por argumento o por rama actual"
			echo -e "  2. Se mueve a rama 'dev'"
			echo -e "  3. Hace merge de tu feature en dev"
			echo -e "  4. Genera changelog de la feature después del merge (opcional)"
			echo -e "  5. Archiva tu rama feature"
			echo -e "  6. Termina en rama 'dev'"
			exit 0
			;;
		--no-changelog)
			GENERATE_CHANGELOG=false
			shift
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
			if [ -z "$INPUT_NAME" ]; then
				INPUT_NAME="$1"
			else
				echo -e "${RED}❗ Argumento desconocido: $1${NC}"
				echo -e "${BLUE}💡 Usa 'git feat --help' para ver las opciones${NC}"
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
	FEATURE_PREFIX="$FEATURE_BRANCH_PREFIX"
}

ensure_supported_flow_mode() {
	case "$FLOW_MODE_TO_DEV" in
	local | pr | pr_auto | pr_immediate)
		return 0
		;;
	*)
		echo -e "${RED}❌ Unsupported git feat flow mode: FLOW_MODE_TO_DEV=${FLOW_MODE_TO_DEV}${NC}"
		exit 1
		;;
	esac
}

run_validation_if_enabled() {
	if [[ "$VALIDATE_TO_DEV" == "true" ]]; then
		if [[ "$GIT_FLOW_DRY_RUN" == "true" ]]; then
			echo -e "${BLUE}Would run validation: ${VALIDATE_CMD_TO_DEV}${NC}"
			return 0
		fi
		echo -e "${BLUE}Running validation: ${VALIDATE_CMD_TO_DEV}${NC}"
		if ! (cd "$GIT_FLOW_REPO_ROOT" && bash -c "$VALIDATE_CMD_TO_DEV"); then
			echo -e "${RED}❌ Validation failed: ${VALIDATE_CMD_TO_DEV}${NC}"
			exit 1
		fi
	fi
}

resolve_feature_branch_name() {
	if branch_exists "$INPUT_NAME"; then
		FEATURE_BRANCH="$INPUT_NAME"
	elif branch_exists "${FEATURE_PREFIX}${INPUT_NAME}"; then
		FEATURE_BRANCH="${FEATURE_PREFIX}${INPUT_NAME}"
	else
		echo -e "${RED}❗ La rama '${INPUT_NAME}' ni '${FEATURE_PREFIX}${INPUT_NAME}' existe localmente.${NC}"
		exit 1
	fi
}

print_dry_run_feat_local() {
	resolve_feature_branch_name
	echo -e "${BLUE}DRY RUN: git feat local flow${NC}"
	run_validation_if_enabled
	echo -e "${BLUE}Would switch to '${DEV_BRANCH}'${NC}"
	echo -e "${BLUE}Would pull '${DEV_BRANCH}' from '${REMOTE_NAME}'${NC}"
	echo -e "${BLUE}Would merge '${FEATURE_BRANCH}' into '${DEV_BRANCH}'${NC}"
	echo -e "${BLUE}Would push '${DEV_BRANCH}' to '${REMOTE_NAME}'${NC}"
	if [[ "$GENERATE_CHANGELOG" == "true" ]]; then
		echo -e "${BLUE}Would generate feature changelog${NC}"
	fi
	if [[ "$DELETE_FEATURE_BRANCH" == "true" ]]; then
		echo -e "${BLUE}Would archive/delete feature branch '${FEATURE_BRANCH}'${NC}"
	else
		echo -e "${BLUE}Would preserve feature branch '${FEATURE_BRANCH}'${NC}"
	fi
}

print_dry_run_feat_pr() {
	echo -e "${BLUE}DRY RUN: git feat PR flow (${FLOW_MODE_TO_DEV})${NC}"
	run_validation_if_enabled
	echo -e "${BLUE}Would push current feature branch '${FEATURE_BRANCH}' to '${REMOTE_NAME}'${NC}"
	echo -e "${BLUE}Would create PR '${FEATURE_BRANCH}' -> '${DEV_BRANCH}'${NC}"
	case "$FLOW_MODE_TO_DEV" in
	pr)
		echo -e "${BLUE}Would leave PR open for manual review${NC}"
		;;
	pr_auto)
		echo -e "${BLUE}Would enable auto-merge using strategy: ${MERGE_STRATEGY_TO_DEV}${NC}"
		;;
	pr_immediate)
		echo -e "${BLUE}Would merge PR immediately using strategy: ${MERGE_STRATEGY_TO_DEV}${NC}"
		;;
	esac
	if [[ "$OPEN_BROWSER" == "true" ]]; then
		echo -e "${BLUE}Would open browser for the pull request${NC}"
	fi
}

resolve_feature_input_name() {
	local current_branch

	if [[ -n "$INPUT_NAME" ]]; then
		return 0
	fi

	current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

	if [[ -z "$current_branch" || "$current_branch" == "HEAD" ]]; then
		echo "ERROR: git feat without a branch argument requires a named current branch." >&2
		exit 1
	fi

	if [[ "$current_branch" != "$FEATURE_PREFIX"* ]]; then
		echo "ERROR: git feat without a branch argument must be run from a ${FEATURE_PREFIX} branch." >&2
		echo "Current branch: ${current_branch}" >&2
		echo "Expected prefix: ${FEATURE_PREFIX}" >&2
		exit 1
	fi

	INPUT_NAME="$current_branch"
}

check_gh_cli_for_pr() {
	if ! command -v gh &>/dev/null; then
		echo -e "${RED}ERROR: PR flow modes require GitHub CLI (\`gh\`).${NC}"
		exit 1
	fi
}

resolve_current_feature_branch_for_pr() {
	local current_branch expected_branch
	current_branch="$(git branch --show-current)"

	if [[ -z "$current_branch" ]]; then
		echo -e "${RED}❌ PR mode requires a named current branch.${NC}" >&2
		exit 1
	fi

	if [[ "$current_branch" != "$FEATURE_PREFIX"* ]]; then
		echo -e "${RED}❌ PR mode requires current branch to start with '${FEATURE_PREFIX}': ${current_branch}${NC}" >&2
		exit 1
	fi

	if [[ "$INPUT_NAME" == "$FEATURE_PREFIX"* ]]; then
		expected_branch="$INPUT_NAME"
	else
		expected_branch="${FEATURE_PREFIX}${INPUT_NAME}"
	fi

	if [[ "$current_branch" != "$expected_branch" ]]; then
		echo -e "${RED}❌ PR mode must run from '${expected_branch}' (current: '${current_branch}').${NC}" >&2
		exit 1
	fi

	printf '%s\n' "$current_branch"
}

run_pr_flow_to_dev() {
	local gh_args

	FEATURE_BRANCH="$(resolve_current_feature_branch_for_pr)"

	if [[ "$GIT_FLOW_DRY_RUN" == "true" ]]; then
		print_dry_run_feat_pr
		exit 0
	fi

	check_clean_repo
	run_validation_if_enabled
	check_gh_cli_for_pr

	echo -e "${YELLOW}Creating pull request for '${FEATURE_BRANCH}' into '${DEV_BRANCH}'...${NC}"

	if ! git push -u "$REMOTE_NAME" "$FEATURE_BRANCH"; then
		echo -e "${RED}❌ Error al hacer push de la rama '${FEATURE_BRANCH}'${NC}"
		exit 1
	fi

	gh_args=(
		pr create
		--base "$DEV_BRANCH"
		--head "$FEATURE_BRANCH"
		--title "$FEATURE_BRANCH"
		--body "Created by git feat policy flow."
	)

	if [[ "$OPEN_BROWSER" == "true" ]]; then
		gh_args+=(--web)
	fi

	if ! gh "${gh_args[@]}"; then
		echo -e "${RED}❌ Error al crear el Pull Request${NC}"
		exit 1
	fi

	if [[ "$FLOW_MODE_TO_DEV" != "pr" ]]; then
		echo -e "${YELLOW}Applying PR merge policy (${FLOW_MODE_TO_DEV}, strategy=${MERGE_STRATEGY_TO_DEV})...${NC}"
		if ! git_flow_policy_run_pr_merge "$FLOW_MODE_TO_DEV" "$MERGE_STRATEGY_TO_DEV" "$FEATURE_BRANCH"; then
			echo -e "${RED}❌ Error al aplicar merge del Pull Request${NC}"
			exit 1
		fi
	fi

	echo -e "${GREEN}✅ Pull Request creado para '${FEATURE_BRANCH}' → '${DEV_BRANCH}'${NC}"
	exit 0
}

# Procesar argumentos y obtener el nombre de la feature
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
	local modified_files
	modified_files=$(git diff --name-only "$target_branch...$source_branch")

	# Verificar si hay archivos que podrían causar conflictos
	local potential_conflicts=()
	for file in $modified_files; do
		if git diff --name-only "$target_branch" | grep -Fxq -- "$file"; then
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
	if ! git push "$REMOTE_NAME" "$target_branch"; then
		echo -e "${RED}❗ Error al hacer push a '${target_branch}'${NC}"
		echo -e "${YELLOW}💡 Sugerencia: Asegúrate de tener permisos y que la rama no esté protegida${NC}"
		exit 1
	fi

	echo -e "${GREEN}✅ Merge completado: '${source_branch}' → '${target_branch}'${NC}"
}

# 📝 Función para generar changelog de la feature después del merge
generate_feature_changelog() {
	local feature_branch="$1"
	local base_branch="$2"
	local base_commit="$3" # Commit de base antes del merge

	if [ "$GENERATE_CHANGELOG" = true ]; then
		echo -e "${YELLOW}📝 Generando changelog de la feature después del merge...${NC}"

		# Crear directorio de releases si no existe
		local releases_dir
		releases_dir="$(git rev-parse --show-toplevel)/releases"
		if [ ! -d "$releases_dir" ]; then
			mkdir -p "$releases_dir"
		fi

		# Crear nombre de archivo seguro para la feature
		local safe_branch_name
		safe_branch_name="${feature_branch//[^a-zA-Z0-9._-]/_}"
		local changelog_file="$releases_dir/branch_${safe_branch_name}.md"

		# Obtener fecha y hora actual
		local current_date
		current_date=$(date +%Y-%m-%d)
		local current_time
		current_time=$(date +%H:%M)

		# Obtener información de la feature usando el commit base antes del merge
		local total_commits
		total_commits=$(git rev-list --count "${base_commit}..${feature_branch}" 2>/dev/null || echo "0")

		# Generar contenido del changelog (commits exclusivos de la feature usando el commit base)
		local changelog_content
		changelog_content=$(git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" "${base_commit}..${feature_branch}" 2>/dev/null || echo "# No se pudieron obtener commits exclusivos")

		# Crear archivo de changelog
		cat >"$changelog_file" <<EOF
# Feature Changelog: ${feature_branch}

**Fecha de integración:** ${current_date}  
**Rama base:** ${base_branch}

## Changes

${changelog_content}

## Technical Details
- Feature branch: ${feature_branch}
- Base branch: ${base_branch}
- Total commits: ${total_commits}
- Integrated: ${current_date} ${current_time}
- Status: Integrated into ${base_branch}
EOF

		echo -e "${GREEN}✅ Changelog de feature generado: ${changelog_file}${NC}"
		echo -e "${BLUE}📊 Estadísticas:${NC}"
		echo -e "  • Commits exclusivos: ${total_commits}"
		echo -e "  • Rama base: ${base_branch}"
		echo -e "  • Archivo: ${changelog_file}"
	fi
}

ensure_supported_flow_mode

resolve_feature_input_name

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Integrando feature '${INPUT_NAME}' en ${DEV_BRANCH}...${NC}"

if git_flow_policy_is_pr_mode "$FLOW_MODE_TO_DEV"; then
	run_pr_flow_to_dev
fi

if [[ "$GIT_FLOW_DRY_RUN" == "true" ]]; then
	print_dry_run_feat_local
	exit 0
fi

resolve_feature_branch_name

# Verificar estado del repositorio
check_clean_repo

run_validation_if_enabled

# 🔁 Merge de feature → dev
echo -e "${YELLOW}🔁 Integrando '${FEATURE_BRANCH}' en '${DEV_BRANCH}'...${NC}"
git checkout "$DEV_BRANCH"
git pull "$REMOTE_NAME" "$DEV_BRANCH"

# Guardar el commit actual de dev antes del merge (para poder obtener commits exclusivos después)
BASE_COMMIT=$(git rev-parse HEAD)

# Hacer el merge primero
do_merge "$FEATURE_BRANCH" "$DEV_BRANCH"

# 📝 Generar changelog de la feature DESPUÉS del merge (usando el commit base guardado)
generate_feature_changelog "$FEATURE_BRANCH" "$DEV_BRANCH" "$BASE_COMMIT"

if [[ "$DELETE_FEATURE_BRANCH" == "true" ]]; then
	# 📦 Archivar la rama feature
	ARCHIVE_BRANCH="${ARCHIVE_PREFIX}${FEATURE_BRANCH}"
	echo -e "${YELLOW}📦 Archivando rama '${FEATURE_BRANCH}' como '${ARCHIVE_BRANCH}'...${NC}"
	git branch -m "$FEATURE_BRANCH" "$ARCHIVE_BRANCH"          # Renombrado local
	git push "$REMOTE_NAME" "$ARCHIVE_BRANCH"                  # Subida rama archivada
	git push "$REMOTE_NAME" --delete "$FEATURE_BRANCH" || true # Eliminación en remoto (ignora error si no existe)
	echo -e "${GREEN}✅ Rama archivada como '${ARCHIVE_BRANCH}' y eliminada la original del remoto.${NC}"
else
	echo -e "${BLUE}INFO: Feature branch preserved by policy: ${FEATURE_BRANCH}${NC}"
fi

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Feature '${INPUT_NAME}' integrada exitosamente en ${DEV_BRANCH}!${NC}"
echo -e "${BLUE}💡 Próximo paso: Cuando dev esté listo para producción, ejecuta 'git rel'${NC}"
