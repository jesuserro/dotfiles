#!/bin/bash

source ~/dotfiles/tmux/common/header.sh


# Total screen
tmux rename-window "One"

# Split screen
tmux new-window -t 2 -n 'Two'
tmux split-window -v -p 35 && sleep $tiempo # Crea t2

# BBDD
# tmux new-window -t 3 -n 'BBDD'
# tmux send -t $session:BBDD "sudo -S ssh -o 'IdentitiesOnly yes' -i ~/.ssh/aws-jesuserro-key.pem -L 3333:localhost:3306 ubuntu@libricos.com" C-m && sleep $tiempo
# tmux send -t $session:BBDD "sudo mysql -u root -p" ENTER

# Local NGES
# tmux new-window -t 4 -n 'NGES'
# tmux send -t $session:NGES "cd /var/www/nges.local && apachestart" ENTER
# tmux split-window -v -p 35 && sleep $tiempo # Crea t3
# tmux send-keys -t 4 'tail -f /var/log/apache2/error.log' C-m && sleep $tiempo

# Ofertas
# tmux new-window -t 5 -n 'Ofertas'
# tmux send -t $session:Ofertas "cd /var/www/ofertas.cdrst.local" ENTER
# tmux split-window -v -p 35 && sleep $tiempo 
# tmux send-keys -t 5 'ssh -oHostKeyAlgorithms=+ssh-dss jesus@89.17.208.189' C-m && sleep $tiempo


source ~/dotfiles/tmux/common/footer.sh


 