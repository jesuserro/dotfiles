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
DEV_BRANCH="dev"
MAIN_BRANCH="main"

# 🔍 Procesar argumentos
process_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--help | -h)
			echo -e "${BLUE}📖 Uso: git rel-resolve [opciones]${NC}"
			echo -e "${BLUE}📖 Descripción: Ayuda a resolver conflictos de merge cuando git rel falla${NC}"
			echo -e "${BLUE}📖 Opciones:${NC}"
			echo -e "  --help, -h                 # Mostrar esta ayuda"
			echo -e "  --abort                    # Abortar el merge actual"
			echo -e "  --continue                 # Continuar el merge después de resolver conflictos"
			exit 0
			;;
		--abort)
			echo -e "${YELLOW}🔄 Abortando merge actual...${NC}"
			git merge --abort
			echo -e "${GREEN}✅ Merge abortado${NC}"
			exit 0
			;;
		--continue)
			echo -e "${YELLOW}🔄 Continuando merge...${NC}"
			if git commit --no-edit; then
				echo -e "${GREEN}✅ Merge completado${NC}"
				echo -e "${BLUE}💡 Ahora puedes continuar con: git rel${NC}"
			else
				echo -e "${RED}❌ Error al completar el merge${NC}"
				exit 1
			fi
			exit 0
			;;
		*)
			echo -e "${RED}❗ Argumento desconocido: $1${NC}"
			echo -e "${BLUE}💡 Usa 'git rel-resolve --help' para ver las opciones${NC}"
			exit 1
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

# 🔍 Verificar si hay un merge en progreso
if ! git rev-parse MERGE_HEAD >/dev/null 2>&1; then
	echo -e "${YELLOW}⚠️  No hay un merge en progreso.${NC}"
	echo -e "${BLUE}💡 Si git rel falló, intenta ejecutarlo nuevamente.${NC}"
	exit 0
fi

# 📋 Mostrar estado actual
echo -e "${BLUE}📋 Estado actual del merge:${NC}"
git status

# 🔍 Verificar archivos con conflictos
conflicted_files=$(git diff --name-only --diff-filter=U 2>/dev/null || echo "")

if [ -z "$conflicted_files" ]; then
	echo -e "${GREEN}✅ No se detectaron archivos con conflictos${NC}"
	echo -e "${BLUE}💡 Intentando completar el merge...${NC}"
	if git commit --no-edit; then
		echo -e "${GREEN}✅ Merge completado exitosamente${NC}"
		echo -e "${BLUE}💡 Ahora puedes continuar con: git rel${NC}"
	else
		echo -e "${RED}❌ Error al completar el merge${NC}"
		exit 1
	fi
else
	echo -e "${YELLOW}⚠️  Archivos con conflictos detectados:${NC}"
	for file in $conflicted_files; do
		echo -e "  ${YELLOW}•${NC} $file"
	done

	echo -e "${BLUE}💡 Pasos para resolver conflictos:${NC}"
	echo -e "  1. Abre cada archivo con conflictos y resuelve los marcadores <<<<<<<, =======, >>>>>>>"
	echo -e "  2. Guarda los archivos"
	echo -e "  3. Ejecuta: git add ."
	echo -e "  4. Ejecuta: git rel-resolve --continue"
	echo -e ""
	echo -e "${YELLOW}💡 O si quieres abortar el merge:${NC}"
	echo -e "  git rel-resolve --abort"
fi
