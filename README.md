# Dotfiles

## Files
- .bash_aliases: Custom aliases for common commands like `ll`, `la`, `grep` with color, `gti` for git, `vi` for vim, etc.
- .bash_exports: Exported environment variables (currently empty).
- .bash_profile: Login shell config that sources .bashrc.
- .bash_wrappers: Custom function wrappers (currently empty).
- .bashrc: Main Bash config with history settings, color prompts, aliases, bash completion, fzf fuzzy search, starship prompt, git branch in PS1, bash-preexec for hooks, hstr for history search, zoxide for smart cd, exa and bat aliases.
- .tmux.conf: Tmux config with prefix C-a, mouse mode, custom theme, status bar showing IP and time, keybinds for splitting, resizing panes, and navigation.
- .vimrc: Extensive Vim configuration with syntax highlighting, line numbers, indentation (4 spaces), plugins like NERDTree, Airline, CtrlP, and custom mappings.
- .config/alacritty/alacritty.yml: Alacritty terminal config with Nerd Font, base16 colors, opacity, and key bindings for ricing.
- .config/nvim/init.vim: Neovim config based on .vimrc with modern plugins (Packer, Treesitter, Telescope, LSP, CMP) for enhanced editing.
- install.sh: Installs dependencies (tmux, git, fzf, vim, neovim, starship, Nerd Font, hstr, bat, exa, zoxide, fastfetch, bash-preexec, base16-shell, alacritty), clones repos, and symlinks dotfiles.
- uninstall.sh: Removes symlinks and optional cleanup of installed tools.
- starship.toml: Starship prompt configuration with custom format showing username, hostname, directory, git status with emojis, battery, and time.

## Installation
1. Clone: git clone https://github.com/deey001/dotfiles.git ~/dotfiles
2. cd ~/dotfiles && ./install.sh
3. tmux: prefix + I for plugins

## Uninstallation
./uninstall.sh

Requirements handled by install.sh.