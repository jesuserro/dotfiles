# Dotfiles
My BETA dotfiles for Ubuntu 20.04, Zsh, Oh My Zsh, TMUX and NVim. Based on [RCM](https://github.com/thoughtbot/rcm) dotfile framework. This project is in develop mode, so you can encounter many bugs. Please don't use this if you're not familiarized with these tools.

## Install
### RCM
``` shell
sudo apt update -y \
	&& sudo apt upgrade -y \
	&& sudo apt autoremove

sudo apt install -y rcm
```

### Dofiles
```shell
cd
mkdir ~/dotfiles-local \
	&& cd ~/dotfiles-local \
	&& touch ~/dotfiles-local/gitconfig.local \
	&& touch ~/dotfiles-local/aliases.local \
	&& cd ~

# Load dotfiles, theme and plugins
git clone https://github.com/jesuserro/dotfiles.git

# Install the dotfiles (create symlinks)
env RCRC=$HOME/dotfiles/rcrc rcup
	overwrite ~/.bashrc? [ynaq] y
	overwrite ~/.gitconfig? [ynaq] y
	overwrite ~/.vimrc? [ynaq] y
	overwrite ~/.zshrc? [ynaq] y

source ~/.zshrc
```

After the initial installation, you can run `rcup` without the one-time variable `RCRC` being set (`rcup` will symlink the repo's `rcrc` to `~/.rcrc` for future runs of `rcup`). [See example](https://github.com/thoughtbot/dotfiles/blob/master/rcrc).

This command will create symlinks for config files in your home directory. Setting the `RCRC` environment variable tells `rcup` to use standard configuration options:

-   Exclude the `README.md`, `README-ES.md` and `LICENSE` files, which are part of the `dotfiles` repository but do not need to be symlinked in.
-   Give precedence to personal overrides which by default are placed in `~/dotfiles-local`
-   Please configure the `rcrc` file if you'd like to make personal overrides in a different directory

## Update
**After creating any new dotfiles-local file** (by example: `~/dotfiles-local/gitconfig.local`): 
``` shell
touch ~/dotfiles-local/gitconfig.local
vim ~/dotfiles-local/gitconfig.local
	1 [user]
	2     name = <Your_User>
	3     email = <Your_User>@<YOUR_DOMAIN>.com
	:wq
```

**do the next**. From time to time you should pull down any updates to these dotfiles, and run:
``` shell
# Crea symlinks entre estos dotfiles y el sistema en ~
rcup

# También puedes probar:
source ~/.zshrc

# Para quitar paneles de TMUX:
pkill -f tmux
```

to link any new files and install new vim plugins. 

A new symlik should have been automatically created:
``` shell
cd
ls -la
	# Created the first time from ~/dotfiles/zshrc:
	.gitconfig -> ~/dotfiles/gitconfig
	# New symlink created from rcup:
	.gitconfig.local -> ~/dotfiles-local/gitconfig.local

# Check if new changes are available:
git config --list
```

**Note** You _must_ run `rcup` after pulling to ensure that all files in plugins are properly installed, but you can safely run `rcup` multiple times so update early and update often!

## Adding new dots
You can add vim support by doing this:
```shell
# Create blank .vim
touch ~/.vim

mkrc ~/.vim

# Se crean los symlynk que une este .vim en el user con mis dotfiles
rcup
```

More info on adding new files: http://thoughtbot.github.io/rcm/

## Make your own customizations
Create a directory for your personal customizations:
```shell
mkdir ~/dotfiles-local
```

Put your customizations in `~/dotfiles-local` appended with `.local`:
```shell
~/dotfiles-local/aliases.local
~/dotfiles-local/git_template.local/*
~/dotfiles-local/gitconfig.local
~/dotfiles-local/tmux.conf.local
~/dotfiles-local/vimrc.local
~/dotfiles-local/vimrc.bundles.local
~/dotfiles-local/zshrc.local
~/dotfiles-local/zsh/configs/*
```

## Calling dotfiles from ~/.zshrc

``` shell
cd
ls -la
	.aliases -> /home/ubuntu/dotfiles/aliases
	.bashrc -> /home/ubuntu/dotfiles/bashrc
	.gitconfig -> /home/ubuntu/dotfiles/gitconfig
	.tmux.conf -> /home/ubuntu/dotfiles/tmux.conf
	.zshrc -> /home/ubuntu/dotfiles/zshrc
```

Edit your `~/dotfiles/zshrc` like this:

``` shell
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	colorize
	colored-man-pages
	history
	dirhistory
	jsontools
	zsh-autosuggestions
	zsh-syntax-highlighting
	autoupdate
	vi-mode
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

## Aliases
[[202211210836 Aliases]]

## Info
- [Install ZSH in Ubuntu](https://www.tecmint.com/install-oh-my-zsh-in-ubuntu/)
- [Plugins Oh my Zsh](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)
	- [AWS plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aws)
- [Plugins de la comunidad](https://github.com/zsh-users)
	- TMUX based on: https://github.com/gpakosz/.tmux
	- @si4tar: https://www.youtube.com/watch?v=1dDahc214co

## Inspired by
- https://github.com/thoughtbot/dotfiles
- https://github.com/thoughtbot/rcm

## TMUX
  - https://github.com/gpakosz/.tmux
  - Cheatsheet: https://tmuxcheatsheet.com/
  
## Bash
  - https://overthewire.org/wargames/bandit/
  - https://www.youtube.com/watch?v=RUorAzaDftg

## NVIM
Adopting Neovim as default editor:
``` shell
sudo apt-get install neovim
```

## Vimrc
Deprecated for me.
### Download Vim Color Schemes
If you do not have such a directory, create one with the command:

``` shell
mkdir ~/.vim/colors
```

Download scheme from: https://vimcolorschemes.com/

Now move the new scheme into it:

``` shell
mv ~/Downloads/[vim_colorscheme]  ~/.vim/colors
```