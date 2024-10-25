#!/data/data/com.termux/files/usr/bin/bash

# Configurar acceso al almacenamiento
termux-setup-storage

# Actualizar e instalar actualizaciones disponibles
pkg update && pkg upgrade -y

# Instalar paquetes básicos
pkg install -y git lsd unzip openssh nano wget curl zsh

# Instalar Oh My Zsh sin cambiar la shell inmediatamente
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Cambiar la shell predeterminada a zsh
chsh -s zsh

# Clonar plugins de Oh My Zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ~/.oh-my-zsh/custom/plugins/autoupdate
git clone https://github.com/marlonrichert/zsh-autocomplete ~/.oh-my-zsh/custom/plugins/zsh-autocomplete

# Respaldar .zshrc existente si existe
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup

# Crear nuevo archivo .zshrc con tus configuraciones
cat << 'EOF' > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  autoupdate
  zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

alias ll="lsd -la"
alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"
alias git-update="git fetch --all --prune && git pull"
alias git-save="git add -A && git commit -m 'chore: commit save point' && git push origin HEAD"
EOF

# Aplicar el nuevo .zshrc
source ~/.zshrc

# Configurar Git
git config --global --add safe.directory /storage/emulated/0/Documents/vault
git config --global credential.helper store
git config --global user.name "Jesús"
git config --global user.email "olagato@gmail.com"

# Crear el directorio vault si no existe y navegar a él
mkdir -p /data/data/com.termux/files/home/storage/shared/Documents/vault
cd /data/data/com.termux/files/home/storage/shared/Documents/vault
