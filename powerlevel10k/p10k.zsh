# --- Personalización visual para Powerlevel10k ---

# Cambiar color del directorio (dir) a naranja pastel
typeset -g POWERLEVEL9K_DIR_BACKGROUND=173

# Cambiar color del os_icon a magenta
typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=5

# --- Mostrar el entorno virtual Python (venv) en la barra derecha ---

# Solo añadir 'virtualenv' si no está ya presente
if [[ ! " ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[@]} " =~ " virtualenv " ]]; then
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS+=('virtualenv')
fi
