#!/data/data/com.termux/files/usr/bin/zsh

# Set the installation directory
INSTALL_DIR="/data/data/com.termux/files/home"

# Update Termux packages
pkg update && pkg upgrade -y

# Install essential packages including unzip
pkg install -y git openssh lsd nano zsh wget curl unzip

# Set Zsh as the default shell
chsh -s zsh

# Install Starship
pkg install starship

# Ensure ~/.config directory exists
mkdir -p "$INSTALL_DIR/.config"

# Configure Starship with Gruvbox Rainbow preset
starship preset gruvbox-rainbow -o "$INSTALL_DIR/.config/starship.toml"

# Download and install Hack Nerd Font for icons
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip -O ~/Hack.zip
unzip -o ~/Hack.zip -d ~/.local/share/fonts

# Clean up downloaded zip file
rm ~/Hack.zip

# Add Starship initialization and alias to ~/.zshrc
echo 'eval "$(starship init zsh)"' >> "$INSTALL_DIR/.zshrc"
echo "alias ll='lsd -la'" >> "$INSTALL_DIR/.zshrc"

# Notify user that fc-cache is unavailable on Termux
echo "Note: 'fc-cache' is not available in Termux. You may need to configure fonts manually in your terminal emulator."

# Reload Zsh configuration and restart shell session
if [ -f "$INSTALL_DIR/.zshrc" ]; then
    . "$INSTALL_DIR/.zshrc"  # Use . to source the file in Zsh
    echo "Zsh configuration reloaded."
    exec zsh  # Restart Zsh to apply changes
else
    echo "No .zshrc file found. You may want to create one."
fi

# Notify the user
echo "Installation complete! Zsh is now the default shell with Starship prompt, NerdFonts, and alias ll='lsd -la'."