#!/bin/bash

# 🧪 Script de prueba para verificar python3 y make tests
# Este script simula las condiciones que el script de release detectaría

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

echo -e "${BLUE}🧪 Probando detección de python3 y make tests...${NC}"

# Verificar python3
echo -e "${YELLOW}🐍 Verificando python3...${NC}"
if command -v python3 &>/dev/null; then
	echo -e "${GREEN}✅ python3 encontrado: $(python3 --version)${NC}"
else
	echo -e "${RED}❌ python3 no encontrado${NC}"
fi

# Verificar python
echo -e "${YELLOW}🐍 Verificando python...${NC}"
if command -v python &>/dev/null; then
	echo -e "${GREEN}✅ python encontrado: $(python --version)${NC}"
else
	echo -e "${RED}❌ python no encontrado${NC}"
fi

# Verificar make
echo -e "${YELLOW}🔨 Verificando make...${NC}"
if command -v make &>/dev/null; then
	echo -e "${GREEN}✅ make encontrado: $(make --version | head -n1)${NC}"
else
	echo -e "${RED}❌ make no encontrado${NC}"
fi

# Verificar si existe Makefile con targets de test
echo -e "${YELLOW}📄 Verificando Makefile...${NC}"
if [ -f "Makefile" ]; then
	echo -e "${GREEN}✅ Makefile encontrado${NC}"

	if grep -q "^tests:" Makefile; then
		echo -e "${GREEN}✅ Target 'tests:' encontrado en Makefile${NC}"
	else
		echo -e "${YELLOW}⚠️  Target 'tests:' no encontrado${NC}"
	fi

	if grep -q "^test:" Makefile; then
		echo -e "${GREEN}✅ Target 'test:' encontrado en Makefile${NC}"
	else
		echo -e "${YELLOW}⚠️  Target 'test:' no encontrado${NC}"
	fi
else
	echo -e "${YELLOW}⚠️  Makefile no encontrado${NC}"
fi

# Verificar archivos de Python
echo -e "${YELLOW}📄 Verificando archivos de Python...${NC}"
if [ -f "pyproject.toml" ]; then
	echo -e "${GREEN}✅ pyproject.toml encontrado${NC}"
else
	echo -e "${YELLOW}⚠️  pyproject.toml no encontrado${NC}"
fi

if [ -f "requirements.txt" ]; then
	echo -e "${GREEN}✅ requirements.txt encontrado${NC}"
else
	echo -e "${YELLOW}⚠️  requirements.txt no encontrado${NC}"
fi

echo -e "${BLUE}🎉 Verificación completada${NC}"
