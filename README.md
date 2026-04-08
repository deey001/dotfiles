# Danny's Dotfiles

Cross-platform dev environment for **macOS**, **Linux** (Debian/Ubuntu, Arch, RHEL), and **Windows**.  
Unified [Catppuccin Mocha](https://catppuccin.com) theme, Starship prompt, Neovim/LazyVim, and zero manual steps after install.

---

## Quick Install

| Platform | One-liner |
|---|---|
| **macOS / Linux** | `curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh \| bash` |
| **Windows** (PowerShell, elevated) | `irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" \| iex` |

> **Windows:** Interactive menu appears — press **A** for the full workflow.  
> **WSL:** Run the Linux one-liner inside WSL, then run the Windows installer in an elevated PowerShell for Terminal + font.

---

## What Gets Installed

| Category | Tools |
|---|---|
| **Shell** | Bash (+ ble.sh), Zsh, Starship prompt |
| **Editor** | Neovim + LazyVim |
| **Terminal** | WezTerm, Windows Terminal (Catppuccin Mocha theme) |
| **CLI** | bat, ripgrep, fd, fzf, eza, atuin, zoxide, tmux, delta |
| **Font** | JetBrainsMono Nerd Font |

---

## Repo Structure

```
dotfiles/
├── home/               # GNU Stow packages — each folder symlinks into $HOME
│   ├── bash/           #   .bashrc, .bash_aliases, .bash_profile, .blerc
│   ├── zsh/            #   .zshrc
│   ├── git/            #   .gitconfig, .gitattributes, .gitignore
│   ├── shell/          #   .common_shell, .inputrc, .editorconfig
│   └── config/         #   ~/.config/: nvim, wezterm, starship, tmux, atuin, bat…
├── themes/             # Theme definitions sourced by ~/.config/dotfiles/theme.sh
│   └── windows/        #   PS1 variants for Windows
├── platform/           # OS-specific files
│   ├── windows/        #   PowerShell profile, Windows Terminal settings.json
│   └── packages/       #   Package lists: ubuntu.txt, arch.txt, rhel.txt
├── scripts/            # install.sh, install.ps1, uninstall.sh, install-blesh.sh
│   └── .bash_local.template  # Machine-local overrides (copy to ~/.bash_local)
├── Brewfile            # macOS Homebrew packages
├── Makefile            # make install / uninstall / theme-mocha / theme-latte
└── README.md
```

---

## Local Workflow

```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install          # stow all packages
make theme-mocha      # apply Catppuccin Mocha (default)
make theme-latte      # switch to Catppuccin Latte (light)
make uninstall        # remove all symlinks
```

---

## Switching Themes

```bash
make theme-mocha   # dark
make theme-latte   # light
```

Theme files live in `themes/` and `themes/windows/`. All consumers (shell, bat, fzf, WezTerm, PSReadLine) source the active theme via `~/.config/dotfiles/theme.sh` (Linux/macOS) or `~/.config/dotfiles/theme.ps1` (Windows).

---

## Machine-Local Overrides

Copy the template and edit to taste — it is never committed:

```bash
cp ~/dotfiles/scripts/.bash_local.template ~/.bash_local
```

Use `~/.bash_local` for secrets, host-specific `$PATH` entries, or anything you don't want in the repo.

---

## ble.sh (Bash Line Editor)

ble.sh is not installed by default (it requires a build step). Install or update it manually:

```bash
bash ~/dotfiles/scripts/install-blesh.sh
```

---

## Documentation

Full documentation lives in the [GitHub Wiki](https://github.com/deey001/dotfiles/wiki):

- [Architecture & How GNU Stow Works](https://github.com/deey001/dotfiles/wiki/Architecture)
- [Tool Reference](https://github.com/deey001/dotfiles/wiki/Tool-Reference)
- [Theme System](https://github.com/deey001/dotfiles/wiki/Theming)
- [Windows Setup Details](https://github.com/deey001/dotfiles/wiki/Windows)
- [Adding a New Machine](https://github.com/deey001/dotfiles/wiki/New-Machine)
- [Troubleshooting](https://github.com/deey001/dotfiles/wiki/Troubleshooting)
