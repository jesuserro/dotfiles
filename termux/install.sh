#!/bin/bash

# Cambiar mirrors a Europa (Alemania)
echo "Cambiando mirrors a Europa (Alemania)..."
termux-change-repo --stable-main --stable-universe --select-repo -r stable

# Actualizar e instalar las actualizaciones disponibles
echo "Actualizando paquetes..."
pkg update && pkg upgrade -y

# Instalar paquetes básicos
echo "Instalando paquetes básicos: git, lsd, unzip, openssh, nano, wget, curl..."
pkg install -y git lsd unzip openssh nano wget curl

# Instalar Zsh
echo "Instalando Zsh..."
pkg install -y zsh

# Configurar Zsh como shell por defecto
echo "Estableciendo Zsh como shell por defecto..."
chsh -s zsh

# Confirmación de instalación
echo "Instalación completada de los paquetes básicos y Zsh configurado como shell por defecto."
