#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
# NOTA: Esta configuración es estándar para TODOS los proyectos.
# Siempre usamos 'main' como rama principal de producción.
VERSION="$1"                          # Versión opcional recibida por parámetro
DEV_BRANCH="dev"                      # Rama de desarrollo
MAIN_BRANCH="main"                    # Rama principal de producción (estándar en todos los proyectos)
TAG_PREFIX="v"                        # Prefijo para tags de versión

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
      --help|-h)
        echo -e "${BLUE}📖 Uso: git rel [versión]${NC}"
        echo -e "${BLUE}📖 Ejemplos:${NC}"
        echo -e "  git rel                    # Release con versión automática"
        echo -e "  git rel 1.2.3              # Release con versión específica"
        echo -e "${BLUE}📖 Opciones:${NC}"
        echo -e "  --help, -h                 # Mostrar esta ayuda"
        exit 0
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

# Procesar argumentos
process_arguments "$@"

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
  exit 1
fi

# ✅ Validación: debe tener un remoto configurado
if ! git remote get-url origin >/dev/null 2>&1; then
  echo -e "${RED}❌ No hay un remoto 'origin' configurado.${NC}"
  echo -e "${YELLOW}💡 Sugerencia: Configura el remoto con: git remote add origin <url>${NC}"
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
  
  # Verificar si las ramas están al día
  git fetch origin "$source_branch" "$target_branch" >/dev/null 2>&1
  
  # Obtener la lista de archivos modificados en la rama source desde el último merge
  local modified_files=$(git diff --name-only $target_branch...$source_branch 2>/dev/null || echo "")
  
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
    if git diff --name-only $source_branch...$target_branch 2>/dev/null | grep -q "^$file$"; then
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

# 🔄 Función para hacer merge con manejo de errores (simplificada como git_feat.sh)
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
  
  # Intentar el merge (igual que git_feat.sh)
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


# 🏷️ Función para generar versión automática
generate_version() {
  if [ -z "$VERSION" ]; then
    # Generar versión automática con formato profesional: vAAAA.MM.DD_HHMM
    # Ejemplo: v2025.12.07_1023
    VERSION=$(date +"%Y.%m.%d_%H%M")
  else
    # Si se proporciona una versión manual, asegurar que tenga el formato correcto
    # Remover el prefijo 'v' si existe para normalizar
    VERSION=$(echo "$VERSION" | sed 's/^v//')
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
echo -e "${YELLOW}🚀 Iniciando release de dev a main...${NC}"

# Verificar que las ramas existan localmente
if ! branch_exists "$DEV_BRANCH"; then
  echo -e "${RED}❗ La rama '${DEV_BRANCH}' no existe localmente.${NC}"
  echo -e "${BLUE}💡 Intentando obtener desde remoto...${NC}"
  if git fetch origin "$DEV_BRANCH" && git checkout -b "$DEV_BRANCH" "origin/$DEV_BRANCH"; then
    echo -e "${GREEN}✅ Rama '${DEV_BRANCH}' creada desde remoto${NC}"
  else
    echo -e "${RED}❌ No se pudo obtener la rama '${DEV_BRANCH}' desde remoto${NC}"
    exit 1
  fi
fi

if ! branch_exists "$MAIN_BRANCH"; then
  echo -e "${RED}❗ La rama '${MAIN_BRANCH}' no existe localmente.${NC}"
  echo -e "${BLUE}💡 Intentando obtener desde remoto...${NC}"
  if git fetch origin "$MAIN_BRANCH" && git checkout -b "$MAIN_BRANCH" "origin/$MAIN_BRANCH"; then
    echo -e "${GREEN}✅ Rama '${MAIN_BRANCH}' creada desde remoto${NC}"
  else
    echo -e "${RED}❌ No se pudo obtener la rama '${MAIN_BRANCH}' desde remoto${NC}"
    exit 1
  fi
fi

# Verificar que las ramas remotas existan
echo -e "${BLUE}🔍 Verificando ramas remotas...${NC}"
if ! git ls-remote --heads origin "$DEV_BRANCH" | grep -q "$DEV_BRANCH"; then
  echo -e "${RED}❗ La rama remota '${DEV_BRANCH}' no existe.${NC}"
  exit 1
fi

if ! git ls-remote --heads origin "$MAIN_BRANCH" | grep -q "$MAIN_BRANCH"; then
  echo -e "${RED}❗ La rama remota '${MAIN_BRANCH}' no existe.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Todas las ramas verificadas correctamente${NC}"

# Verificar estado del repositorio
check_clean_repo

# 🔁 Paso 1: Merge de dev → main (igual que git_feat.sh)
echo -e "${YELLOW}🔁 Integrando '${DEV_BRANCH}' en '${MAIN_BRANCH}'...${NC}"

# Asegurar que dev esté actualizada antes del merge
git fetch origin "$DEV_BRANCH" >/dev/null 2>&1 || true

# Cambiar a main y actualizar
git checkout "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"

# Guardar el commit actual de main antes del merge (para poder obtener commits exclusivos después)
BASE_COMMIT=$(git rev-parse HEAD)

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
      git push origin ":refs/tags/$TAG_NAME" 2>/dev/null || true
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

# 📝 Función para generar changelog antes de crear el tag
generate_changelog_for_tag() {
  local tag_name="$1"
  local base_commit="$2"  # Commit base de main antes del merge
  local dev_branch="$3"    # Rama dev para calcular commits exclusivos
  local project_root=$(git rev-parse --show-toplevel)
  local releases_dir="$project_root/releases"
  
  # Crear directorio de releases si no existe
  if [ ! -d "$releases_dir" ]; then
    mkdir -p "$releases_dir"
  fi
  
  # Obtener el tag anterior (el último tag de release antes del HEAD actual)
  # Buscar solo tags que empiecen con el prefijo (normalmente "v") y tengan formato de release
  local last_tag=""
  # Obtener todos los tags que empiecen con el prefijo, ordenados por fecha (más recientes primero)
  local all_tags=$(git tag --sort=-creatordate | grep "^${TAG_PREFIX}" 2>/dev/null || echo "")
  if [ -n "$all_tags" ]; then
    # Si hay tags, obtener el primero que no sea el que estamos creando
    for tag in $all_tags; do
      if [ "$tag" != "$tag_name" ]; then
        last_tag="$tag"
        break
      fi
    done
  fi
  
  # Si aún no tenemos un tag anterior, intentar con git describe pero solo tags con prefijo
  if [ -z "$last_tag" ]; then
    last_tag=$(git describe --tags --abbrev=0 --match "${TAG_PREFIX}*" "$base_commit" 2>/dev/null || echo "")
  fi
  
  # Generar contenido del changelog desde commits exclusivos de dev
  # Usar el commit base guardado antes del merge para calcular solo los commits de dev
  local changelog_content=""
  if [ -n "$base_commit" ] && [ -n "$dev_branch" ]; then
    # Asegurar que tenemos la referencia remota de dev actualizada
    git fetch origin "$dev_branch" >/dev/null 2>&1 || true
    
    # Calcular commits exclusivos de dev desde el commit base (similar a git_feat.sh)
    # Esto asegura que solo incluimos los commits que vienen de dev en este release
    # Usar origin/dev_branch para asegurar que tenemos la versión más reciente
    local dev_ref="origin/${dev_branch}"
    if ! git rev-parse --verify "$dev_ref" >/dev/null 2>&1; then
      # Si no existe origin/dev_branch, usar la rama local
      dev_ref="$dev_branch"
    fi
    
    changelog_content=$(git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" "${base_commit}..${dev_ref}" 2>/dev/null || echo "")
    
    # Si no hay commits en ese rango, intentar con el último tag como fallback
    if [ -z "$changelog_content" ] && [ -n "$last_tag" ]; then
      echo -e "${YELLOW}⚠️  No se encontraron commits exclusivos de dev, usando último tag como referencia${NC}"
      changelog_content=$(git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" "${last_tag}..${dev_ref}" 2>/dev/null || echo "")
    fi
  elif [ -n "$last_tag" ]; then
    # Fallback: usar último tag si no tenemos commit base
    changelog_content=$(git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" "${last_tag}..HEAD" 2>/dev/null || echo "")
  else
    # Último fallback: todos los commits
    changelog_content=$(git log --pretty=format:"- %ad \`%h\` %s (%an)" --date=format:"%Y-%m-%d %H:%M" --reverse 2>/dev/null || echo "")
  fi
  
  # Categorizar commits (mejorado para detectar tipos después del backtick)
  local categorized_content=""
  # El formato es: "- YYYY-MM-DD HH:MM `hash` tipo(scope): mensaje"
  # Necesitamos extraer el tipo después del backtick de cierre
  local feat_items=$(echo "$changelog_content" | grep -E "`[^`]*` (feat|feature)" || true)
  local fix_items=$(echo "$changelog_content" | grep -E "`[^`]*` fix" || true)
  local docs_items=$(echo "$changelog_content" | grep -E "`[^`]*` docs" || true)
  local refactor_items=$(echo "$changelog_content" | grep -E "`[^`]*` refactor" || true)
  local test_items=$(echo "$changelog_content" | grep -E "`[^`]*` test" || true)
  local style_items=$(echo "$changelog_content" | grep -E "`[^`]*` style" || true)
  local chore_items=$(echo "$changelog_content" | grep -E "`[^`]*` chore" || true)
  local other_items=$(echo "$changelog_content" | grep -vE "`[^`]*` (feat|feature|fix|docs|refactor|test|style|chore)" || true)
  
  if [ -n "$feat_items" ]; then
    categorized_content+="### ✨ Added\n${feat_items}\n\n"
  fi
  if [ -n "$fix_items" ]; then
    categorized_content+="### 🐛 Fixed\n${fix_items}\n\n"
  fi
  if [ -n "$docs_items" ]; then
    categorized_content+="### 📚 Documentation\n${docs_items}\n\n"
  fi
  if [ -n "$refactor_items" ]; then
    categorized_content+="### ♻️ Refactored\n${refactor_items}\n\n"
  fi
  if [ -n "$test_items" ]; then
    categorized_content+="### ✅ Tests\n${test_items}\n\n"
  fi
  if [ -n "$style_items" ]; then
    categorized_content+="### 💅 Style\n${style_items}\n\n"
  fi
  if [ -n "$chore_items" ]; then
    categorized_content+="### 🔧 Chores\n${chore_items}\n\n"
  fi
  if [ -n "$other_items" ]; then
    categorized_content+="### 📝 Other\n${other_items}\n\n"
  fi
  
  # Si no hay contenido categorizado, usar el contenido completo
  if [ -z "$categorized_content" ]; then
    categorized_content="$changelog_content"
  fi
  
  # Obtener fecha del commit actual
  local tag_date=$(date +%Y-%m-%d)
  local tag_time=$(date +%H:%M)
  
  # Calcular estadísticas
  local total_commits=$(echo "$changelog_content" | grep -c "^-" || echo "0")
  
  # Crear mensaje para el tag anotado (formato similar a data-peek)
  local tag_message="## ${tag_name}

**Release Date:** ${tag_date} ${tag_time}
${last_tag:+**Previous Release:** ${last_tag}}

### What's Changed

${categorized_content}"

  # Si no hay contenido categorizado, usar el contenido completo
  if [ -z "$categorized_content" ]; then
    tag_message="## ${tag_name}

**Release Date:** ${tag_date} ${tag_time}
${last_tag:+**Previous Release:** ${last_tag}}

### What's Changed

${changelog_content}"
  fi

  echo "$tag_message"
}

# 📝 Paso 3: Generar changelog antes de crear el tag
TAG_MESSAGE=""
if [ -n "$TAG_NAME" ]; then
  echo -e "${YELLOW}📝 Generando changelog para el tag...${NC}"
  # Pasar el commit base y la rama dev para calcular commits exclusivos
  TAG_MESSAGE=$(generate_changelog_for_tag "$TAG_NAME" "$BASE_COMMIT" "$DEV_BRANCH")
  if [ -n "$TAG_MESSAGE" ]; then
    echo -e "${GREEN}✅ Changelog generado exitosamente${NC}"
  else
    echo -e "${YELLOW}⚠️  No se pudo generar changelog, usando mensaje básico${NC}"
    TAG_MESSAGE="Release ${TAG_NAME}"
  fi
fi

# 🏷️ Paso 4: Crear tag anotado con changelog
if [ -n "$TAG_NAME" ]; then
  echo -e "${BLUE}🏷️  Creando tag anotado '${TAG_NAME}' en el commit actual...${NC}"
  
  # Mostrar información del commit donde se creará el tag
  current_commit=$(git rev-parse HEAD)
  commit_info=$(git log -1 --pretty=format:"%h - %s (%an)" "$current_commit")
  echo -e "${BLUE}📝 Tag se creará en: ${commit_info}${NC}"
  
  # Crear tag anotado con el mensaje del changelog
  if echo "$TAG_MESSAGE" | git tag -a "$TAG_NAME" -F -; then
    echo -e "${BLUE}📤 Subiendo tag a GitHub...${NC}"
    if git push origin "$TAG_NAME"; then
      echo -e "${GREEN}✅ Tag anotado '${TAG_NAME}' creado y subido exitosamente a GitHub.${NC}"
      
      # Verificar que el tag se subió correctamente
      echo -e "${BLUE}🔍 Verificando tag en GitHub...${NC}"
      if git ls-remote --tags origin | grep -q "$TAG_NAME"; then
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

# 📝 Paso 5: Generar archivos de changelog (solo si se creó un tag)
if [ -n "$TAG_NAME" ]; then
  echo -e "${YELLOW}📝 Generando archivos de changelog...${NC}"
  if bash ~/dotfiles/scripts/git_changelog.sh "$TAG_NAME"; then
    echo -e "${GREEN}✅ Archivos de changelog generados exitosamente${NC}"
  else
    echo -e "${YELLOW}⚠️  Error generando archivos de changelog, pero el release se completó${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Saltando generación de archivos de changelog (no hay tag)${NC}"
fi

# 🚀 Paso 6: Crear release en GitHub (solo si se creó un tag)
if [ -n "$TAG_NAME" ]; then
  echo -e "${YELLOW}🚀 Creando release en GitHub...${NC}"
  
  # Verificar si gh CLI está disponible
  if command -v gh &> /dev/null; then
    # Obtener el archivo de changelog generado
    project_root=$(git rev-parse --show-toplevel)
    release_file="$project_root/releases/${TAG_NAME}.md"
    
    if [ -f "$release_file" ]; then
      # Crear release usando gh CLI con el contenido del changelog
      if gh release create "$TAG_NAME" --title "$TAG_NAME" --notes-file "$release_file" 2>/dev/null; then
        echo -e "${GREEN}✅ Release '${TAG_NAME}' creado exitosamente en GitHub${NC}"
      else
        # Si el release ya existe, intentar editarlo
        if gh release edit "$TAG_NAME" --notes-file "$release_file" 2>/dev/null; then
          echo -e "${GREEN}✅ Release '${TAG_NAME}' actualizado exitosamente en GitHub${NC}"
        else
          echo -e "${YELLOW}⚠️  No se pudo crear/actualizar el release en GitHub (puede que ya exista)${NC}"
          echo -e "${BLUE}💡 Puedes crearlo manualmente en: https://github.com/$(git remote get-url origin | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/')/releases/new${NC}"
        fi
      fi
    else
      # Si no hay archivo de changelog, crear release con el mensaje del tag
      if gh release create "$TAG_NAME" --title "$TAG_NAME" --notes "$TAG_MESSAGE" 2>/dev/null; then
        echo -e "${GREEN}✅ Release '${TAG_NAME}' creado exitosamente en GitHub${NC}"
      else
        if gh release edit "$TAG_NAME" --notes "$TAG_MESSAGE" 2>/dev/null; then
          echo -e "${GREEN}✅ Release '${TAG_NAME}' actualizado exitosamente en GitHub${NC}"
        else
          echo -e "${YELLOW}⚠️  No se pudo crear/actualizar el release en GitHub${NC}"
          echo -e "${BLUE}💡 Puedes crearlo manualmente en: https://github.com/$(git remote get-url origin | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/')/releases/new${NC}"
        fi
      fi
    fi
  else
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) no está instalado${NC}"
    echo -e "${BLUE}💡 Instala gh CLI para crear releases automáticamente: https://cli.github.com/${NC}"
    echo -e "${BLUE}💡 O crea el release manualmente en: https://github.com/$(git remote get-url origin | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/')/releases/new${NC}"
    echo -e "${BLUE}💡 Usa el siguiente contenido para el release:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "$TAG_MESSAGE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Saltando creación de release (no hay tag)${NC}"
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
  repo_url=$(git remote get-url origin | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')
  echo -e "  • Tag anotado creado: ${TAG_NAME} ✅"
  echo -e "  • Tag en GitHub: https://github.com/${repo_url}/releases/tag/${TAG_NAME}"
  echo -e "  • Release en GitHub: https://github.com/${repo_url}/releases/tag/${TAG_NAME}"
else
  echo -e "  • Tag: No creado ⚠️"
fi
if [ -n "$TAG_NAME" ]; then
  echo -e "  • Changelog en tag: ✅"
  echo -e "  • Archivos de changelog generados: ✅"
  if command -v gh &> /dev/null; then
    echo -e "  • Release de GitHub: ✅"
  else
    echo -e "  • Release de GitHub: ⚠️  (requiere gh CLI)"
  fi
else
  echo -e "  • Changelogs: No generados ⚠️"
fi
echo -e "${BLUE}💡 Próximo paso: Deploy a producción${NC}" 