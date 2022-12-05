#!/bin/bash

source ~/dotfiles/tmux/common/header.sh


# Local
tmux rename-window "Local"
tmux send -t $session:Local "cd /var/www/localidades.cdrst.local" ENTER
tmux split-window -v -p 35 && sleep $tiempo
tmux send-keys 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo

# PROD 
tmux new-window -t 2 -n 'ms.cdrst.com'
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@ms.cdrst.com && cd /home/localidades.cdrst.com/html/' C-m && sleep $tiempo
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@ms.cdrst.com' C-m && sleep $tiempo
tmux send-keys -t 2 'tail -f /var/log/httpd/localidades_error_log' C-m && sleep $tiempo


source ~/dotfiles/tmux/common/footer.sh


 