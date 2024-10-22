#!/bin/bash

# Directorio de Oh My Zsh
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OH_MY_ZSH_DIR/custom"

# Lista de plugins a instalar
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
  tmux
  vi-mode
  wp-cli
  z
  zsh-autosuggestions
  zsh-completions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

# Verificar si Zsh está instalado
if ! command -v zsh >/dev/null 2>&1; then
    echo "Zsh no está instalado. Instalando Zsh..."
    pkg install -y zsh
fi

# Actualizar paquetes de Termux e instalar paquetes esenciales
pkg update && pkg upgrade -y
pkg install -y git openssh lsd nano wget curl

# Establecer Zsh como shell predeterminado
chsh -s $(which zsh)

# Instalar Oh My Zsh
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh ya está instalado."
fi

# Instalar plugins de Oh My Zsh
for plugin in "${plugins[@]}"; do
    plugin_dir="$ZSH_CUSTOM/plugins/$plugin"
    if [ ! -d "$plugin_dir" ]; then
        echo "Instalando plugin $plugin..."
        case $plugin in
            zsh-autosuggestions)
                git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
                ;;
            zsh-syntax-highlighting)
                git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"
                ;;
            zsh-autocomplete)
                git clone https://github.com/marlonrichert/zsh-autocomplete "$plugin_dir"
                ;;
            zsh-history-substring-search)
                git clone https://github.com/zsh-users/zsh-history-substring-search "$plugin_dir"
                ;;
            zsh-completions)
                git clone https://github.com/zsh-users/zsh-completions "$plugin_dir"
                ;;
            *)
                echo "El plugin $plugin se gestionará automáticamente por Oh My Zsh."
                ;;
        esac
    else
        echo "El plugin $plugin ya está instalado."
    fi
done

# Instalar tema Powerlevel10k
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Instalando tema Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    echo "El tema Powerlevel10k ya está instalado."
fi

# Respaldar .zshrc existente
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    echo "Archivo .zshrc existente respaldado en .zshrc.backup"
fi

# Crear nuevo archivo .zshrc con la configuración deseada
cat > "$HOME/.zshrc" <<EOL
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  ${plugins[@]}
)

source \$ZSH/oh-my-zsh.sh

alias ll="lsd -la"

# Cargar configuración de Powerlevel10k si existe
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOL

echo "Archivo .zshrc actualizado con la nueva configuración."

# Iniciar Zsh
exec zsh
