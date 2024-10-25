#!/data/data/com.termux/files/usr/bin/bash

# Acceso a /data/data/com.termux/files/home/storage/shared/Documents/vault
termux-setup-storage

# Servidores cercanos en Europe 
termux-change-repo

# Actualizar e instalar las actualizaciones disponibles
pkg update && pkg upgrade -y

# Instalar paquetes básicos
pkg install -y git lsd unzip openssh nano wget curl

# Instalar Zsh
pkg install -y zsh

# chsh -s zsh
# source ~/.zshrc 

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions && \
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search && \
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ~/.oh-my-zsh/custom/plugins/autoupdate && \
git clone https://github.com/marlonrichert/zsh-autocomplete ~/.oh-my-zsh/custom/plugins/zsh-autocomplete && \
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Añadir alias al .zshrc usando sed
sed -i '$ a\
alias ll="lsd -la"\
alias ups="pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom"\
alias git-update="git fetch --all --prune && git pull"\
alias git-save="git add -A && git commit -m '\''chore: commit save point'\'' && git push origin HEAD"' ~/.zshrc

#cd /data/data/com.termux/files/home/storage/shared/Documents/vault
git config --global --add safe.directory /storage/emulated/0/Documents/vault
git config --global credential.helper store
git config --global user.name "Jesús"
git config --global user.email "olagato@gmail.com"

echo "Instalación completa. Por favor, reinicia Termux para aplicar todos los cambios."