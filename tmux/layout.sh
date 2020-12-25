#!/bin/sh 
tiempo=0.25
# https://gist.github.com/dbeckham/655da225f1243b2db5da
#sesion="ifconfig|xargs|awk '{print $7}'|sed -e 's/[a-z]*:/''/'"
# sesion="(ip addr show dev eth0 | grep "inet[^6]" | awk '{print $2}')"
#sesion=ifconfig wlan0 | grep "inet " | awk -F'[: ]+' '{ print $4 }'
#ip=$("hostname -I")
ip=$(hostname -I | cut -f1,2,3 -d".")
#hostname -I | awk '{ print $1 }'
sesion="Localhost" 
#sesion=${ip//./_}

tmux new-session -d -s $sesion && sleep $tiempo # Crea panel t1
tmux rename-window "Debug $ip"
#tmux rename-session -t $sesion "Localhost 123\.234566"
#tmux rename-session -t $sesion "Localhost \033k...\033\\"
#tmux rename-window "$(echo $* | cut -d . -f 1)"
#tmux rename-window "$(echo $* | rev | cut -d ' ' -f1 | rev | cut -d . -f 1)"

tmux split-window -v -p 35 && sleep $tiempo # Crea t2
tmux send-keys -t 2 'tail -f /var/log/nginx/error.log' C-m && sleep $tiempo


tmux new-window -t $sesion:2 -n 'BBDD'

tmux select-window -t 1
tmux select-pane -t 1
#tmux send-keys -t 1 $ip C-m && sleep $tiempo
tmux send -t $session:BBDD ls ENTER

# Styles:
# border colours: tmux set -g pane-border-style fg=red
tmux set -g pane-active-border-style "bg=default fg=red"

# Modo ratón:
tmux set -g mouse on

# Guardando session
tmux -2 attach-session -d

# Borrar todo: pkill -f tmux


 