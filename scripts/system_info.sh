#!/bin/bash

echo -e "\n\e[1;34mInformación del Sistema:\e[0m"

# Mostrar el nombre del PC
echo -e "\e[1;33mNombre del PC:\e[0m $(hostname)"

# Mostrar la versión del sistema operativo
echo -e "\e[1;33mSistema Operativo:\e[0m $(lsb_release -d | cut -f2)"

# Mostrar la versión del kernel
echo -e "\e[1;33mVersión del Kernel:\e[0m $(uname -r)"

# Mostrar la carga de la CPU
echo -e "\e[1;33mUso de la CPU:\e[0m $(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/')% idle"

# Mostrar el uso de la memoria
echo -e "\e[1;33mUso de Memoria RAM:\e[0m $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"

# Mostrar el uso del disco duro (tamaño ocupado/Tamaño Total en GB)
echo -e "\e[1;33mUso del Disco Duro:\e[0m $(df -h --total | grep 'total' | awk '{print $3 "/" $2 " (" $5 " usado)"}')"

# Mostrar la IP local
echo -e "\e[1;33mIP Local:\e[0m $(hostname -I | awk '{print $1}')"

# Mostrar la IP pública (requiere conexión a internet)
echo -e "\e[1;33mIP Pública:\e[0m $(curl -s https://api.ipify.org)"

# Mostrar el estado de los servicios principales
echo -e "\n\e[1;34mEstado de Servicios:\e[0m"
echo -e "\e[1;33mDocker:\e[0m $(systemctl is-active docker)"
echo -e "\e[1;33mApache:\e[0m $(systemctl is-active apache2)"
echo -e "\e[1;33mMySQL:\e[0m $(systemctl is-active mysql)"

# Mostrar la conectividad a Internet
echo -e "\n\e[1;34mConectividad a Internet:\e[0m"
if ping -c 3 google.com &> /dev/null; then
    echo -e "\e[1;33mConectividad:\e[0m \e[32mConectado\e[0m"
else
    echo -e "\e[1;33mConectividad:\e[0m \e[31mDesconectado\e[0m"
fi
