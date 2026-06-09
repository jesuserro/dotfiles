#!/bin/bash
# =============================================================================
# Script de instalación global de GitNexus
# =============================================================================
# Instala gitnexus CLI globalmente usando npm.
# Idempotente: puede ejecutarse múltiples veces sin efectos adversos.
# =============================================================================

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║${NC}  ${GREEN}Instalación de GitNexus CLI${NC}                                ${YELLOW}║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que npm está disponible
if ! command -v npm &>/dev/null; then
	echo -e "${RED}❌ Error: npm no está instalado o no está en el PATH${NC}"
	echo "Por favor, instala primero el stack Node.js moderno requerido por GitNexus:"
	echo "  - Dotfiles/Ubuntu WSL: make install-node-stack"
	echo "  - macOS: brew install node"
	echo "  - Windows: Instala Node.js desde https://nodejs.org"
	exit 1
fi

echo -e "${GREEN}✓${NC} npm encontrado: $(npm --version)"

node_version="$(node --version 2>/dev/null || true)"
node_major="${node_version#v}"
node_major="${node_major%%.*}"
if [[ -z "${node_major}" || "${node_major}" -lt 22 ]]; then
	echo -e "${RED}❌ Error: GitNexus requiere Node >=22; detectado ${node_version:-desconocido}${NC}"
	echo "Ejecuta: make install-node-stack"
	exit 1
fi

# Prefijo npm global canónico en espacio de usuario
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-${DOTFILES_NPM_PREFIX:-$HOME/.npm-global}}"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

npm_ignore_scripts_enabled() {
	local configured="${NPM_CONFIG_IGNORE_SCRIPTS:-${npm_config_ignore_scripts:-}}" value
	case "$configured" in
	1 | true | TRUE | yes | YES | on | ON) return 0 ;;
	esac

	value="$(npm config get ignore-scripts 2>/dev/null | head -n 1 | tr -d '\r' || true)"
	case "$value" in
	1 | true | TRUE | yes | YES | on | ON) return 0 ;;
	esac
	return 1
}

run_gitnexus_postinstall_scripts() {
	local gitnexus_dir="$1"
	local postinstall script

	if [[ ! -d "$gitnexus_dir/scripts" ]]; then
		echo -e "${YELLOW}⚠️${NC} No se encontraron scripts postinstall de GitNexus en ${gitnexus_dir}"
		return 1
	fi

	postinstall="$(node -e 'const fs = require("fs"); const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); process.stdout.write(pkg.scripts && pkg.scripts.postinstall ? pkg.scripts.postinstall : "");' "${gitnexus_dir}/package.json" 2>/dev/null || true)"
	if [[ -z "$postinstall" ]]; then
		echo -e "${YELLOW}⚠️${NC} GitNexus no declara script postinstall en package.json"
		return 1
	fi

	for script in ${postinstall//&&/ }; do
		[[ "$script" == scripts/*.cjs ]] || continue
		if [[ -f "${gitnexus_dir}/${script}" ]]; then
			(
				cd "$gitnexus_dir" || exit 1
				node "$script"
			)
		fi
	done
}

# Instalar gitnexus globalmente en el prefijo npm de usuario
echo ""
gitnexus_spec="gitnexus@${GITNEXUS_VERSION:-latest}"
echo -e "${YELLOW}⏳${NC} Instalando ${gitnexus_spec} globalmente..."

mkdir -p "$NPM_CONFIG_PREFIX/bin" "$NPM_CONFIG_PREFIX/lib/node_modules"

if npm_ignore_scripts_enabled; then
	echo -e "${RED}❌ Error: npm ignore-scripts está activo; GitNexus necesita ejecutar postinstall para preparar gramáticas tree-sitter${NC}"
	echo "Desactiva ignore-scripts para instalar GitNexus correctamente."
	exit 1
fi

if npm install -g --prefix="$NPM_CONFIG_PREFIX" "$gitnexus_spec" 2>&1; then
	gitnexus_dir="$(npm root -g --prefix="$NPM_CONFIG_PREFIX")/gitnexus"
	run_gitnexus_postinstall_scripts "$gitnexus_dir" || {
		echo -e "${RED}❌ Error preparando gramáticas nativas de GitNexus${NC}"
		exit 1
	}
	echo -e "${GREEN}✓${NC} GitNexus CLI instalado correctamente"
	# shellcheck source=scripts/lib/gitnexus_canonical.sh
	source "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/lib/gitnexus_canonical.sh"
	if gitnexus_ensure_canonical_symlink; then
		echo -e "${GREEN}✓${NC} Symlink canónico agent-first creado"
	else
		echo -e "${RED}❌ Error creando symlink canónico en ~/.local/bin/gitnexus${NC}"
		exit 1
	fi
	if command -v gitnexus &>/dev/null; then
		echo -e "${GREEN}✓${NC} gitnexus disponible en PATH: $(which gitnexus)"
		echo -e "${GREEN}✓${NC} Versión: $(gitnexus --version 2>/dev/null || echo 'versión no disponible')"
	else
		echo -e "${YELLOW}⚠️${NC} gitnexus instalado pero no encontrado en PATH"
		echo "  Ejecuta: hash -r  # para actualizar el cache de comandos"
	fi
else
	echo -e "${RED}❌ Error al instalar gitnexus${NC}"
	exit 1
fi

echo -e "${GREEN}✓${NC} Prefijo npm global canónico: ${NPM_CONFIG_PREFIX}"

echo ""
echo -e "${GREEN}✅ Instalación completada${NC}"
echo ""
echo "Uso:"
echo "  gitnexus --help           Ver ayuda"
echo "  gitnexus analyze          Analizar repositorio actual"
echo "  gitnexus serve            Iniciar servidor local"
echo "  gitnexus mcp              Ejecutar como servidor MCP"
echo ""
echo "Aliases disponibles después de source ~/.zshrc:"
echo "  gnx-serve      - Iniciar servidor GitNexus"
echo "  gnx-analyze-here - Analizar repo actual"
echo "  gnx-wiki-here  - Generar wiki en docs/wiki/"
echo "  gnx-map        - Analizar y servir"
