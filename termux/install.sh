#!/usr/bin/env bash

# Solicitar permisos de almacenamiento
termux-setup-storage

# No modificar los repositorios por defecto
# sed -i 's@https://packages.termux.dev/termux-main@https://europe.termux.dev/termux-main@g' $PREFIX/etc/apt/sources.list

# Actualizar e instalar paquetes básicos
pkg update && pkg upgrade -y
pkg install -y git lsd unzip openssh nano wget curl zsh

# Configurar Zsh como shell predeterminada en Termux
mkdir -p ~/.termux
echo "zsh" > ~/.termux/shell

# Añadir alias al .zshrc usando sed
sed -i '$ a\
alias ll="lsd -la"\
alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"\
alias git-update="git fetch --all --prune && git pull"\
alias git-save="git add -A && git commit -m '\''chore: commit save point'\'' && git push origin HEAD"' ~/.zshrc

# Instalar Oh My Zsh sin interacción si no está instalado
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Definir ZSH_CUSTOM si no está establecido
ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

# Instalar el tema Powerlevel10k si no está instalado
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
fi

# Modificar ZSH_THEME en .zshrc
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Instalar plugins de Oh My Zsh si no están instalados
plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  autoupdate
  zsh-autocomplete
)

for plugin in "${plugins[@]}"; do
  if [ ! -d "${ZSH_CUSTOM}/plugins/${plugin}" ]; then
    case $plugin in
      autoupdate)
        git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ${ZSH_CUSTOM}/plugins/${plugin}
        ;;
      zsh-autocomplete)
        git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM}/plugins/${plugin}
        ;;
      *)
        git clone https://github.com/zsh-users/${plugin} ${ZSH_CUSTOM}/plugins/${plugin}
        ;;
    esac
  fi
done

# Añadir plugins al .zshrc
sed -i 's/^plugins=(.*)/plugins=(autoupdate aws colored-man-pages colorize composer dirhistory docker extract gh git history jsontools vi-mode wp-cli zsh-autosuggestions zsh-autocomplete zsh-completions zsh-history-substring-search z zsh-syntax-highlighting)/' ~/.zshrc

# Configurar Git
git config --global --add safe.directory /storage/emulated/0/Documents/vault
git config --global credential.helper store
git config --global user.name "Jesús"
git config --global user.email "olagato@gmail.com"

echo "Instalación completa. Por favor, reinicia Termux o inicia una nueva sesión para aplicar todos los cambios."
