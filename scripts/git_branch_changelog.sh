#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
PROJECT_ROOT=$(git rev-parse --show-toplevel)
RELEASES_DIR="$PROJECT_ROOT/releases"
CURRENT_BRANCH=$(git branch --show-current)
BASE_BRANCH="dev"          # Rama base para comparar (configurable)
CHANGELOG_PREFIX="branch_" # Prefijo para archivos de changelog de ramas

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

# 🧠 Verifica si una rama existe
branch_exists() {
	git rev-parse --verify "$1" >/dev/null 2>&1
}

# 🔍 Procesar argumentos
process_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--base | -b)
			BASE_BRANCH="$2"
			shift 2
			;;
		--help | -h)
			echo -e "${BLUE}📖 Uso: git branch-changelog [opciones]${NC}"
			echo -e "${BLUE}📖 Descripción: Genera changelog para la rama actual${NC}"
			echo -e "${BLUE}📖 Ejemplos:${NC}"
			echo -e "  git branch-changelog                    # Rama actual vs dev"
			echo -e "  git branch-changelog --base main        # Rama actual vs main"
			echo -e "  git branch-changelog -b feature/login   # Rama actual vs feature/login"
			echo -e "${BLUE}📖 Opciones:${NC}"
			echo -e "  --base, -b <rama>                       # Rama base para comparar (default: dev)"
			echo -e "  --help, -h                              # Mostrar esta ayuda"
			exit 0
			;;
		*)
			echo -e "${RED}❗ Argumento desconocido: $1${NC}"
			echo -e "${BLUE}💡 Usa 'git branch-changelog --help' para ver las opciones${NC}"
			exit 1
			;;
		esac
	done
}

# Procesar argumentos
process_arguments "$@"

# 📝 Función para generar contenido del changelog desde commits
generate_changelog_content() {
	local from_branch="$1"
	local to_branch="$2"

	if [ -n "$from_branch" ] && branch_exists "$from_branch"; then
		echo -e "${BLUE}📝 Generando changelog desde ${from_branch} hasta ${to_branch}...${NC}"
		git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" "${from_branch}..${to_branch}" 2>/dev/null ||
			git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" "${from_branch}..HEAD" 2>/dev/null
	else
		echo -e "${BLUE}📝 Generando changelog completo de ${to_branch}...${NC}"
		git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" --reverse
	fi
}

# 📊 Función para categorizar commits (Conventional Commits)
categorize_commits() {
	local content="$1"

	# Crear archivos temporales para cada categoría
	local feat_file=$(mktemp)
	local fix_file=$(mktemp)
	local docs_file=$(mktemp)
	local style_file=$(mktemp)
	local refactor_file=$(mktemp)
	local test_file=$(mktemp)
	local chore_file=$(mktemp)
	local other_file=$(mktemp)

	# Procesar cada línea
	local tmp_content=$(mktemp)
	echo "$content" >"$tmp_content"
	while IFS= read -r line; do
		case "$line" in
		"- "*feature* | "- "*feat*)
			echo "$line" >>"$feat_file"
			;;
		"- "*"fix"*)
			echo "$line" >>"$fix_file"
			;;
		"- "*"docs"*)
			echo "$line" >>"$docs_file"
			;;
		"- "*"style"*)
			echo "$line" >>"$style_file"
			;;
		"- "*"refactor"*)
			echo "$line" >>"$refactor_file"
			;;
		"- "*"test"*)
			echo "$line" >>"$test_file"
			;;
		"- "*"chore"*)
			echo "$line" >>"$chore_file"
			;;
		"-"*)
			echo "$line" >>"$other_file"
			;;
		esac
	done <"$tmp_content"
	rm -f "$tmp_content"

	# Generar contenido categorizado
	local categorized_content=""

	if [ -s "$feat_file" ]; then
		categorized_content+="### Added\n"
		categorized_content+="$(cat "$feat_file")\n\n"
	fi

	if [ -s "$fix_file" ]; then
		categorized_content+="### Fixed\n"
		categorized_content+="$(cat "$fix_file")\n\n"
	fi

	if [ -s "$docs_file" ]; then
		categorized_content+="### Documentation\n"
		categorized_content+="$(cat "$docs_file")\n\n"
	fi

	if [ -s "$refactor_file" ]; then
		categorized_content+="### Refactored\n"
		categorized_content+="$(cat "$refactor_file")\n\n"
	fi

	if [ -s "$test_file" ]; then
		categorized_content+="### Tests\n"
		categorized_content+="$(cat "$test_file")\n\n"
	fi

	if [ -s "$style_file" ]; then
		categorized_content+="### Style\n"
		categorized_content+="$(cat "$style_file")\n\n"
	fi

	if [ -s "$chore_file" ]; then
		categorized_content+="### Technical\n"
		categorized_content+="$(cat "$chore_file")\n\n"
	fi

	if [ -s "$other_file" ]; then
		categorized_content+="### Other\n"
		categorized_content+="$(cat "$other_file")\n\n"
	fi

	# Limpiar archivos temporales
	rm -f "$feat_file" "$fix_file" "$docs_file" "$style_file" "$refactor_file" "$test_file" "$chore_file" "$other_file"

	echo "$categorized_content"
}

# 📁 Función para crear directorio de releases
create_releases_directory() {
	if [ ! -d "$RELEASES_DIR" ]; then
		echo -e "${BLUE}📁 Creando directorio de releases...${NC}"
		mkdir -p "$RELEASES_DIR"
	fi
}

# 📄 Función para generar changelog de la rama actual
generate_branch_changelog() {
	local branch_name="$1"
	local base_branch="$2"

	# Crear nombre de archivo seguro para la rama
	local safe_branch_name=$(echo "$branch_name" | sed 's/[^a-zA-Z0-9._-]/_/g')
	local changelog_file="$RELEASES_DIR/${CHANGELOG_PREFIX}${safe_branch_name}.md"

	echo -e "${YELLOW}📄 Generando changelog para rama: ${branch_name}${NC}"
	echo -e "${BLUE}📁 Archivo: ${changelog_file}${NC}"

	# Obtener fecha y hora actual
	local current_date=$(date +%Y-%m-%d)
	local current_time=$(date +%H:%M)

	# Obtener información de la rama
	local total_commits=$(git rev-list --count "${base_branch}..${branch_name}" 2>/dev/null || echo "0")

	# Generar contenido del changelog con formato mejorado
	local changelog_content=""
	if [ -n "$base_branch" ] && branch_exists "$base_branch"; then
		changelog_content=$(git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" "${base_branch}..${branch_name}" 2>/dev/null ||
			git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" "${base_branch}..HEAD" 2>/dev/null)
	else
		changelog_content=$(git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" --reverse)
	fi

	# Crear archivo de changelog
	cat >"$changelog_file" <<EOF
# Branch Changelog: ${branch_name}

**Fecha de generación:** ${current_date}  
**Rama base:** ${base_branch}

## Changes

${changelog_content}

## Technical Details
- Branch: ${branch_name}
- Base branch: ${base_branch}
- Total commits: ${total_commits}
- Generated: ${current_date} ${current_time}
EOF

	echo -e "${GREEN}✅ Changelog generado: ${changelog_file}${NC}"
	echo -e "${BLUE}📊 Estadísticas:${NC}"
	echo -e "  • Commits totales: ${total_commits}"
	echo -e "  • Rama base: ${base_branch}"
	echo -e "  • Archivo: ${changelog_file}"
}

# 🔍 Función para mostrar información de la rama actual
show_branch_info() {
	echo -e "${BLUE}🔍 Información de la rama actual:${NC}"
	echo -e "  • Rama actual: ${CURRENT_BRANCH}"
	echo -e "  • Rama base: ${BASE_BRANCH}"

	if branch_exists "$BASE_BRANCH"; then
		local commits_ahead=$(git rev-list --count "${BASE_BRANCH}..${CURRENT_BRANCH}" 2>/dev/null || echo "0")
		local commits_behind=$(git rev-list --count "${CURRENT_BRANCH}..${BASE_BRANCH}" 2>/dev/null || echo "0")
		echo -e "  • Commits adelante: ${commits_ahead}"
		echo -e "  • Commits atrás: ${commits_behind}"
	else
		echo -e "  • ⚠️  La rama base '${BASE_BRANCH}' no existe"
	fi
	echo ""
}

# 🚀 Función principal
main() {
	echo -e "${YELLOW}🚀 Generando changelog para la rama actual...${NC}"

	# Mostrar información de la rama
	show_branch_info

	# Validar que no estemos en la rama base
	if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
		echo -e "${YELLOW}⚠️  Ya estás en la rama base '${BASE_BRANCH}'.${NC}"
		echo -e "${BLUE}💡 Sugerencia: Cambia a una rama feature o especifica otra rama base con --base${NC}"
		exit 1
	fi

	# Crear directorio de releases
	create_releases_directory

	# Generar changelog de la rama actual
	generate_branch_changelog "$CURRENT_BRANCH" "$BASE_BRANCH"

	echo -e "${GREEN}🎉 ¡Changelog de rama generado exitosamente!${NC}"
	echo -e "${BLUE}💡 Próximo paso: Revisa el archivo generado en releases/${NC}"
}

# Ejecutar función principal
main
