#!/bin/bash

# Mostrar todas las ramas locales con la fecha del último commit
echo "Ramas locales y su última actividad:"
git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) - Última actividad: %(committerdate:format:%A, %d-%m-%Y %H:%M)'
