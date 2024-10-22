#!/bin/bash

# Set the installation directory
INSTALL_DIR="/data/data/com.termux/files/home"

# Update Termux packages
pkg update && pkg upgrade -y

# Install essential packages
pkg install -y git openssh lsd nano zsh wget curl

# Set Zsh as the default shell
chsh -s zsh

# Install Starship
pkg install starship

# Configure Starship with Gruvbox Rainbow preset
mkdir -p ~/.config
starship preset gruvbox-rainbow -o ~/.config/starship.toml

# Download and install Hack Nerd Font for icons (example method)
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip -O ~/Hack.zip
unzip ~/Hack.zip -d ~/.local/share/fonts
fc-cache -fv

# Notify the user
echo "Installation complete! Zsh is now the default shell with Starship prompt and NerdFonts."
