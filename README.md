# dotfiles
Mis dotfiles para Ubuntu, Zsh, Oh My Zsh, Tmux

Inspired in: 
- https://github.com/thoughtbot/dotfiles
- https://github.com/thoughtbot/rcm

Instala el gestor oficial de Ubuntu para dotfiles:
```shell
sudo apt install rcm
```

Instala los dotfiles:
```shell
env RCRC=$HOME/dotfiles/rcrc rcup
```

Refresca para ver los cambios:
```shell
source ~/.zshrc
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