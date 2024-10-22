#!/bin/bash

# Cambiar mirrors a Europa (Alemania)
echo "Cambiando mirrors a Europa..."
termux-change-repo --stable-main --stable-universe --select-repo -r stable

# Resolver conflictos de sources.list automáticamente forzando a mantener la versión del mantenedor
echo "Forzando la instalación de la versión del mantenedor para evitar conflicto con sources.list..."
DEBIAN_FRONTEND=noninteractive dpkg --configure -a
apt-get -o Dpkg::Options::="--force-confnew" --fix-broken install

# Actualizar e instalar las actualizaciones disponibles
echo "Actualizando e instalando paquetes..."
pkg update && pkg upgrade -y

# Instalar paquetes básicos
echo "Instalando paquetes básicos: git, lsd, unzip, openssh, nano, wget, curl..."
pkg install -y git lsd unzip openssh nano wget curl

# Instalar Zsh
echo "Instalando Zsh..."
pkg install -y zsh

# Verificar si Zsh está correctamente instalado antes de configurarlo como shell por defecto
if [ -x "$(command -v zsh)" ]; then
    echo "Estableciendo Zsh como shell por defecto..."
    chsh -s zsh
else
    echo "Error: Zsh no se ha instalado correctamente o no es ejecutable."
fi

# Confirmación de instalación
echo "Instalación completada de los paquetes básicos y Zsh configurado como shell por defecto (si la instalación fue exitosa)."
