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


source ~/dotfiles/tmux/common/footer.sh


 