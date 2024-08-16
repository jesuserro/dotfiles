#!/bin/bash

# Mostrar todas las ramas locales con la fecha del último commit
echo -e "\n\e[1;34mRamas locales y su última actividad:\e[0m"
git for-each-ref --sort=-committerdate refs/heads/ --format='%(color:yellow)%(refname:short)%(color:reset) - Última actividad: %(color:green)%(committerdate:format:%A, %d-%m-%Y %H:%M)%(color:reset) - %(color:cyan)Autor: %(authorname)%(color:reset)'
echo -e "\n\e[1;34mTotal de ramas: \e[1;32m$(git branch | wc -l)\e[0m"
