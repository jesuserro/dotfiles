#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 📦 Configuración básica
VERSION="$1"                          # Versión opcional recibida por parámetro
DEV_BRANCH="dev"                      # Rama de desarrollo
MAIN_BRANCH="main"                    # Rama principal de producción
TAG_PREFIX="v"                        # Prefijo para tags de versión
SKIP_TESTS=false                      # Flag para saltar tests

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
      --force|--skip-tests)
        SKIP_TESTS=true
        shift
        ;;
      --help|-h)
        echo -e "${BLUE}📖 Uso: git rel [versión] [opciones]${NC}"
        echo -e "${BLUE}📖 Ejemplos:${NC}"
        echo -e "  git rel                    # Release con versión automática"
        echo -e "  git rel 1.2.3              # Release con versión específica"
        echo -e "  git rel --force            # Release saltando tests"
        echo -e "  git rel 1.2.3 --skip-tests # Release con versión y saltando tests"
        echo -e "${BLUE}📖 Opciones:${NC}"
        echo -e "  --force, --skip-tests      # Continuar aunque los tests fallen"
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
  
  # Intentar el merge con mejor manejo de errores
  local merge_output
  merge_output=$(git merge "$source_branch" --no-edit 2>&1)
  local merge_exit_code=$?
  
  if [ $merge_exit_code -ne 0 ]; then
    # Verificar si es un error de fast-forward
    if echo "$merge_output" | grep -q "Not possible to fast-forward"; then
      echo -e "${YELLOW}⚠️  No es posible hacer fast-forward merge.${NC}"
      echo -e "${BLUE}💡 Intentando merge con --no-ff...${NC}"
      
      # Intentar merge con --no-ff
      if git merge "$source_branch" --no-ff --no-edit; then
        echo -e "${GREEN}✅ Merge completado con --no-ff${NC}"
      else
        echo -e "${RED}❗ Error en merge con --no-ff${NC}"
        echo -e "${YELLOW}💡 Sugerencia: Resuelve los conflictos manualmente y luego ejecuta:${NC}"
        echo -e "  git add ."
        echo -e "  git commit -m \"merge: resolve conflicts between ${source_branch} and ${target_branch}\""
        exit 1
      fi
    else
      echo -e "${RED}❗ Conflictos detectados entre '${source_branch}' y '${target_branch}'${NC}"
      echo -e "${YELLOW}💡 Sugerencia: Resuelve los conflictos y luego ejecuta:${NC}"
      echo -e "  git add ."
      echo -e "  git commit -m \"merge: resolve conflicts between ${source_branch} and ${target_branch}\""
      exit 1
    fi
  else
    echo -e "${GREEN}✅ Merge completado exitosamente${NC}"
  fi
  
  # Push de los cambios
  if ! git push origin "$target_branch"; then
    echo -e "${RED}❗ Error al hacer push a '${target_branch}'${NC}"
    echo -e "${YELLOW}💡 Sugerencia: Asegúrate de tener permisos y que la rama no esté protegida${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Merge completado: '${source_branch}' → '${target_branch}'${NC}"
}

# 🧪 Función para ejecutar tests (si existen)
run_tests() {
  # Si se especificó saltar tests, salir inmediatamente
  if [ "$SKIP_TESTS" = true ]; then
    echo -e "${YELLOW}⚠️  Saltando tests (--skip-tests especificado)${NC}"
    return 0
  fi
  
  echo -e "${BLUE}🧪 Ejecutando tests...${NC}"
  
  # Verificar si existe un script de tests personalizado
  if [ -f "scripts/test.sh" ]; then
    echo -e "${YELLOW}🔧 Detectado script de tests personalizado, ejecutando...${NC}"
    if bash scripts/test.sh; then
      echo -e "${GREEN}✅ Tests personalizados pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests personalizados fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe package.json (Node.js)
  if [ -f "package.json" ]; then
    echo -e "${YELLOW}📦 Detectado proyecto Node.js, ejecutando tests...${NC}"
    if npm test; then
      echo -e "${GREEN}✅ Tests de Node.js pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de Node.js fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe requirements.txt o pyproject.toml (Python)
  if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    echo -e "${YELLOW}🐍 Detectado proyecto Python, ejecutando tests...${NC}"
    # Intentar con python3 primero, luego con python
    if command -v python3 &> /dev/null; then
      if python3 -m pytest; then
        echo -e "${GREEN}✅ Tests de Python pasaron${NC}"
        return 0
      else
        echo -e "${RED}❌ Tests de Python fallaron${NC}"
        echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
          exit 1
        fi
        echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
        return 0
      fi
    elif command -v python &> /dev/null; then
      if python -m pytest; then
        echo -e "${GREEN}✅ Tests de Python pasaron${NC}"
        return 0
      else
        echo -e "${RED}❌ Tests de Python fallaron${NC}"
        echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
          exit 1
        fi
        echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
        return 0
      fi
    else
      echo -e "${RED}❌ No se encontró python3 ni python${NC}"
      exit 1
    fi
  fi
  
  # Verificar si existe pom.xml (Maven)
  if [ -f "pom.xml" ]; then
    echo -e "${YELLOW}☕ Detectado proyecto Maven, ejecutando tests...${NC}"
    if mvn test; then
      echo -e "${GREEN}✅ Tests de Maven pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de Maven fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe build.gradle (Gradle)
  if [ -f "build.gradle" ]; then
    echo -e "${YELLOW}☕ Detectado proyecto Gradle, ejecutando tests...${NC}"
    if ./gradlew test; then
      echo -e "${GREEN}✅ Tests de Gradle pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de Gradle fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe Cargo.toml (Rust)
  if [ -f "Cargo.toml" ]; then
    echo -e "${YELLOW}🦀 Detectado proyecto Rust, ejecutando tests...${NC}"
    if cargo test; then
      echo -e "${GREEN}✅ Tests de Rust pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de Rust fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe go.mod (Go)
  if [ -f "go.mod" ]; then
    echo -e "${YELLOW}🐹 Detectado proyecto Go, ejecutando tests...${NC}"
    if go test ./...; then
      echo -e "${GREEN}✅ Tests de Go pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de Go fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe composer.json (PHP)
  if [ -f "composer.json" ]; then
    echo -e "${YELLOW}🐘 Detectado proyecto PHP, ejecutando tests...${NC}"
    if composer test || php vendor/bin/phpunit; then
      echo -e "${GREEN}✅ Tests de PHP pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de PHP fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe Gemfile (Ruby)
  if [ -f "Gemfile" ]; then
    echo -e "${YELLOW}💎 Detectado proyecto Ruby, ejecutando tests...${NC}"
    if bundle exec rspec || bundle exec rake test; then
      echo -e "${GREEN}✅ Tests de Ruby pasaron${NC}"
      return 0
    else
      echo -e "${RED}❌ Tests de Ruby fallaron${NC}"
      echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
      read -r response
      if [[ ! "$response" =~ ^[Ss]$ ]]; then
        exit 1
      fi
      echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
      return 0
    fi
  fi
  
  # Verificar si existe Makefile con target test
  if [ -f "Makefile" ] && (grep -q "^test:" Makefile || grep -q "^tests:" Makefile); then
    echo -e "${YELLOW}🔨 Detectado Makefile con target test/tests, ejecutando...${NC}"
    # Intentar con "make tests" primero, luego con "make test"
    if grep -q "^tests:" Makefile; then
      if make tests; then
        echo -e "${GREEN}✅ Tests de Makefile (make tests) pasaron${NC}"
        return 0
      else
        echo -e "${RED}❌ Tests de Makefile (make tests) fallaron${NC}"
        echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
          exit 1
        fi
        echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
        return 0
      fi
    elif grep -q "^test:" Makefile; then
      if make test; then
        echo -e "${GREEN}✅ Tests de Makefile (make test) pasaron${NC}"
        return 0
      else
        echo -e "${RED}❌ Tests de Makefile (make test) fallaron${NC}"
        echo -e "${YELLOW}⚠️  ¿Deseas continuar con la release aunque los tests fallen? (s/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
          exit 1
        fi
        echo -e "${YELLOW}⚠️  Continuando con la release (tests fallaron)${NC}"
        return 0
      fi
    fi
  fi
  
  # Si no se detectó ningún framework de tests
  echo -e "${YELLOW}⚠️  No se detectaron tests automáticos.${NC}"
  echo -e "${BLUE}💡 Opciones para configurar tests:${NC}"
  echo -e "  • Crear scripts/test.sh (script personalizado)"
  echo -e "  • Configurar package.json (Node.js)"
  echo -e "  • Configurar pyproject.toml (Python)"
  echo -e "  • Configurar pom.xml (Maven)"
  echo -e "  • Configurar build.gradle (Gradle)"
  echo -e "  • Configurar Cargo.toml (Rust)"
  echo -e "  • Configurar go.mod (Go)"
  echo -e "  • Configurar composer.json (PHP)"
  echo -e "  • Configurar Gemfile (Ruby)"
  echo -e "  • Añadir target 'test:' en Makefile"
  echo -e "${YELLOW}¿Deseas continuar sin ejecutar tests? (s/N)${NC}"
  read -r response
  if [[ ! "$response" =~ ^[Ss]$ ]]; then
    exit 1
  fi
}

# 🏷️ Función para generar versión automática
generate_version() {
  if [ -z "$VERSION" ]; then
    # Generar versión automática con formato vAAAA.MM.DD_HHMM
    VERSION=$(date +"%Y.%m.%d_%H%M")
  fi
  echo "${TAG_PREFIX}${VERSION}"
}

# 📢 Inicio del flujo
echo -e "${YELLOW}🚀 Iniciando release de dev a main...${NC}"

# Verificar que las ramas existan
if ! branch_exists "$DEV_BRANCH"; then
  echo -e "${RED}❗ La rama '${DEV_BRANCH}' no existe.${NC}"
  exit 1
fi

if ! branch_exists "$MAIN_BRANCH"; then
  echo -e "${RED}❗ La rama '${MAIN_BRANCH}' no existe.${NC}"
  exit 1
fi

# Verificar estado del repositorio
check_clean_repo

# 🧪 Paso 1: Ejecutar tests
run_tests

# 🔁 Paso 2: Merge de dev → main
echo -e "${YELLOW}🔁 Integrando '${DEV_BRANCH}' en '${MAIN_BRANCH}'...${NC}"
git checkout "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"
do_merge "$DEV_BRANCH" "$MAIN_BRANCH"

# 🏷️ Paso 3: Crear tag de versión
TAG_NAME=$(generate_version)
echo -e "${YELLOW}🏷️  Creando tag '${TAG_NAME}'...${NC}"
git tag "$TAG_NAME"
git push origin "$TAG_NAME"
echo -e "${GREEN}✅ Tag '${TAG_NAME}' creado y subido.${NC}"

# 📝 Paso 4: Generar changelogs
echo -e "${YELLOW}📝 Generando changelogs...${NC}"
if bash ~/dotfiles/scripts/git_changelog.sh "$TAG_NAME"; then
  echo -e "${GREEN}✅ Changelogs generados exitosamente${NC}"
else
  echo -e "${YELLOW}⚠️  Error generando changelogs, pero el release se completó${NC}"
fi

# 🎉 Fin del proceso
echo -e "${GREEN}🎉 ¡Release completado exitosamente!${NC}"
echo -e "${BLUE}📋 Resumen:${NC}"
echo -e "  • ${DEV_BRANCH} → ${MAIN_BRANCH} ✅"
echo -e "  • Tag creado: ${TAG_NAME} ✅"
if [ "$SKIP_TESTS" = true ]; then
  echo -e "  • Tests saltados (--skip-tests) ⚠️"
else
  echo -e "  • Tests ejecutados ✅"
fi
echo -e "  • Changelogs generados ✅"
echo -e "${BLUE}💡 Próximo paso: Deploy a producción${NC}" 