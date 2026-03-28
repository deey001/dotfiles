# Source .profile for login shell environment (PATH, etc.)
if [ -f ~/.profile ]; then
    . ~/.profile
fi

# Trigger ~/.bashrc commands for interactive login shells
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
