#!/bin/bash

# Cambiar mirrors a Europa
echo "Cambiando mirrors a Europa..."
termux-change-repo --stable-main --stable-universe --select-repo -r stable

# Resolver posibles conflictos
dpkg --configure -a

# Actualizar paquetes
echo "Actualizando e instalando paquetes..."
pkg update && pkg upgrade -y

# Instalar paquetes básicos
pkg install -y git lsd unzip openssh nano wget curl zsh

# Verificar Zsh
if [ -x "$(command -v zsh)" ]; then
    chsh -s zsh
    echo "Zsh instalado y configurado como shell por defecto."
else
    echo "Zsh no se instaló correctamente."
fi
