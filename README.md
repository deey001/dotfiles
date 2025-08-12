# Dotfiles

## Files
- .bash_aliases: Custom aliases for common commands.
- .bash_exports: Exported environment variables.
- .bash_profile: Login shell config.
- .bash_wrappers: Custom function wrappers.
- .bashrc: Main Bash config with prompt, history, aliases, and completion.
- .tmux.conf: Tmux config with keybinds, mouse, vi mode, and Dracula plugin.
- .vimrc: Basic Vim configuration.
- install.sh: Installs dependencies, fonts, vim, Starship, and symlinks files.
- uninstall.sh: Removes symlinks.
- starship.toml: Starship prompt configuration.

## Installation
1. Clone: git clone https://github.com/deey001/dotfiles.git ~/dotfiles
2. cd ~/dotfiles && ./install.sh
3. tmux: prefix + I for plugins

## Uninstallation
./uninstall.sh

Requirements handled by install.sh.