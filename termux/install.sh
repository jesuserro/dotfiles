#!/bin/bash

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
    
    # Crear o modificar el archivo ~/.zshrc con un alias para lsd
    echo 'alias ll="lsd -la"' >> ~/.zshrc
    echo "Alias ll configurado en ~/.zshrc."
else
    echo "Error: Zsh no se ha instalado correctamente o no es ejecutable."
fi

# Confirmación de instalación
echo "Instalación completada de los paquetes básicos, Zsh configurado como shell por defecto (si la instalación fue exitosa), y alias ll añadido a ~/.zshrc."
