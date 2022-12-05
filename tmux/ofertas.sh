#!/bin/bash

source ~/dotfiles/tmux/common/header.sh


# Local
tmux rename-window "Local"
tmux send -t $session:Local "cd /var/www/ofertas.cdrst.local" ENTER
tmux split-window -v -p 35 && sleep $tiempo
tmux send-keys 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo

# DEV 
tmux new-window -t 2 -n '89.17.208.189'
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.189' C-m && sleep $tiempo
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.189 && tail -f /var/log/httpd/dev-ofertas_error_log' C-m && sleep $tiempo


source ~/dotfiles/tmux/common/footer.sh


 