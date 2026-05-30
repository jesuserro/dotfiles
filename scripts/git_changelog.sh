#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
TAG_NAME="$1" # Tag del release actual
LAST_TAG="$2" # Tag anterior (opcional)
PROJECT_ROOT=$(git rev-parse --show-toplevel)
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"
RELEASES_DIR="$PROJECT_ROOT/releases"
MAX_RECENT_RELEASES=5 # Número de releases a mantener en CHANGELOG.md

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
		--help | -h)
			echo -e "${BLUE}📖 Uso: git changelog <tag-actual> [tag-anterior]${NC}"
			echo -e "${BLUE}📖 Descripción: Genera changelogs para un release${NC}"
			echo -e "${BLUE}📖 Ejemplos:${NC}"
			echo -e "  git changelog v1.2.3                    # Genera changelog para v1.2.3"
			echo -e "  git changelog v1.2.3 v1.2.2             # Desde v1.2.2 hasta v1.2.3"
			echo -e "${BLUE}📖 Opciones:${NC}"
			echo -e "  --help, -h                              # Mostrar esta ayuda"
			exit 0
			;;
		*)
			if [ -z "$TAG_NAME" ]; then
				TAG_NAME="$1"
			elif [ -z "$LAST_TAG" ]; then
				LAST_TAG="$1"
			else
				echo -e "${RED}❗ Demasiados argumentos: $1${NC}"
				echo -e "${BLUE}💡 Usa 'git changelog --help' para ver las opciones${NC}"
				exit 1
			fi
			shift
			;;
		esac
	done
}

# Procesar argumentos
process_arguments "$@"

# Validar que se proporcionó el tag actual
if [ -z "$TAG_NAME" ]; then
	echo -e "${RED}❗ ERROR: Debes proporcionar el tag del release actual.${NC}"
	echo -e "${BLUE}💡 Usa: git changelog <tag-actual>${NC}"
	echo -e "${BLUE}💡 Ejemplo: git changelog v1.2.3${NC}"
	exit 1
fi

# 🏷️ Función para obtener el tag anterior si no se proporciona
get_previous_tag() {
	if [ -z "$LAST_TAG" ]; then
		# Extraer el prefijo del tag actual (normalmente "v")
		TAG_PREFIX=$(echo "$TAG_NAME" | sed 's/^\([^0-9]*\).*/\1/')
		if [ -z "$TAG_PREFIX" ]; then
			TAG_PREFIX="v"
		fi

		# Intentar obtener el último tag de release antes del actual
		# Buscar solo tags que empiecen con el prefijo
		LAST_TAG=$(git describe --tags --abbrev=0 --match "${TAG_PREFIX}*" "$TAG_NAME"^ 2>/dev/null)
		if [ $? -ne 0 ] || [ -z "$LAST_TAG" ]; then
			# Si no se encuentra, buscar en todos los tags con prefijo ordenados por fecha
			LAST_TAG=$(git tag --sort=-creatordate | grep "^${TAG_PREFIX}" | grep -v "^${TAG_NAME}$" | head -n 1 2>/dev/null || echo "")
		fi

		if [ -n "$LAST_TAG" ] && [ "$LAST_TAG" != "$TAG_NAME" ]; then
			echo -e "${BLUE}🔍 Tag anterior detectado automáticamente: ${LAST_TAG}${NC}"
		else
			LAST_TAG="" # Limpiar si es el mismo tag o no se encontró
			echo -e "${YELLOW}⚠️  No se encontró tag anterior de release. Mostrando todos los commits hasta este tag.${NC}"
		fi
	fi
}

# 📝 Función para generar changelog desde commits
generate_changelog_content() {
	local from_tag="$1"
	local to_tag="$2"

	if [ -n "$from_tag" ] && [ "$from_tag" != "$to_tag" ]; then
		echo -e "${BLUE}📝 Generando changelog desde ${from_tag} hasta ${to_tag}...${NC}"
		git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" "${from_tag}..${to_tag}" 2>/dev/null ||
			git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" "${from_tag}..HEAD" 2>/dev/null
	else
		echo -e "${BLUE}📝 Generando changelog completo hasta ${to_tag}...${NC}"
		git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" "${to_tag}" 2>/dev/null ||
			git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" --reverse
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

	# Procesar cada línea (el formato ahora es: "- YYYY-MM-DD HH:MM `hash` tipo(scope): mensaje")
	local tmp_content=$(mktemp)
	echo "$content" >"$tmp_content"
	while IFS= read -r line; do
		# Extraer el tipo del commit que viene después del backtick de cierre y antes de (
		# El formato es: "- YYYY-MM-DD HH:MM `hash` tipo(scope): mensaje"
		# Usar una variable para el patrón del backtick para evitar problemas de escape
		local backtick_pattern='`[^`]*`'
		if echo "$line" | grep -qE "${backtick_pattern} (feat|feature)"; then
			echo "$line" >>"$feat_file"
		elif echo "$line" | grep -qE "${backtick_pattern} fix"; then
			echo "$line" >>"$fix_file"
		elif echo "$line" | grep -qE "${backtick_pattern} docs"; then
			echo "$line" >>"$docs_file"
		elif echo "$line" | grep -qE "${backtick_pattern} style"; then
			echo "$line" >>"$style_file"
		elif echo "$line" | grep -qE "${backtick_pattern} refactor"; then
			echo "$line" >>"$refactor_file"
		elif echo "$line" | grep -qE "${backtick_pattern} test"; then
			echo "$line" >>"$test_file"
		elif echo "$line" | grep -qE "${backtick_pattern} chore"; then
			echo "$line" >>"$chore_file"
		elif echo "$line" | grep -qE "^-"; then
			echo "$line" >>"$other_file"
		fi
	done <"$tmp_content"
	rm -f "$tmp_content"

	# Generar contenido categorizado usando printf para saltos de línea correctos
	local categorized_content=""
	local nl=$'\n'

	if [ -s "$feat_file" ]; then
		categorized_content+="### Added${nl}"
		categorized_content+="$(cat "$feat_file")${nl}${nl}"
	fi

	if [ -s "$fix_file" ]; then
		categorized_content+="### Fixed${nl}"
		categorized_content+="$(cat "$fix_file")${nl}${nl}"
	fi

	if [ -s "$docs_file" ]; then
		categorized_content+="### Documentation${nl}"
		categorized_content+="$(cat "$docs_file")${nl}${nl}"
	fi

	if [ -s "$refactor_file" ]; then
		categorized_content+="### Refactored${nl}"
		categorized_content+="$(cat "$refactor_file")${nl}${nl}"
	fi

	if [ -s "$test_file" ]; then
		categorized_content+="### Tests${nl}"
		categorized_content+="$(cat "$test_file")${nl}${nl}"
	fi

	if [ -s "$style_file" ]; then
		categorized_content+="### Style${nl}"
		categorized_content+="$(cat "$style_file")${nl}${nl}"
	fi

	if [ -s "$chore_file" ]; then
		categorized_content+="### Chores${nl}"
		categorized_content+="$(cat "$chore_file")${nl}${nl}"
	fi

	if [ -s "$other_file" ]; then
		categorized_content+="### Other${nl}"
		categorized_content+="$(cat "$other_file")${nl}${nl}"
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

# 📄 Función para generar changelog individual por release
generate_individual_changelog() {
	local tag="$1"
	local from_tag="$2"
	local release_file="$RELEASES_DIR/${tag}.md"

	echo -e "${YELLOW}📄 Generando changelog individual: ${release_file}${NC}"

	# Obtener fecha del tag
	local tag_date=$(git log -1 --format="%ad" --date=short "$tag" 2>/dev/null || date +%Y-%m-%d)

	# Generar contenido del changelog
	local changelog_content=$(generate_changelog_content "$from_tag" "$tag")
	local categorized_content=$(categorize_commits "$changelog_content")

	# Crear archivo de release
	cat >"$release_file" <<EOF
# Release ${tag}

**Fecha:** ${tag_date}

## Changes

${categorized_content}

## Technical Details
- Tag: ${tag}
- Previous tag: ${from_tag:-"Initial release"}
- Total commits: $(echo "$changelog_content" | wc -l)
EOF

	echo -e "${GREEN}✅ Changelog individual generado: ${release_file}${NC}"
}

# 📋 Función para actualizar CHANGELOG.md principal
update_main_changelog() {
	echo -e "${YELLOW}📋 Actualizando CHANGELOG.md principal...${NC}"

	# Crear archivo temporal para el nuevo contenido
	local temp_file=$(mktemp)

	# Obtener lista de releases recientes (ordenados por fecha, más recientes primero)
	local recent_releases=$(find "$RELEASES_DIR" -name "*.md" -type f | sort -r | head -n "$MAX_RECENT_RELEASES")

	# Crear encabezado
	cat >"$temp_file" <<EOF
# Changelog

Este archivo contiene las últimas ${MAX_RECENT_RELEASES} releases. Para el historial completo, consulta los archivos en el directorio \`releases/\`.

EOF

	# Añadir cada release reciente
	for release_file in $recent_releases; do
		local tag=$(basename "$release_file" .md)
		local tag_date=$(git log -1 --format="%ad" --date=short "$tag" 2>/dev/null || echo "Unknown date")

		echo "## [${tag}] - ${tag_date}" >>"$temp_file"
		echo "" >>"$temp_file"

		# Extraer solo las categorías principales (sin Technical Details)
		sed -n '/^## Changes$/,/^## Technical Details$/p' "$release_file" |
			sed '/^## Technical Details$/d' |
			sed '/^$/d' >>"$temp_file"

		echo "" >>"$temp_file"
	done

	# Reemplazar el archivo principal
	mv "$temp_file" "$CHANGELOG_FILE"

	echo -e "${GREEN}✅ CHANGELOG.md principal actualizado${NC}"
}

# 🚀 Función principal
main() {
	echo -e "${YELLOW}🚀 Iniciando generación de changelogs para ${TAG_NAME}...${NC}"

	# Obtener tag anterior si no se proporcionó
	get_previous_tag

	# Crear directorio de releases
	create_releases_directory

	# Generar changelog individual
	generate_individual_changelog "$TAG_NAME" "$LAST_TAG"

	# Actualizar CHANGELOG.md principal
	update_main_changelog

	echo -e "${GREEN}🎉 ¡Changelogs generados exitosamente!${NC}"
	echo -e "${BLUE}📋 Resumen:${NC}"
	echo -e "  • Changelog individual: releases/${TAG_NAME}.md ✅"
	echo -e "  • CHANGELOG.md principal actualizado ✅"
	echo -e "  • Releases mantenidos: ${MAX_RECENT_RELEASES} ✅"
}

# Ejecutar función principal
main
