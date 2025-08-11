# Dotfiles

## Files
- .bash_aliases: Custom aliases for common commands.
- .bash_exports: Exported environment variables (e.g., PATH additions).
- .bash_profile: Login shell config, sourced on login (e.g., for PATH setup).
- .bash_wrappers: Custom function wrappers for commands.
- .bashrc: Main Bash config with prompt, history, aliases, and completion.
- .tmux.conf: Tmux config with keybinds, mouse, vi mode, and Dracula plugin.
- install.sh: Installs dependencies, fonts, and symlinks files.
- uninstall.sh: Removes symlinks.

## Installation
1. Clone: git clone https://github.com/deey001/dotfiles.git ~/dotfiles
2. cd ~/dotfiles && ./install.sh
3. tmux: prefix + I for plugins

## Uninstallation
./uninstall.sh

Requirements handled by install.sh.
