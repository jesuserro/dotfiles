#!/bin/bash

# Obtén la lista de ramas remotas y guárdala en un array
remote_branches=$(git branch -r | sed 's/origin\///' | tr -d ' ')

# Recorre todas las ramas locales
for local_branch in $(git branch --format='%(refname:short)'); do
    if [[ "$local_branch" == "main" || "$local_branch" == "master" || "$local_branch" == "dev" ]]; then
        # Saltar la rama principal o ramas importantes
        continue
    fi

    # Verifica si la rama local existe en el remoto
    if [[ ! $remote_branches =~ $local_branch ]]; then
        echo "Borrando rama local $local_branch que ya no existe en el remoto..."
        git branch -d $local_branch
    fi
done
