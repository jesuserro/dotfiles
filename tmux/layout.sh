#!/bin/sh 
tmux new-session -d -s main # Crea panel t1
tmux rename-window $USER

tmux split-window -v -p 35 # Crea t2
tmux send-keys -t 2 'tail -f /var/log/nginx/error.log' C-m

tmux select-pane -t 1
tmux split-window -h -p 50 # Crea t3 (cambia numeración de paneles ya creados)
tmux send-keys -t 2 'sudo mysql -u root -p' C-m


# Styles:
# border colours: tmux set -g pane-border-style fg=red
tmux set -g pane-active-border-style "bg=default fg=red"

# Modo ratón:
tmux set -g mouse on

# Guardando session
tmux -2 attach-session -d

# Borrar todo: pkill -f tmux


 