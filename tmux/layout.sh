#!/bin/sh 
tmux new-session -s foo -d
tmux rename-window 'Ventana'

tmux split-window -v -p 45
tmux send 'tail -f /var/log/nginx/error.log' C-m;


#tmux select-pane -t 0
#tmux select-window -t foo:0

tmux -2 attach-session -d 
# tmux selectw -t 0
# tmux set-window-option -g window-status-current-bg red
# tmux setw -g window-status-current-style fg=black,bg=white

# Borrar todo: pkill -f tmux 