#!/bin/bash

# This will kill all sessions not attached by someone: 
tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' | xargs -n 1 tmux kill-session -t || echo No sessions to kill

tiempo=0.5

ip=$(hostname -I)
sesion=${ip//./_}
tmux new-session -d -s $sesion && sleep $tiempo # Crea panel t1

# Total screen
tmux rename-window "One"

# Split screen
tmux new-window -t 2 -n 'Two'
tmux split-window -v -p 35 && sleep $tiempo # Crea t2

# BBDD
tmux new-window -t 3 -n 'BBDD'
tmux send -t $session:BBDD "sudo -S ssh -o 'IdentitiesOnly yes' -i ~/.ssh/aws-jesuserro-key.pem -L 3333:localhost:3306 ubuntu@libricos.com" C-m && sleep $tiempo
# tmux send -t $session:BBDD "sudo mysql -u root -p" ENTER

# Local NGES
tmux new-window -t 4 -n 'NGES'
tmux send -t $session:NGES "cd /var/www/nges.local && ss" ENTER
tmux split-window -v -p 35 && sleep $tiempo # Crea t3
tmux send-keys -t 4 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo

# Ofertas
tmux new-window -t 5 -n 'Ofertas'
tmux send -t $session:Ofertas "cd /var/www/ofertas.cdrst.local" ENTER
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 5 'ssh -oHostKeyAlgorithms=+ssh-dss subv@89.17.208.189' C-m && sleep $tiempo





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


 