# dotfiles
Mis dotfiles para Ubuntu, Zsh, Oh My Zsh, Tmux

Inspired by: 
- https://github.com/thoughtbot/dotfiles
- https://github.com/thoughtbot/rcm
- TMUX: 
  - https://github.com/gpakosz/.tmux
  - Cheatsheet: https://tmuxcheatsheet.com/
- Bash:
  - https://overthewire.org/wargames/bandit/
    - https://www.youtube.com/watch?v=RUorAzaDftg

Instalación:
```shell
cd
sudo mkdir dotfiles-local && cd dotfiles-local && sudo touch gitconfig.local && cd ~
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoremove
sudo apt-get -y install zsh powerline fonts-powerline rcm
zsh --version
whereis zsh

# Install OH-MY-ZSH in Ubuntu 20.04:
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Load dotfiles, theme and plugins
git clone https://github.com/jesuserro/dotfiles.git
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Instala mis dotfiles y crea symlinks
env RCRC=$HOME/dotfiles/rcrc rcup

source ~/.zshrc

# Configuración personal de la terminal - alias, themes, plugins, etc:
sudo nano ~/.zshrc
# plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# Configurando el theme:
p10k configure
```

- [Info detallada](https://www.tecmint.com/install-oh-my-zsh-in-ubuntu/)
- [Plugins Oh my Zsh](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins)
  - [AWS plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aws)
- [Plugins de la comunidad](https://github.com/zsh-users)
- TMUX based on: 
  - https://github.com/gpakosz/.tmux
  - @si4tar: https://www.youtube.com/watch?v=1dDahc214co

# Instalación de Nerdfonts:
Instalar MesloLGS NF Regular.ttf
- https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k
Instalar todas: regular, italic, bold e italic-bold
- https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
```shell
# Refrescar caché de fonts:
fc-cache -fv
# Configurar la shell:
p10k configure
```

# Refresca para ver los cambios en tus dotfiles:
```shell
# Crea symlinks entre estos dotfiles y el sistema en ~
rcup
# También puedes probar:
source ~/.zshrc
# Para quitar paneles de TMUX:
pkill -f tmux
```

Después de la instalación inicial, puedes ejecutarlo sin establecer la variable RCRC (rcup establecerá un enlace simbólico (symlink) del repo rcrc hacia ~/.rcrc para futuras ejecuciones de rcup). Ve el ejemplo.

Este comando creará enlaces simbólicos (symlinks) para los archivos de configuración en tu directorio principal.

Establecer la variable de entorno le dice a rcup que use las opciones de configuración preestablecidas:

  - Excluye los archivos README.md, README-ES.md y LICENSE, que son parte del repositorio dotfiles, pero no necesitan enlazarse simbólicamente.
  - Le da precedencia a las modificaciones personales que por defecto están en ~/dotfiles-local
  - Por favor configura el archivo rcrc en caso de que quieras hacer modificaciones personales en un directorio distinto.

# Actualizar
De vez en cuando deberías descargar las actualizaciones de estos dotfiles, y ejectuar
```shell
rcup
```
para ligar cualquier nuevo archivo e instalar los nuevos plugins de vim. Nota Debes ejecutar rcup después de descargar para asegurarte que todos los archivos de los plugins estén instalados adecuadamente. Puedes ejecutar rcup con seguridad muchas veces para actualizar pronto y muy seguido!

# Haz tus propias modificaciones
Crea un directorio para tus modificaciones personales:

```shell
mkdir ~/dotfiles-local
```
Pon tus modificaciones en ~/dotfiles-local anexado con .local:
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

# TMUX
```shell
# Listar sessiones
tmux list-sessions
# Ocultar sessiones (continuan los procesos ocultos):
tmux detach -s Debug
# Volver a mostrar ventana Debug
tmux attach -t Debug
# Ver los números de los paneles:
Crtl + b + q
# Amplia panel actual (y volver):
Crtl + b + z
# Show all sessions:
Crtl + b + s
```