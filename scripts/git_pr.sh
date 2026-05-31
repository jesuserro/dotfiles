#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
DEV_BRANCH="dev"          # Rama de desarrollo
FEATURE_PREFIX="feature/" # Prefijo estándar para ramas de features
FEATURE_BRANCH=""         # Rama feature final a usar (resuelta más abajo)
OPEN_BROWSER=true         # Abrir navegador automáticamente

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# 🔍 Procesar argumentos
process_arguments() {
	local input_name=""

	while [[ $# -gt 0 ]]; do
		case $1 in
		--help | -h)
			echo -e "${BLUE}📖 Uso: git pr <nombre-feature> [opciones]${NC}"
			echo -e "${BLUE}📖 Descripción: Crea un Pull Request de una rama feature a dev${NC}"
			echo -e "${BLUE}📖 Ejemplos:${NC}"
			echo -e "  git pr mi-nueva-funcionalidad     # Rama 'feature/mi-nueva-funcionalidad'"
			echo -e "  git pr feature/login-system       # Rama 'feature/login-system'"
			echo -e "  git pr login-system               # Rama 'feature/login-system'"
			echo -e "${BLUE}📖 Opciones:${NC}"
			echo -e "  --no-open                         # No abrir el PR en el navegador"
			echo -e "  --help, -h                        # Mostrar esta ayuda"
			echo -e "${BLUE}📖 Flujo:${NC}"
			echo -e "  1. Detecta la rama feature"
			echo -e "  2. Verifica que existe localmente y en remoto"
			echo -e "  3. Genera título y descripción automáticamente"
			echo -e "  4. Crea el Pull Request en GitHub"
			echo -e "  5. Abre el PR en el navegador (opcional)"
			exit 0
			;;
		--no-open)
			OPEN_BROWSER=false
			shift
			;;
		*)
			if [ -z "$input_name" ]; then
				input_name="$1"
			else
				echo -e "${RED}❗ Argumento desconocido: $1${NC}"
				echo -e "${BLUE}💡 Usa 'git pr --help' para ver las opciones${NC}"
				exit 1
			fi
			shift
			;;
		esac
	done

	echo "$input_name"
}

# Procesar argumentos y obtener el nombre de la feature
INPUT_NAME=$(process_arguments "$@")

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
	exit 1
fi

# 🧠 Verifica si una rama existe localmente
branch_exists() {
	git rev-parse --verify "$1" >/dev/null 2>&1
}

# 🔍 Verifica si una rama existe en el remoto
branch_exists_remote() {
	git ls-remote --heads origin "$1" >/dev/null 2>&1
}

# 🔍 Verifica si GitHub CLI está instalado
check_gh_cli() {
	if ! command -v gh &>/dev/null; then
		echo -e "${RED}❌ GitHub CLI (gh) no está instalado.${NC}"
		echo -e "${YELLOW}💡 Instala GitHub CLI: https://cli.github.com/${NC}"
		exit 1
	fi

	# Verificar que está autenticado
	if ! gh auth status &>/dev/null; then
		echo -e "${RED}❌ GitHub CLI no está autenticado.${NC}"
		echo -e "${YELLOW}💡 Ejecuta: gh auth login${NC}"
		exit 1
	fi
}

# 📝 Genera el título del PR automáticamente
generate_pr_title() {
	local feature_branch="$1"
	local base_branch="$2"

	# Intentar extraer del primer commit siguiendo Conventional Commits
	local first_commit
	first_commit=$(git log --pretty=format:"%s" "${base_branch}..${feature_branch}" 2>/dev/null | head -n 1)

	if [ -n "$first_commit" ]; then
		# Si el commit sigue Conventional Commits, usar su mensaje
		if [[ "$first_commit" =~ ^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: ]]; then
			echo "$first_commit"
			return
		fi
	fi

	# Fallback: formatear nombre de la rama
	local clean_name
	clean_name=$(echo "$feature_branch" | sed "s|^${FEATURE_PREFIX}||" | sed 's/-/ /g')
	# Capitalizar primera letra
	echo "$clean_name" | awk '{for(i=1;i<=NF;i++){sub(/./,toupper(substr($i,1,1)),$i)};print}'
}

# 📄 Genera la descripción del PR automáticamente
generate_pr_description() {
	local feature_branch="$1"
	local base_branch="$2"

	local description=""

	# Obtener estadísticas
	local stats
	stats=$(git diff --stat "${base_branch}..${feature_branch}" 2>/dev/null | tail -n 1)
	local total_commits
	total_commits=$(git rev-list --count "${base_branch}..${feature_branch}" 2>/dev/null || echo "0")

	# Obtener lista de commits
	local commits
	commits=$(git log --pretty=format:"- %s" "${base_branch}..${feature_branch}" 2>/dev/null)

	# Obtener archivos modificados
	local files
	files=$(git diff --name-status "${base_branch}..${feature_branch}" 2>/dev/null | head -n 20)

	# Construir descripción
	description="## 📊 Estadísticas\n\n"
	description+="- **Commits:** ${total_commits}\n"
	description+="- **Estadísticas:** ${stats}\n\n"

	if [ -n "$commits" ]; then
		description+="## 📝 Commits\n\n"
		description+="${commits}\n\n"
	fi

	if [ -n "$files" ]; then
		description+="## 📁 Archivos Modificados\n\n"
		description+="\`\`\`\n"
		description+="${files}\n"
		description+="\`\`\`\n"
	fi

	echo -e "$description"
}

# 📤 Verifica y hace push de la rama si no está en remoto
ensure_remote_branch() {
	local feature_branch="$1"

	if ! branch_exists_remote "$feature_branch"; then
		echo -e "${YELLOW}📤 La rama '${feature_branch}' no existe en el remoto. Haciendo push...${NC}"
		if ! git push --set-upstream origin "$feature_branch"; then
			echo -e "${RED}❌ Error al hacer push de la rama '${feature_branch}'${NC}"
			exit 1
		fi
		echo -e "${GREEN}✅ Rama '${feature_branch}' publicada en remoto${NC}"
	else
		echo -e "${GREEN}✅ Rama '${feature_branch}' ya existe en remoto${NC}"
	fi
}

# 🔍 Verifica si ya existe un PR para esta rama
pr_exists() {
	local feature_branch="$1"
	local base_branch="$2"

	# Verificar si hay un PR abierto para esta rama
	if gh pr list --base "$base_branch" --head "$feature_branch" --state open --json number --jq 'length' 2>/dev/null | grep -q '[1-9]'; then
		return 0
	fi
	return 1
}

# 🚀 Crea el Pull Request
create_pull_request() {
	local feature_branch="$1"
	local base_branch="$2"

	# Verificar si ya existe un PR
	if pr_exists "$feature_branch" "$base_branch"; then
		echo -e "${YELLOW}⚠️  Ya existe un Pull Request abierto para '${feature_branch}' → '${base_branch}'${NC}"
		local pr_url
		pr_url=$(gh pr list --base "$base_branch" --head "$feature_branch" --state open --json url --jq '.[0].url' 2>/dev/null)
		if [ -n "$pr_url" ]; then
			echo -e "${BLUE}🔗 PR existente: ${pr_url}${NC}"
			if [ "$OPEN_BROWSER" = true ]; then
				echo -e "${YELLOW}🌐 Abriendo PR en el navegador...${NC}"
				gh pr view "$feature_branch" --web 2>/dev/null || true
			fi
		fi
		exit 0
	fi

	# Generar título y descripción
	echo -e "${YELLOW}📝 Generando título y descripción del PR...${NC}"
	local pr_title
	pr_title=$(generate_pr_title "$feature_branch" "$base_branch")
	local pr_description
	pr_description=$(generate_pr_description "$feature_branch" "$base_branch")

	echo -e "${BLUE}📋 Título: ${pr_title}${NC}"

	# Crear el PR
	echo -e "${YELLOW}🚀 Creando Pull Request '${feature_branch}' → '${base_branch}'...${NC}"

	local pr_url=""
	if [ "$OPEN_BROWSER" = true ]; then
		pr_url=$(gh pr create --base "$base_branch" --head "$feature_branch" --title "$pr_title" --body "$pr_description" --web 2>&1)
	else
		pr_url=$(gh pr create --base "$base_branch" --head "$feature_branch" --title "$pr_title" --body "$pr_description" 2>&1)
	fi

	if [ $? -eq 0 ]; then
		echo -e "${GREEN}✅ Pull Request creado exitosamente${NC}"
		if [ "$OPEN_BROWSER" = false ]; then
			# Extraer URL del output si no se abrió el navegador
			local extracted_url
			extracted_url=$(echo "$pr_url" | grep -o 'https://github.com[^ ]*' | head -n 1)
			if [ -n "$extracted_url" ]; then
				echo -e "${BLUE}🔗 PR: ${extracted_url}${NC}"
			else
				echo -e "${BLUE}🔗 ${pr_url}${NC}"
			fi
		fi
	else
		echo -e "${RED}❌ Error al crear el Pull Request${NC}"
		echo -e "${YELLOW}💡 Verifica que tienes permisos y que la rama existe en el remoto${NC}"
		exit 1
	fi
}

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Creando Pull Request para feature '${INPUT_NAME}'...${NC}"

# 📛 Validación de argumentos
if [ -z "$INPUT_NAME" ]; then
	echo -e "${RED}❗ ERROR: Debes pasar el nombre de la rama feature como argumento.${NC}"
	echo "👉 Ejemplo: git pr mi-nueva-funcionalidad"
	echo "👉 O usa: git pr --help"
	exit 1
fi

# Verificar GitHub CLI
check_gh_cli

# 🔍 Detección automática: resuelve si la rama tiene o no prefijo
if branch_exists "$INPUT_NAME"; then
	FEATURE_BRANCH="$INPUT_NAME"
elif branch_exists "${FEATURE_PREFIX}${INPUT_NAME}"; then
	FEATURE_BRANCH="${FEATURE_PREFIX}${INPUT_NAME}"
else
	echo -e "${RED}❗ La rama '${INPUT_NAME}' ni '${FEATURE_PREFIX}${INPUT_NAME}' existe localmente.${NC}"
	exit 1
fi

# Verificar que la rama base existe
if ! branch_exists "$DEV_BRANCH"; then
	echo -e "${RED}❗ La rama base '${DEV_BRANCH}' no existe localmente.${NC}"
	exit 1
fi

# Verificar que la rama base existe en remoto
if ! branch_exists_remote "$DEV_BRANCH"; then
	echo -e "${YELLOW}⚠️  La rama base '${DEV_BRANCH}' no existe en el remoto.${NC}"
	echo -e "${YELLOW}💡 Asegúrate de que la rama base existe en GitHub${NC}"
fi

# Asegurar que la rama feature está en el remoto
ensure_remote_branch "$FEATURE_BRANCH"

# Crear el Pull Request
create_pull_request "$FEATURE_BRANCH" "$DEV_BRANCH"
