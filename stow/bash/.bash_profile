# ==============================================================================
# .bash_profile — Login Shell Entry Point
# ==============================================================================
# Sourced by: Bash when started as a **login** shell (e.g., SSH sessions,
#             macOS Terminal.app, `su -`, `bash --login`).
#
# NOT sourced by: Non-login interactive shells (e.g., opening a new tmux pane,
#                 running `bash` inside an existing session). Those only read
#                 .bashrc directly.
#
# Purpose: Bridge between login-shell initialization (.profile) and interactive
#          shell configuration (.bashrc). This ensures both login and non-login
#          shells get the same environment.
#
# Load order for a login shell:
#   1. /etc/profile          (system-wide, read by bash automatically)
#   2. ~/.bash_profile        ← YOU ARE HERE
#   3.   └─ ~/.profile        (POSIX-compatible env: PATH, locale, etc.)
#   4.   └─ ~/.bashrc         (interactive config: prompt, aliases, functions)
#   5.       └─ .bash_exports, .bash_aliases, .bash_functions, .bash_wrappers,
#              .bash_local, .blerc
#
# Why source .bashrc here? Bash only reads .bash_profile OR .bashrc for login
# shells, not both. Without this delegation, login shells (SSH, macOS default)
# would lack aliases, functions, and prompt configuration.
# ==============================================================================

# Source .profile for login shell environment (PATH, etc.)
if [ -f ~/.profile ]; then
    . ~/.profile
fi

# Trigger ~/.bashrc commands for interactive login shells
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
