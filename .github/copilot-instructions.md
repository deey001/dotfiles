# Copilot Instructions

## What This Repo Is

Cross-platform dotfiles for macOS, Debian/Ubuntu, RHEL/Fedora, Arch, and Windows (PowerShell/CMD).
Goal: identical terminal experience everywhere — Starship prompt (Catppuccin Mocha), Neovim (LazyVim), tmux, and modern CLI tools.

## Commands

```bash
make install        # install deps + symlink dotfiles via GNU Stow
make uninstall      # remove all managed symlinks
make test           # validate symlinks, commands, syntax
make theme-mocha    # switch to Catppuccin Mocha (dark)
make theme-latte    # switch to Catppuccin Latte (light)
```

Windows (PowerShell, elevated):
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```

## Directory Layout

- `home/` — Single GNU Stow package symlinked into `$HOME`:
  - `home/.bashrc`, `home/.bash_aliases`, `home/.bash_profile`, `home/.blerc`
  - `home/.zshrc`
  - `home/.gitconfig`, `home/.gitattributes`, `home/.gitignore`
  - `home/.common_shell`, `home/.inputrc`, `home/.editorconfig`
  - `home/.config/` → `~/.config/`: nvim, wezterm, starship, tmux (conf + scripts), bat, atuin, fastfetch
- `themes/` — Shell theme definitions sourced into `~/.config/dotfiles/theme.sh`
  - `themes/windows/` — PS1 variants for Windows PSReadLine
- `platform/` — OS-specific files:
  - `platform/windows/` — `settings.json` (Windows Terminal), `Microsoft.PowerShell_profile.ps1`
  - `platform/packages/` — Per-distro package lists: `ubuntu.txt`, `arch.txt`, `rhel.txt`
- `scripts/` — `install.sh`, `install.ps1`, `uninstall.sh`, `test.sh`, `install-blesh.sh`
- `Brewfile` — macOS Homebrew packages

## Key Conventions

- **`set -euo pipefail`** on all shell scripts — strict error handling.
- **`command -v` guards** on all modern tool aliases — always fall back gracefully.
- **Theme system**: `make theme-mocha` symlinks `themes/catppuccin-mocha.sh` → `~/.config/dotfiles/theme.sh`. `.common_shell` sources it on every shell start. Windows uses `themes/windows/catppuccin-mocha.ps1` deployed by `Configure-PowerShell`.
- **Secrets go in `~/.bash_local`** — never committed. See wiki [New Machine](https://github.com/deey001/dotfiles/wiki/New-Machine) for examples.
- **tmux config** lives in `~/.config/tmux/tmux.conf` (stowed from `home/.config/tmux/`).
- **`.stowrc`** sets `--dir=. --target=~ --no-folding` as defaults.
