#!/bin/bash
tiempo=0.25

ip=$(hostname -I)
sesion=${ip//./_}

tmux new-session -d -s $sesion && sleep $tiempo # Crea panel t1
tmux rename-window "Debug"
tmux split-window -v -p 35 && sleep $tiempo # Crea t2
tmux send-keys -t 2 'tail -f /var/log/nginx/error.log' C-m && sleep $tiempo
# ---------------------------------------------------------------------------

tmux new-window -t 2 -n 'BBDD'
tmux send -t $session:BBDD "sudo mysql -u root -p" ENTER

tmux select-window -t 1
tmux select-pane -t 1

tmux send -t $session:Debug "cd /var/www/html" ENTER

# Styles:
# border colours: tmux set -g pane-border-style fg=red
tmux set -g pane-active-border-style "bg=default fg=red"

# Modo ratón:
tmux set -g mouse on

# Guardando session
tmux -2 attach-session -d

# Borrar todo: pkill -f tmux


 