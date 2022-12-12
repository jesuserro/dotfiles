#!/bin/bash

source ~/dotfiles/tmux/common/header.sh


# Local
tmux rename-window "Local"
tmux send -t $session:Local "cd /var/www/ofertas.cdrst.local" ENTER
tmux split-window -v -p 35 && sleep $tiempo
tmux send-keys 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo

# DEV 
tmux new-window -t 2 -n '89.17.208.189 DEV'
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.189' C-m && sleep $tiempo
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 2 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.189 && tail -f /var/log/httpd/dev-ofertas_error_log' C-m && sleep $tiempo

# PROD
tmux new-window -t 3 -n '89.17.208.138 PRE'
tmux send-keys -t 3 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.138' C-m && sleep $tiempo
tmux send-keys -t 3 'cd /home/pre-ofertas.centraldereservas.com/html' C-m && sleep $tiempo
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 3 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.138 && tail -f /var/log/httpd/dev-ofertas_error_log' C-m && sleep $tiempo

# PROD
tmux new-window -t 4 -n '89.17.208.138 PROD'
tmux send-keys -t 4 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.138' C-m && sleep $tiempo
tmux send-keys -t 4 'cd /home/ofertas.centraldereservas.com/html' C-m && sleep $tiempo
tmux split-window -v -p 35 && sleep $tiempo 
tmux send-keys -t 4 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.138 && tail -f /var/log/httpd/dev-ofertas_error_log' C-m && sleep $tiempo



source ~/dotfiles/tmux/common/footer.sh


 