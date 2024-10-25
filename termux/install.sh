#!/usr/bin/env bash

# Solicitar permisos de almacenamiento
termux-setup-storage

# Configurar repositorios de Europa
sed -i 's@https://packages.termux.dev/termux-main@https://europe.termux.dev/termux-main@g' $PREFIX/etc/apt/sources.list

# Actualizar e instalar paquetes básicos
pkg update && pkg upgrade -y
pkg install -y git lsd unzip openssh nano wget curl zsh

# Cambiar shell predeterminada a Zsh y continuar en Zsh
chsh -s zsh
export SHELL=$(which zsh)
exec zsh

# Añadir alias al .zshrc
cat << 'EOF' >> ~/.zshrc
alias ll="lsd -la"
alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"
alias git-update="git fetch --all --prune && git pull"
alias git-save="git add -A && git commit -m 'chore: commit save point' && git push origin HEAD"
EOF

# Recargar .zshrc
source ~/.zshrc

# Instalar Oh My Zsh sin interacción
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Definir ZSH_CUSTOM si no está establecido
ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

# Instalar el tema Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Modificar ZSH_THEME en .zshrc
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Instalar plugins de Oh My Zsh
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search $ZSH_CUSTOM/plugins/zsh-history-substring-search
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $ZSH_CUSTOM/plugins/autoupdate
git clone https://github.com/marlonrichert/zsh-autocomplete $ZSH_CUSTOM/plugins/zsh-autocomplete

# Añadir plugins al .zshrc
sed -i 's/plugins=(git)/plugins=(autoupdate aws colored-man-pages colorize composer dirhistory docker extract gh git history jsontools vi-mode wp-cli zsh-autosuggestions zsh-autocomplete zsh-completions zsh-history-substring-search z zsh-syntax-highlighting)/g' ~/.zshrc

# Configurar Git
git config --global --add safe.directory /storage/emulated/0/Documents/vault
git config --global credential.helper store
git config --global user.name "Jesús"
git config --global user.email "olagato@gmail.com"

echo "Instalación completa. Por favor, reinicia Termux para aplicar todos los cambios."
