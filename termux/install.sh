#!/usr/bin/env zsh

# Set the installation directory
INSTALL_DIR="$HOME"

# Update Termux packages
pkg update -y && pkg upgrade -y

# Install essential packages
pkg install -y git openssh lsd nano zsh wget curl

# Install Oh My Zsh manually

# Clone the Oh My Zsh repository
git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"

# Copy the template .zshrc to your home directory
cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

# Set Zsh as the default shell in Termux
# Since chsh doesn't work in Termux, we can start zsh from bash
echo "exec zsh" >> "$HOME/.bashrc"

# Define ZSH_CUSTOM
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Install Oh My Zsh plugins

# Zsh Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# Zsh Autocomplete
git clone https://github.com/marlonrichert/zsh-autocomplete "$ZSH_CUSTOM/plugins/zsh-autocomplete"

# Zsh Syntax Highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# Update .zshrc to set Powerlevel10k as the default theme
sed -i 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"

# Enable plugins in .zshrc
sed -i 's|^plugins=(.*)|plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting)|' "$HOME/.zshrc"

# Reload Zsh configuration
if [ -f "$HOME/.zshrc" ]; then
    echo "Zsh configuration updated."
else
    echo "No .zshrc file found. You may want to create one."
fi

# Notify the user
echo "Installation complete! Zsh is now installed with Oh My Zsh, Powerlevel10k theme, and the specified plugins."

# Start Zsh
exec zsh
