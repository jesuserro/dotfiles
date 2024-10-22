#!/data/data/com.termux/files/usr/bin/zsh

# Global Variables
INSTALL_DIR="/data/data/com.termux/files/home"
PLUGIN_INSTALLER="$INSTALL_DIR/install_plugins.sh"

# Function to update and install essential packages
install_packages() {
    pkg update && pkg upgrade -y
    pkg install -y git openssh lsd nano zsh wget curl
}

# Function to install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$INSTALL_DIR/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
}

# Function to configure .zshrc
configure_zshrc() {
    local zshrc="$INSTALL_DIR/.zshrc"

    if [ ! -f "$zshrc" ]; then
        printf "No .zshrc file found. You may want to create one.\n" >&2
        return 1
    fi

    # Set Powerlevel10k as the default theme
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"

    # Enable plugins
    sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting)' "$zshrc"
    
    # Reload Zsh configuration properly
    zsh -ic "source $zshrc"
}

# Function to run plugin installation script
run_plugin_installer() {
    if [ -x "$PLUGIN_INSTALLER" ]; then
        "$PLUGIN_INSTALLER"
    else
        printf "Plugin installer script not found or not executable.\n" >&2
        return 1
    fi
}

# Main function
main() {
    install_packages
    chsh -s zsh  # Set Zsh as the default shell
    install_oh_my_zsh

    # Call plugin installer script
    if ! run_plugin_installer; then
        printf "Failed to install plugins.\n" >&2
        return 1
    fi

    # Configure .zshrc
    if configure_zshrc; then
        printf "Zsh configuration reloaded with Oh My Zsh, Powerlevel10k, and plugins.\n"
    else
        printf "Failed to reload Zsh configuration.\n" >&2
    fi

    # Notify the user
    printf "Installation complete! Zsh is now the default shell with Oh My Zsh, Powerlevel10k theme, Autosuggestions, Autocomplete, and Syntax Highlighting plugins.\n"
}

# Execute main
main
