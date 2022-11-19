# Installing ZSH & OhMyZSH

- [[#1 Installing ZSH|1 Installing ZSH]]
- [[#2 Installing OhMyZSH (OMZ)|2 Installing OhMyZSH (OMZ)]]
	- [[#2 Installing OhMyZSH (OMZ)#2.1 [Optional] Uninstall OMZ|2.1 [Optional] Uninstall OMZ]]
	- [[#2 Installing OhMyZSH (OMZ)#2.2 Referencias|2.2 Referencias]]
	- [[#2 Installing OhMyZSH (OMZ)#2.3 Themes|2.3 Themes]]
		- [[#2.3 Themes#2.3.1 Default themes|2.3.1 Default themes]]
		- [[#2.3 Themes#2.3.2 Instalar Powerlevel10k vía OMZ|2.3.2 Instalar Powerlevel10k vía OMZ]]
			- [[#2.3.2 Instalar Powerlevel10k vía OMZ#2.3.2.1 Installing theme core|2.3.2.1 Installing theme core]]
			- [[#2.3.2 Instalar Powerlevel10k vía OMZ#2.3.2.2 Instalar Meslo Fonts|2.3.2.2 Instalar Meslo Fonts]]
			- [[#2.3.2 Instalar Powerlevel10k vía OMZ#2.3.2.3 Configure Powerlevel10k|2.3.2.3 Configure Powerlevel10k]]
			- [[#2.3.2 Instalar Powerlevel10k vía OMZ#2.3.2.4 Error iconos no se ven en la terminal|2.3.2.4 Error iconos no se ven en la terminal]]
		- [[#2.3 Themes#2.3.3 Otros themes|2.3.3 Otros themes]]
	- [[#2 Installing OhMyZSH (OMZ)#2.4 Plugins|2.4 Plugins]]
		- [[#2.4 Plugins#2.4.1 Default plugins|2.4.1 Default plugins]]
			- [[#2.4.1 Default plugins#2.4.1.1 History|2.4.1.1 History]]
		- [[#2.4 Plugins#2.4.2 Remove a plugin|2.4.2 Remove a plugin]]
		- [[#2.4 Plugins#2.4.3 Custom plugins|2.4.3 Custom plugins]]
			- [[#2.4.3 Custom plugins#2.4.3.1 [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)|2.4.3.1 [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)]]
			- [[#2.4.3 Custom plugins#2.4.3.2 Syntax Highlighting Plugin|2.4.3.2 Syntax Highlighting Plugin]]
			- [[#2.4.3 Custom plugins#2.4.3.3 Autoupdate (plugins and themes)|2.4.3.3 Autoupdate (plugins and themes)]]
			- [[#2.4.3 Custom plugins#2.4.3.4 Error Windows 10 al clonar repos con CR|2.4.3.4 Error Windows 10 al clonar repos con CR]]
		- [[#2.4 Plugins#2.4.4 Permisos|2.4.4 Permisos]]
- [[#3 Script para actualizar todo|3 Script para actualizar todo]]
- [[#4 Aliases|4 Aliases]]
	- [[#4 Aliases#4.1 Default|4.1 Default]]
	- [[#4 Aliases#4.2 Your custom aliases|4.2 Your custom aliases]]


## 1 Installing ZSH 
``` shell
sudo apt update -y && sudo apt upgrade -y \
&& sudo apt autoremove 

sudo apt -y install zsh

zsh --version
whereis zsh

# Make ZSH our default shell
echo $SHELL # /bin/bash (shell por defecto aún es bash)
chsh -s $(which zsh)

# Primera ejecución ZSH (configuración)
zsh
# pulsa 0 para guardar valores por defecto y salir

# Save the .zshrc configuration file and load it again:
source ~/.zshrc
echo $SHELL # /usr/bin/zsh
# Reinicia laptop si lo anterior no ha funcionado
```

[How to Install and Setup Zsh in Ubuntu 20.04](https://www.tecmint.com/install-zsh-in-ubuntu/)

## 2 Installing OhMyZSH (OMZ)
``` shell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Advanced: If you'd like to change the install directory with the ZSH environment variable, either by running export ZSH=/your/path before installing, or by setting it before the end of the install pipeline like this:
# ZSH="$HOME/.dotfiles/oh-my-zsh" sh install.sh
# ZSH="$HOME/.dotfiles/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Update OMZ core
omz update
```

### 2.1 [Optional] Uninstall OMZ
Just run `uninstall_oh_my_zsh` from the command-line. It will remove itself and revert your previous `bash` or `zsh` configuration.

``` shell
uninstall_oh_my_zsh
```

### 2.2 Referencias
[How to Install and Start Using Oh My Zsh on Ubuntu 20.04 to Boost Your Productivity](https://www.cherryservers.com/blog/how-to-install-and-start-using-oh-my-zsh-on-ubuntu-20-04)

### 2.3 Themes
#### 2.3.1 Default themes
``` shell
# List default themes OMZ
ls ~/.oh-my-zsh/themes

vim ~/.zshrc
ZSH_THEME="agnoster"

source ~/.zshrc
```

#### 2.3.2 Instalar Powerlevel10k vía OMZ
##### 2.3.2.1 Installing theme core
``` shell
# List your custom themes installed already
ls ~/.oh-my-zsh/custom/themes

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

vim ~/.zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"

source ~/.zshrc
```

##### 2.3.2.2 Instalar Meslo Fonts
Descargar MESLO fonts:
-   [MesloLGS NF Regular.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)
-   [MesloLGS NF Bold.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf)
-   [MesloLGS NF Italic.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf)
-   [MesloLGS NF Bold Italic.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf)

Instalarlas en: `Windows 11 -> Settings -> Personalización -> Fuentes` con el botón "Examinar e instalar fuentes".

``` shell
# Refrescar caché de Linux
# fc-cache -fv
```

##### 2.3.2.3 Configure Powerlevel10k
``` shell
# Configurando el theme PowerLevel10k:
p10k configure
# Elegir Rainbow style
```

##### 2.3.2.4 Error iconos no se ven en la terminal
Nos referimos a los iconos FontAwesome, NerdFonts, etc.
Si la terminal que usemos (Windows Terminal, WSL Ubuntu terminal, etc.) muestra caracteres chungos en vez de iconos (flechas, diamante, reloj de arena, home, ubuntu, espiral Debian, etc), probar:
- En la terminal que usemos, seleccionar fuente Meslo. Con esto se suele arreglar.
- [Opcional]: instalar
``` shell
# Probar a instalar
sudo apt-get -y install powerline fonts-powerline
```

https://github.com/romkatv/powerlevel10k#installation

#### 2.3.3 Otros themes
https://travis.media/top-12-oh-my-zsh-themes-for-productive-developers/#20210921-eastwood

### 2.4 Plugins
#### 2.4.1 Default plugins
``` shell
# List default plugins OMZ
ls ~/.oh-my-zsh/plugins

vim ~/.zshrc
plugins=(
	# Default
	git
	colorize
    colored-man-pages
    history
    dirhistory
    jsontools
    vi-mode
    # Custom
    zsh-autosuggestions
    zsh-syntax-highlighting
    autoupdate
)

# Load changes
source ~/.zshrc
```

##### 2.4.1.1 History
``` shell
# Show history path
echo $HISTFILE             
# ~/.zsh_history
```

#### 2.4.2 Remove a plugin
If you want to remove a plugin managed by oh-my-zsh, remove it from the plugins array in your `~/.zshrc` 

#### 2.4.3 Custom plugins
As described in [#7690](https://github.com/ohmyzsh/ohmyzsh/issues/7690) users may have ZSH plugins installed by other tools (e.g. Homebrew) and are not sourced in $ZSH/plugins.  
These should not be referenced inside plugins=(...) within the .zshrc

``` shell
# List custom plugins
ls ~/.oh-my-zsh/custom/plugins
```
##### 2.4.3.1 [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
``` shell
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

vim ~/.zshrc
plugins=( 
    # other plugins...
    zsh-autosuggestions
)

source ~/.zshrc
```

##### 2.4.3.2 Syntax Highlighting Plugin
``` shell
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

vim ~/.zshrc
plugins=( [plugins...] zsh-syntax-highlighting)

source ~/.zshrc
```
https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md

##### 2.4.3.3 Autoupdate (plugins and themes)
``` shell
git clone https://github.com/tamcore/autoupdate-oh-my-zsh-plugins.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/autoupdate

# Comando para actualizar plugins y themes
upgrade_oh_my_zsh_custom

# Actualizar todo OMZ
omz update && upgrade_oh_my_zsh_custom
```
- [How to auto-update custom plugins in Oh My Zsh?](https://unix.stackexchange.com/questions/477258/how-to-auto-update-custom-plugins-in-oh-my-zsh)
- https://github.com/TamCore/autoupdate-oh-my-zsh-plugins

##### 2.4.3.4 Error Windows 10 al clonar repos con CR
``` shell
source ~/.zshrc
/home/ubuntu/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh:source:1: no such file or directory: /home/ubuntu/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh^M
```

Hay que clonar con LF, para ello:
``` shell
git config --global core.autocrlf false
git config --global core.eol lf
```

Se borran los repos descargados anteriormente y que dan error, y se vuelven a clonar.

- [How do I force Git to use LF instead of CR+LF under Windows?](https://stackoverflow.com/questions/2517190/how-do-i-force-git-to-use-lf-instead-of-crlf-under-windows)

#### 2.4.4 Permisos
ls -la ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

-rw-r--r-- 1 ubuntu ubuntu 27775 Nov 13 16:19 zsh-autosuggestions.zsh

## 3 Script para actualizar todo
``` shell
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove \
&& omz update && upgrade_oh_my_zsh_custom
```

## 4 Aliases
### 4.1 Default
``` shell
# List all default aliases
alias

# Localizar alias
which g                                                                                                 
# g: aliased to git
```
- [Oh My ZSh Commands Aliases Cheat Sheet](https://ohmycheatsheet.com/oh-my-zsh-commands-cheat-sheet/)
- [Oh-My-Zsh Git](https://kapeli.com/cheat_sheets/Oh-My-Zsh_Git.docset/Contents/Resources/Documents/index)

### 4.2 Your custom aliases
``` shell
vim ~/.zshrc

# Add aliases using the syntax
# alias [name]='[command]'
alias gflbs='git flow bugfix start'
alias gbm='git branch -m'
alias ups="clear && sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove \
&& omz update && upgrade_oh_my_zsh_custom \
&& sudo service apache2 restart && sudo service mysql restart \
&& sudo service apache2 status && sudo service mysql status"

# source ~/.zshrc
. ~/.zshrc
```


