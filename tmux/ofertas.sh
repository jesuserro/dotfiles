#!/bin/bash

# This will kill all sessions not attached by someone: 
tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' | xargs -n 1 tmux kill-session -t || echo No sessions to kill

tiempo=0.5

ip=$(hostname -I)
sesion=${ip//./_}
tmux new-session -d -s $sesion && sleep $tiempo 

# Local
tmux rename-window "Local"
tmux send -t $session:Local "cd /var/www/ofertas.cdrst.local" ENTER
tmux split-window -v -p 35 && sleep $tiempo
tmux send-keys 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo

# DEV 
tmux new-window -t 2 -n '89.17.208.189'
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss subv@89.17.208.189' C-m && sleep $tiempo
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss subv@89.17.208.189 && tail -f /var/log/httpd/dev-ofertas_error_log' C-m && sleep $tiempo






# Selección final
tmux select-window -t 1
tmux select-pane -t 1

# Styles
# Border colours 
tmux set -g pane-border-style "fg=default"
tmux set -g pane-active-border-style "bg=default fg=yellow"

# Modo ratón
tmux set -g mouse on
tmux set -g mouse-select-pane on
tmux set -g mouse-resize-pane on
tmux set -g mouse-select-window on

# Guardando session
tmux -2 attach-session -d

# Borrar todo: pkill -f tmux


 