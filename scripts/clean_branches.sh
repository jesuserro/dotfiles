#!/bin/bash

# Este script limpia las ramas locales que ya no existen en el remoto 
# y cuyo último commit es de hace más de 1 año. Excluye las ramas "main", "master", y "dev".

# Obtén la lista de ramas remotas y guárdala en un array
remote_branches=$(git branch -r | sed 's/origin\///' | tr -d ' ')

# Fecha de referencia: hace 1 año desde la fecha actual
one_year_ago=$(date -d "1 year ago" +%s)

# Recorre todas las ramas locales
for local_branch in $(git branch --format='%(refname:short)'); do
    if [[ "$local_branch" == "main" || "$local_branch" == "master" || "$local_branch" == "dev" ]]; then
        # Saltar la rama principal o ramas importantes
        continue
    fi

    # Obtén la fecha del último commit en la rama actual
    last_commit_date=$(git log -1 --format=%ct "$local_branch")
    
    # Verifica si la rama local existe en el remoto y si el último commit es de hace más de 1 año
    if [[ ! $remote_branches =~ $local_branch && $last_commit_date -lt $one_year_ago ]]; then
        echo "Borrando rama local '$local_branch' que ya no existe en el remoto y tiene un commit más antiguo que 1 año..."
        git branch -d $local_branch
    fi
done
