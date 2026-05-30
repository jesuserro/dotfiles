#!/bin/bash

# Activa el modo estricto: cualquier error hace que el script se detenga
set -e

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# 📦 Configuración
DEV_BRANCH="dev"
CODEX_PREFIX="codex/"
ARCHIVE_PREFIX="archive/"
BRANCHES_TO_KEEP=("main" "master" "dev")

# ✅ Validación: debe ejecutarse dentro de un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo -e "${RED}❌ No estás dentro de un repositorio Git.${NC}"
	exit 1
fi

# 🧠 Verifica si una rama existe
branch_exists() {
	git rev-parse --verify "$1" >/dev/null 2>&1
}

# 🔄 Función para cambiar a una rama de forma segura
safe_checkout() {
	local target_branch="$1"

	if ! branch_exists "$target_branch"; then
		echo -e "${RED}❌ La rama '${target_branch}' no existe.${NC}"
		exit 1
	fi

	echo -e "${YELLOW}🔄 Cambiando a la rama '${target_branch}'...${NC}"
	git checkout "$target_branch"
	echo -e "${GREEN}✅ Cambiado a '${target_branch}'${NC}"
}

# 🧹 Función para limpiar ramas locales
clean_local_branches() {
	local prefix="$1"
	local branch_type="$2"
	local count=0

	echo -e "${BLUE}🧹 Limpiando ramas locales '${prefix}*' mergeadas en dev...${NC}"

	# Obtener ramas locales que empiecen con el prefijo y estén mergeadas en dev
	local merged_branches=$(git branch --merged dev --format='%(refname:short)' | grep "^${prefix}" || true)

	if [ -z "$merged_branches" ]; then
		echo -e "${YELLOW}⚠️  No hay ramas locales '${prefix}*' mergeadas en dev${NC}"
		CLEAN_COUNT=0
		return 0
	fi

	for branch in $merged_branches; do
		# Verificar que no sea una rama que debemos mantener
		local should_keep=false
		for keep_branch in "${BRANCHES_TO_KEEP[@]}"; do
			if [[ "$branch" == "$keep_branch" ]]; then
				should_keep=true
				break
			fi
		done

		if [ "$should_keep" = false ]; then
			echo -e "${YELLOW}🗑️  Borrando rama local: ${branch}${NC}"
			if git branch -d "$branch" 2>/dev/null; then
				echo -e "${GREEN}✅ Rama local '${branch}' borrada${NC}"
				((count++))
			else
				echo -e "${RED}❌ No se pudo borrar la rama local '${branch}' (puede tener cambios no mergeados)${NC}"
			fi
		fi
	done

	echo -e "${GREEN}📊 Ramas locales '${prefix}*' borradas: ${count}${NC}"
	CLEAN_COUNT=$count
	return 0
}

# 🧹 Función para limpiar ramas remotas
clean_remote_branches() {
	local prefix="$1"
	local branch_type="$2"
	local count=0

	echo -e "${BLUE}🧹 Limpiando ramas remotas '${prefix}*' mergeadas en dev...${NC}"

	# Obtener ramas remotas que empiecen con el prefijo y estén mergeadas en dev
	local merged_remote_branches=$(git branch -r --merged dev --format='%(refname:short)' | sed 's/origin\///' | grep "^${prefix}" || true)

	if [ -z "$merged_remote_branches" ]; then
		echo -e "${YELLOW}⚠️  No hay ramas remotas '${prefix}*' mergeadas en dev${NC}"
		CLEAN_COUNT=0
		return 0
	fi

	for branch in $merged_remote_branches; do
		echo -e "${YELLOW}🗑️  Borrando rama remota: ${branch}${NC}"
		if git push origin --delete "$branch" 2>/dev/null; then
			echo -e "${GREEN}✅ Rama remota '${branch}' borrada${NC}"
			((count++))
		else
			echo -e "${RED}❌ No se pudo borrar la rama remota '${branch}' (puede no existir o no tener permisos)${NC}"
		fi
	done

	echo -e "${GREEN}📊 Ramas remotas '${prefix}*' borradas: ${count}${NC}"
	CLEAN_COUNT=$count
	return 0
}

# 📢 Inicio del flujo
echo -e "${CYAN}🧹 Iniciando limpieza de ramas codex/ y archive/...${NC}"
echo ""

# 🔄 Paso 1: Cambiar a la rama dev
safe_checkout "$DEV_BRANCH"

# 🔄 Paso 2: Hacer fetch --prune
echo -e "${YELLOW}🔄 Ejecutando git fetch --prune...${NC}"
if git fetch --prune; then
	echo -e "${GREEN}✅ Fetch --prune completado${NC}"
else
	echo -e "${RED}❌ Error al ejecutar fetch --prune${NC}"
	exit 1
fi

echo ""

# 📊 Contadores totales
total_local_codex=0
total_local_archive=0
total_remote_codex=0
total_remote_archive=0

# 🧹 Paso 3: Limpiar ramas codex/ locales
clean_local_branches "$CODEX_PREFIX" "codex"
total_local_codex=$CLEAN_COUNT

echo ""

# 🧹 Paso 4: Limpiar ramas archive/ locales
clean_local_branches "$ARCHIVE_PREFIX" "archive"
total_local_archive=$CLEAN_COUNT

echo ""

# 🧹 Paso 5: Limpiar ramas codex/ remotas
clean_remote_branches "$CODEX_PREFIX" "codex"
total_remote_codex=$CLEAN_COUNT

echo ""

# 🧹 Paso 6: Limpiar ramas archive/ remotas
clean_remote_branches "$ARCHIVE_PREFIX" "archive"
total_remote_archive=$CLEAN_COUNT

echo ""

# 📊 Resumen final
echo -e "${CYAN}📋 Resumen de limpieza:${NC}"
echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│ Tipo de Rama    │ Locales │ Remotas │ Total │${NC}"
echo -e "${BLUE}├─────────────────┼─────────┼─────────┼───────┤${NC}"
printf "${BLUE}│ codex/          │ %7d │ %7d │ %5d │${NC}\n" $total_local_codex $total_remote_codex $((total_local_codex + total_remote_codex))
printf "${BLUE}│ archive/        │ %7d │ %7d │ %5d │${NC}\n" $total_local_archive $total_remote_archive $((total_local_archive + total_remote_archive))
echo -e "${BLUE}├─────────────────┼─────────┼─────────┼───────┤${NC}"
local_total=$((total_local_codex + total_local_archive))
remote_total=$((total_remote_codex + total_remote_archive))
grand_total=$((local_total + remote_total))
printf "${BLUE}│ TOTAL           │ %7d │ %7d │ %5d │${NC}\n" $local_total $remote_total $grand_total
echo -e "${BLUE}└─────────────────┴─────────┴─────────┴───────┘${NC}"

echo ""
echo -e "${GREEN}🎉 ¡Limpieza de ramas completada exitosamente!${NC}"
echo -e "${BLUE}💡 Rama actual: ${DEV_BRANCH}${NC}"
