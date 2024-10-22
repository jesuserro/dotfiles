#!/data/data/com.termux/files/usr/bin/zsh

# Global Variables
INSTALL_DIR="/data/data/com.termux/files/home"
ZSH_CUSTOM="${ZSH_CUSTOM:-$INSTALL_DIR/.oh-my-zsh/custom}"

# Function to install a plugin or theme via git
install_plugin() {
    local repo_url=$1
    local target_dir=$2

    if [ ! -d "$target_dir" ]; then
        git clone --depth=1 "$repo_url" "$target_dir"
    fi
}

# Main function to install all plugins and themes
main() {
    # Install Zsh Autosuggestions
    install_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    
    # Install Zsh Autocomplete
    install_plugin "https://github.com/marlonrichert/zsh-autocomplete" "$ZSH_CUSTOM/plugins/zsh-autocomplete"
    
    # Install Zsh Syntax Highlighting
    install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    
    # Install Powerlevel10k theme
    install_plugin "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"

    printf "Plugins and themes installed successfully.\n"
}

# Execute main
main
