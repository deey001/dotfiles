# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# Not on Omarchy: use the copy of Omarchy's defaults that ships with these dotfiles
# (refresh it with `make sync-omarchy` on an Omarchy machine)
[[ -z ${OMARCHY_PATH:-} ]] && OMARCHY_PATH="$HOME/.local/share/omarchy-shell"

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"
[[ $OMARCHY_PATH == "$HOME/.local/share/omarchy-shell" ]] && source "$OMARCHY_PATH/portable"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

[[ -f ~/.bash_local ]] && source ~/.bash_local
