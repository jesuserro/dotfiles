#!/bin/bash

# This will kill all sessions not attached by someone: 
tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' | xargs -n 1 tmux kill-session -t || echo No sessions to kill

tiempo=0.5

ip=$(hostname -I)
sesion=${ip//./_}

tmux new-session -d -s $sesion && sleep $tiempo # Crea panel t1
tmux rename-window "Debug"
tmux split-window -v -p 35 && sleep $tiempo # Crea t2
tmux send-keys -t 2 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo
# ---------------------------------------------------------------------------

tmux new-window -t 2 -n 'BBDD'
tmux send -t $session:BBDD "sudo -S ssh -o 'IdentitiesOnly yes' -i ~/.ssh/aws-jesuserro-key.pem -L 3333:localhost:3306 ubuntu@libricos.com" C-m && sleep $tiempo
# tmux send -t $session:BBDD "sudo mysql -u root -p" ENTER

tmux select-window -t 1
tmux select-pane -t 1

tmux send -t $session:Debug "cd /var/www/nges.local && ss" ENTER

# Styles:
# border colours: tmux set -g pane-border-style fg=red
tmux set -g pane-active-border-style "bg=default fg=red"

# Modo ratón
tmux set -g mouse on
tmux set -g mouse-select-pane on
tmux set -g mouse-resize-pane on
tmux set -g mouse-select-window on

# Guardando session
tmux -2 attach-session -d

# Borrar todo: pkill -f tmux


 