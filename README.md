# Dotfiles

My **BETA** dotfiles for Ubuntu 20.04, Zsh, Oh My Zsh, TMUX, and NVim. Based on the [RCM](https://github.com/thoughtbot/rcm) dotfile framework. This project is in development mode, so you may encounter bugs. **Please don't use this if you're not familiar with these tools.**

## Install

### RCM

```shell
sudo apt update -y \
&& sudo apt upgrade -y \
&& sudo apt autoremove -y \
&& sudo apt install -y rcm
```

### Dotfiles

```shell
# Create local dotfiles directory
mkdir -p ~/dotfiles-local

# Create example local dotfiles
touch ~/dotfiles-local/gitconfig.local
touch ~/dotfiles-local/aliases.local

# Clone dotfiles repository
git clone https://github.com/jesuserro/dotfiles.git ~/dotfiles

# Install the dotfiles (create symlinks)
env RCRC=$HOME/dotfiles/rcrc rcup
```

After the initial installation, you can run `rcup` without setting the `RCRC` environment variable. This command will create symlinks for config files in your home directory:

```shell
rcup
```

## Update

To link any new files and install new vim plugins:

```shell
rcup
source ~/.zshrc
pkill -f tmux
```

## Adding New Dots

You can add vim support by doing this:

```shell
touch ~/.vim
mkrc ~/.vim
rcup
```

For more information on adding new files, visit [RCM Documentation](http://thoughtbot.github.io/rcm/).

## Customizations

Create a directory for your personal customizations:

```shell
mkdir -p ~/dotfiles-local
```

Put your customizations in `~/dotfiles-local` appended with `.local`:

- `~/dotfiles-local/aliases.local`
- `~/dotfiles-local/gitconfig.local`
- `~/dotfiles-local/tmux.conf.local`
- `~/dotfiles-local/vimrc.local`
- `~/dotfiles-local/zshrc.local`

## .zshrc Configuration

Edit your `~/dotfiles/zshrc` like this:

```shell
# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
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
source $ZSH/oh-my-zsh.sh

# User configuration
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.aliases ]] && source ~/.aliases
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

## Oh My ZSH Plugins

Here are some popular plugins to enhance your `Oh My Zsh` experience:

| Plugin                          | Git Command                                                                                                                    | Description                                                                                                                |
|---------------------------------|---------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| autoupdate                      | `git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate`  | Automatically updates `oh-my-zsh` and its plugins.                                                                         |
| aws                             | `git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aws ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/aws`       | Adds auto-completion for AWS CLI commands.                                                                                 |
| docker                          | `git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/docker` | Adds auto-completion and aliases for Docker.                                                                               |
| gh                              | `git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gh ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/gh`         | Adds auto-completion and aliases for GitHub CLI.                                                                           |
| vi-mode                         | `git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/vi-mode` | Adds vi keybindings for command line editing.                                                                              |
| wp-cli                          | `git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/wp-cli ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/wp-cli` | Adds auto-completion for WP-CLI commands.                                                                                  |
| z                               | `git clone https://github.com/rupa/z ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/z`                                          | Quickly navigates to directories you use frequently.                                                                       |
| zsh-autosuggestions             | `git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions` | Suggests commands based on history as you type.                                                                            |
| zsh-completions                 | `git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions`         | Provides additional completions for many commands.                                                                         |
| zsh-history-substring-search    | `git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search` | Searches your command history by substring.                                                                                |
| zsh-nvm                         | `git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-nvm`                       | Manages Node.js versions.                                                                                                  |
| zsh-syntax-highlighting         | `git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting` | Highlights syntax in your command line.  |

Installing Github Copilot (gh) extension:

```shell
sudo apt update -y \
&& sudo apt install -y gh

gh extension install github/gh-copilot
```

## Termux Installation

```shell
curl 'https://raw.githubusercontent.com/jesuserro/dotfiles/main/termux/install.sh' | sh
```

## Resources

- [Install ZSH in Ubuntu](https://www.tecmint.com/install-oh-my-zsh-in-ubuntu/)
- [Oh My Zsh Plugins](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)
- [TMUX Configuration](https://github.com/gpakosz/.tmux)
- [Neovim](https://neovim.io/)
- [Vim Color Schemes](https://vimcolorschemes.com/)

## Inspired by

- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)
- [thoughtbot/rcm](https://github.com/thoughtbot/rcm)
```