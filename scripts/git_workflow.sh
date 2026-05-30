#!/bin/bash

# 🎨 Colores para el output en consola
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

echo -e "${CYAN}🗂️  Branch Policy & Git Aliases Guide${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

echo -e "${YELLOW}1 · Nueva política de ramas${NC}"
echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│ Rama           │ Propósito                                  │${NC}"
echo -e "${BLUE}├─────────────────┼─────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│ main            │ Producción – solo código estable           │${NC}"
echo -e "${BLUE}│ dev             │ Integración continua – todas las features  │${NC}"
echo -e "${BLUE}│ feature/*       │ Trabajo diario – una por funcionalidad     │${NC}"
echo -e "${BLUE}│ Tags (vX.Y.Z)   │ Versión inmutable de main                  │${NC}"
echo -e "${BLUE}│ hotfix/*        │ Parche crítico sobre main                  │${NC}"
echo -e "${BLUE}└─────────────────┴─────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${YELLOW}2 · Flujo estándar${NC}"
echo -e "${GREEN}1.${NC} Crea tu rama feature desde dev:"
echo -e "   ${CYAN}git checkout dev && git pull && git checkout -b feature/mi-feature${NC}"
echo ""
echo -e "${GREEN}2.${NC} Una vez terminada → integra en dev:"
echo -e "   ${CYAN}git feat mi-feature${NC}"
echo ""
echo -e "${GREEN}3.${NC} Cuando dev está listo para producción → release:"
echo -e "   ${CYAN}git rel${NC}                    # Versión automática vAAAA.MM.DD_HHMM"
echo -e "   ${CYAN}git rel 2.1.0${NC}              # Versión específica v2.1.0"
echo ""

echo -e "${YELLOW}3 · Comandos disponibles${NC}"
echo -e "${GREEN}•${NC} ${CYAN}git feat <nombre>${NC}     - Integra feature en dev y la archiva"
echo -e "${GREEN}•${NC} ${CYAN}git rel [versión]${NC}     - Publica dev → main + tag"
echo -e "${GREEN}•${NC} ${CYAN}git start-feature <nombre>${NC} - Crea nueva rama feature desde dev"
echo -e "${GREEN}•${NC} ${CYAN}git merge-cleanup <nombre>${NC} - Flujo completo (legacy)"
echo ""

echo -e "${YELLOW}4 · Reglas de oro${NC}"
echo -e "${RED}•${NC} Nunca trabajar directamente en main"
echo -e "${RED}•${NC} dev debe ser siempre integrable (tests verdes)"
echo -e "${RED}•${NC} Una feature = una rama = vida corta"
echo -e "${RED}•${NC} Tags solo después de release"
echo ""

echo -e "${YELLOW}5 · Ejemplos de uso${NC}"
echo -e "${CYAN}# Crear y trabajar en una feature${NC}"
echo -e "git start-feature adding-dbt"
echo -e "git add . && git commit -m \"feat(dbt): add new models\""
echo -e "git push origin feature/adding-dbt"
echo ""
echo -e "${CYAN}# Integrar feature en dev${NC}"
echo -e "git feat adding-dbt"
echo ""
echo -e "${CYAN}# Hacer release a producción${NC}"
echo -e "git rel"
echo -e "git rel 2.1.0"
echo ""

echo -e "${YELLOW}6 · Configuración de Tests${NC}"
echo -e "${GREEN}•${NC} ${CYAN}Node.js${NC}: Añade \"test\" script en package.json"
echo -e "${GREEN}•${NC} ${CYAN}Python${NC}: Configura pytest en pyproject.toml (usa python3)"
echo -e "${GREEN}•${NC} ${CYAN}Java${NC}: Configura maven-surefire-plugin en pom.xml"
echo -e "${GREEN}•${NC} ${CYAN}Makefile${NC}: Añade target 'test:' o 'tests:'"
echo -e "${GREEN}•${NC} ${CYAN}Personalizado${NC}: Crea scripts/test.sh"
echo -e "${BLUE}💡 El script git rel ejecuta tests automáticamente antes del release${NC}"
echo ""

echo -e "${GREEN}✅ Checklist rápida${NC}"
echo -e "${GREEN}☐${NC} Scripts en scripts/ y con permisos +x"
echo -e "${GREEN}☐${NC} Alias añadidos a ~/.gitconfig"
echo -e "${GREEN}☐${NC} Tests automáticos listos"
echo -e "${GREEN}☐${NC} Equipo informado de la nueva convención"
echo ""
echo -e "${CYAN}¡Listo! Disfruta de un flujo Git limpio y predecible 🚀${NC}"
