# Dotfiles

Personal dotfiles for Bash and tmux configurations.

## Files
- `.bash_aliases`: Custom Bash aliases.
- `.bash_exports`: Exported environment variables.
- `.bash_profile`: Bash login shell config.
- `.bash_wrappers`: Custom Bash functions/wrappers.
- `.bashrc`: Main Bash config.
- `.tmux.conf`: Enhanced tmux config with plugins and modern features.
- `install.sh`: Script to install dependencies and symlink files.
- `uninstall.sh`: Script to remove symlinks and clean up.

## Installation
1. Clone: `git clone https://github.com/deey001/dotfiles.git ~/dotfiles`
2. Run: `cd ~/dotfiles && ./install.sh`
3. For tmux plugins: Start tmux, press Ctrl-a + I.

## Uninstallation
1. Run: `cd ~/dotfiles && ./uninstall.sh`
2. Restart shell.

## Requirements
- tmux, git, fzf, clipboard tools (handled by install.sh).

Customize as needed!
