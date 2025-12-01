#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
DEV_BRANCH="dev"                      # Rama de desarrollo
FEATURE_PREFIX="feature/"            # Prefijo estándar para ramas de features
FEATURE_BRANCH=""                    # Rama feature final a usar (resuelta más abajo)
ARCHIVE_PREFIX="archive/"            # Prefijo para archivar ramas
GENERATE_CHANGELOG=true              # Generar changelog automáticamente

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
      --help|-h)
        echo -e "${BLUE}📖 Uso: git feat <nombre-feature> [opciones]${NC}"
        echo -e "${BLUE}📖 Descripción: Integra una rama feature en dev y la archiva${NC}"
        echo -e "${BLUE}📖 Ejemplos:${NC}"
        echo -e "  git feat mi-nueva-funcionalidad     # Rama 'feature/mi-nueva-funcionalidad'"
        echo -e "  git feat feature/login-system       # Rama 'feature/login-system'"
        echo -e "  git feat login-system               # Rama 'feature/login-system'"
        echo -e "${BLUE}📖 Opciones:${NC}"
        echo -e "  --no-changelog                      # No generar changelog automáticamente"
        echo -e "  --help, -h                          # Mostrar esta ayuda"
        echo -e "${BLUE}📖 Flujo:${NC}"
        echo -e "  1. Se mueve a rama 'dev'"
        echo -e "  2. Hace merge de tu feature en dev"
        echo -e "  3. Genera changelog de la feature (opcional)"
        echo -e "  4. Archiva tu rama feature"
        echo -e "  5. Termina en rama 'dev'"
        exit 0
        ;;
      --no-changelog)
        GENERATE_CHANGELOG=false
        shift
        ;;
      *)
        if [ -z "$input_name" ]; then
          input_name="$1"
        else
          echo -e "${RED}❗ Argumento desconocido: $1${NC}"
          echo -e "${BLUE}💡 Usa 'git feat --help' para ver las opciones${NC}"
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
  local modified_files=$(git diff --name-only $target_branch...$source_branch)
  
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
  if ! git push origin "$target_branch"; then
    echo -e "${RED}❗ Error al hacer push a '${target_branch}'${NC}"
    echo -e "${YELLOW}💡 Sugerencia: Asegúrate de tener permisos y que la rama no esté protegida${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Merge completado: '${source_branch}' → '${target_branch}'${NC}"
}

# 📝 Función para generar changelog de la feature antes de archivarla
generate_feature_changelog() {
  local feature_branch="$1"
  local base_branch="$2"
  
  if [ "$GENERATE_CHANGELOG" = true ]; then
    echo -e "${YELLOW}📝 Generando changelog de la feature antes de archivarla...${NC}"
    
    # Crear directorio de releases si no existe
    local releases_dir="$(git rev-parse --show-toplevel)/releases"
    if [ ! -d "$releases_dir" ]; then
      mkdir -p "$releases_dir"
    fi
    
    # Crear nombre de archivo seguro para la feature
    local safe_branch_name=$(echo "$feature_branch" | sed 's/[^a-zA-Z0-9._-]/_/g')
    local changelog_file="$releases_dir/branch_${safe_branch_name}.md"
    
    # Obtener fecha y hora actual
    local current_date=$(date +%Y-%m-%d)
    local current_time=$(date +%H:%M)
    
    # Obtener información de la feature
    local branch_info=$(git log -1 --pretty=format:"%h - %s (%an)" "$feature_branch")
    local total_commits=$(git rev-list --count "${base_branch}..${feature_branch}" 2>/dev/null || echo "0")
    
    # Generar contenido del changelog (commits exclusivos de la feature)
    local changelog_content=$(git log --pretty=format:"- %h %ad %an %s" --date=format:"%Y-%m-%d %H:%M" "${base_branch}..${feature_branch}" 2>/dev/null || echo "# No se pudieron obtener commits exclusivos")
    
    # Crear archivo de changelog
    cat > "$changelog_file" << EOF
# Feature Changelog: ${feature_branch}

**Fecha de integración:** ${current_date}  
**Rama base:** ${base_branch}  
**Último commit:** ${branch_info}

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

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Integrando feature '${INPUT_NAME}' en dev...${NC}"

# 📛 Validación de argumentos
if [ -z "$INPUT_NAME" ]; then
  echo -e "${RED}❗ ERROR: Debes pasar el nombre de la rama feature como argumento.${NC}"
  echo "👉 Ejemplo: git feat mi-nueva-funcionalidad"
  echo "👉 O usa: git feat --help"
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

# Verificar estado del repositorio
check_clean_repo

# 🔁 Merge de feature → dev
echo -e "${YELLOW}🔁 Integrando '${FEATURE_BRANCH}' en '${DEV_BRANCH}'...${NC}"
git checkout "$DEV_BRANCH"
git pull origin "$DEV_BRANCH"

# 📝 Generar changelog de la feature ANTES del merge (cuando todavía tiene commits exclusivos)
generate_feature_changelog "$FEATURE_BRANCH" "$DEV_BRANCH"

# Ahora hacer el merge
do_merge "$FEATURE_BRANCH" "$DEV_BRANCH"

# 📦 Archivar la rama feature
ARCHIVE_BRANCH="${ARCHIVE_PREFIX}${FEATURE_BRANCH}"
echo -e "${YELLOW}📦 Archivando rama '${FEATURE_BRANCH}' como '${ARCHIVE_BRANCH}'...${NC}"
git branch -m "$FEATURE_BRANCH" "$ARCHIVE_BRANCH"   # Renombrado local
git push origin "$ARCHIVE_BRANCH"                   # Subida rama archivada
git push origin --delete "$FEATURE_BRANCH" || true  # Eliminación en remoto (ignora error si no existe)
echo -e "${GREEN}✅ Rama archivada como '${ARCHIVE_BRANCH}' y eliminada la original del remoto.${NC}"

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Feature '${INPUT_NAME}' integrada exitosamente en dev!${NC}"
echo -e "${BLUE}💡 Próximo paso: Cuando dev esté listo para producción, ejecuta 'git rel'${NC}" 