#!/data/data/com.termux/files/usr/bin/bash
set -e

# Configurar acceso al almacenamiento
termux-setup-storage

# Nota: 'termux-change-repo' es interactivo y debe ejecutarse manualmente si es necesario.
echo "Si deseas cambiar los repositorios a servidores cercanos en Europa, por favor ejecuta 'termux-change-repo' manualmente."

# Actualizar e instalar actualizaciones disponibles
pkg update && pkg upgrade -y

# Instalar paquetes básicos
pkg install -y git lsd unzip openssh nano wget curl zsh

# Cambiar la shell predeterminada a zsh en Termux
echo "Configurando zsh como shell predeterminada en Termux."
mkdir -p ~/.termux
echo "zsh" > ~/.termux/shell

# Cerrar la sesión para que el cambio de shell tenga efecto
echo "Es necesario reiniciar Termux para aplicar los cambios. Por favor, cierra y vuelve a abrir Termux y vuelve a ejecutar este script para continuar la instalación."
exit 0

# Desde aquí, el script continuará después de reiniciar Termux y ejecutar de nuevo este script.

# Verificar si la shell actual es zsh
if [ "$(basename "$SHELL")" != "zsh" ]; then
  echo "La shell actual no es zsh. Por favor, reinicia Termux y ejecuta de nuevo este script."
  exit 1
fi

# Instalar Oh My Zsh
echo "Instalando Oh My Zsh..."
RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Clonar plugins de Oh My Zsh
echo "Clonando plugins de Oh My Zsh..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-history-substring-search $ZSH_CUSTOM/plugins/zsh-history-substring-search
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $ZSH_CUSTOM/plugins/autoupdate
git clone https://github.com/marlonrichert/zsh-autocomplete $ZSH_CUSTOM/plugins/zsh-autocomplete

# Respaldar .zshrc existente si existe
if [ -f ~/.zshrc ]; then
  echo "Respaldo del archivo .zshrc existente..."
  mv ~/.zshrc ~/.zshrc.backup
fi

# Crear nuevo archivo .zshrc con tus configuraciones
echo "Creando nuevo archivo .zshrc con configuraciones personalizadas..."
cat > ~/.zshrc << 'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  history-substring-search
  autoupdate
  zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

alias ll='lsd -la'
alias ups='pkg update -y && pkg upgrade -y && omz update && upgrade_oh_my_zsh_custom'
alias git-update='git fetch --all --prune && git pull'
alias git-save='git add -A && git commit -m "chore: commit save point" && git push origin HEAD'
EOF

# Aplicar el nuevo .zshrc
echo "Aplicando el nuevo archivo .zshrc..."
source ~/.zshrc

# Configurar Git
echo "Configurando Git..."
git config --global --add safe.directory /storage/emulated/0/Documents/vault
git config --global credential.helper store
git config --global user.name "Jesús"
git config --global user.email "olagato@gmail.com"

# Crear el directorio vault si no existe y navegar a él
echo "Creando y navegando al directorio 'vault'..."
mkdir -p /data/data/com.termux/files/home/storage/shared/Documents/vault
cd /data/data/com.termux/files/home/storage/shared/Documents/vault

echo "Instalación completada."
