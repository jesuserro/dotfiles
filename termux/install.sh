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

# Instalar Oh My Zsh sin interacción
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Instalar Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Instalar plugins de Oh My Zsh
ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

# Clonar los repositorios de los plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM}/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM}/plugins/zsh-history-substring-search
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ${ZSH_CUSTOM}/plugins/autoupdate
git clone https://github.com/agkozak/zsh-z ${ZSH_CUSTOM}/plugins/z
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

# Añadir alias al .zshrc
cat << 'EOF' >> ~/.zshrc

# Alias personalizados
alias ll="lsd -la"
alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"
alias git-update="git fetch --all --prune && git pull"
alias git-save="git add -A && git commit -m 'chore: commit save point' && git push origin HEAD"
EOF

# Configurar el tema y los plugins en .zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Añadir plugins al .zshrc con "zsh-syntax-highlighting" al final
sed -i '/^plugins=/d' ~/.zshrc
cat << 'EOF' >> ~/.zshrc

# Plugins de Oh My Zsh
plugins=(
  autoupdate
  aws
  colored-man-pages
  colorize
  composer
  dirhistory
  docker
  extract
  gh
  git
  history
  jsontools
  vi-mode
  wp-cli
  zsh-autosuggestions
  zsh-autocomplete
  zsh-completions
  zsh-history-substring-search
  z
  zsh-syntax-highlighting
)
EOF

# Recargar .zshrc
source ~/.zshrc

# Configurar Git
git config --global --add safe.directory /storage/emulated/0/Documents/vault
git config --global credential.helper store
git config --global user.name "Jesús"
git config --global user.email "olagato@gmail.com"

echo "Instalación completa. Por favor, reinicia Termux para aplicar todos los cambios."
