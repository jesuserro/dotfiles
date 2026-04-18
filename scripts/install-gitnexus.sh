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
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ Error: npm no está instalado o no está en el PATH${NC}"
    echo "Por favor, instala Node.js y npm primero:"
    echo "  - Ubuntu/Debian: sudo apt-get install nodejs npm"
    echo "  - macOS: brew install node"
    echo "  - Windows: Instala Node.js desde https://nodejs.org"
    exit 1
fi

echo -e "${GREEN}✓${NC} npm encontrado: $(npm --version)"

# Prefijo npm global canónico en espacio de usuario
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# Instalar gitnexus globalmente en el prefijo npm de usuario
echo ""
echo -e "${YELLOW}⏳${NC} Instalando gitnexus@latest globalmente..."

mkdir -p "$NPM_CONFIG_PREFIX/bin" "$NPM_CONFIG_PREFIX/lib/node_modules"

if npm install -g --prefix="$NPM_CONFIG_PREFIX" gitnexus@latest 2>&1; then
    echo -e "${GREEN}✓${NC} GitNexus CLI instalado correctamente"
    if command -v gitnexus &> /dev/null; then
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
