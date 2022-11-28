#!/bin/bash

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


 