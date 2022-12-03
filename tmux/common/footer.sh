#!/bin/bash

# Selección final
tmux select-window -t 1
tmux select-pane -t 1

# Guardando session
tmux -2 attach-session -d

# Borrar todo: pkill -f tmux


 