#!/bin/bash

# This will kill all sessions not attached by someone: 
tmux list-sessions | grep -v attached | awk 'BEGIN{FS=":"}{print $1}' | xargs -n 1 tmux kill-session -t || echo "No sessions to kill"

tiempo=0.5

ip=$(hostname -I)
sesion=${ip//./_}
tmux new-session -d -s $sesion && sleep $tiempo 