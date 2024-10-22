#!/data/data/com.termux/files/usr/bin/zsh

# Global Variables
INSTALL_DIR="/data/data/com.termux/files/home"
ZSH_CUSTOM="${ZSH_CUSTOM:-$INSTALL_DIR/.oh-my-zsh/custom}"

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

# Function to install a plugin or theme via git
install_plugin() {
    local repo_url=$1
    local target_dir=$2

    if [ ! -d "$target_dir" ]; then
        git clone --depth=1 "$repo_url" "$target_dir"
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
    
    # Reload .zshrc
    . "$zshrc" || return 1
    exec zsh  # Restart Zsh to apply changes
}

# Main function
main() {
    install_packages
    chsh -s zsh  # Set Zsh as the default shell
    install_oh_my_zsh

    # Install plugins and themes
    install_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    install_plugin "https://github.com/marlonrichert/zsh-autocomplete" "$ZSH_CUSTOM/plugins/zsh-autocomplete"
    install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    install_plugin "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"

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
