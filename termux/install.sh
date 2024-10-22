#!/data/data/com.termux/files/usr/bin/zsh

# Set the installation directory
INSTALL_DIR="/data/data/com.termux/files/home"

# Update Termux packages
pkg update && pkg upgrade -y

# Install essential packages including unzip and curl
pkg install -y git openssh lsd nano zsh wget curl

# Set Zsh as the default shell
chsh -s zsh

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Oh My Zsh plugins

# Zsh Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Zsh Autocomplete
git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# Zsh Syntax Highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Update .zshrc to set Powerlevel10k as the default theme
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$INSTALL_DIR/.zshrc"

# Enable plugins in .zshrc
sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting)' "$INSTALL_DIR/.zshrc"

# Reload Zsh configuration
if [ -f "$INSTALL_DIR/.zshrc" ]; then
    # Source the .zshrc file
    source "$INSTALL_DIR/.zshrc"
    echo "Zsh configuration reloaded with Oh My Zsh, Powerlevel10k, and plugins."
    exec zsh  # Restart Zsh to apply changes
else
    echo "No .zshrc file found. You may want to create one."
fi

# Notify the user
echo "Installation complete! Zsh is now the default shell with Oh My Zsh, Powerlevel10k theme, Autosuggestions, Autocomplete, and Syntax Highlighting plugins."