# 🐾 Danny's Dotfiles

> Cross-platform dev environment for **macOS**, **Linux**, and **Windows** — unified [Catppuccin Mocha](https://catppuccin.com) theme, Starship prompt, Neovim/LazyVim, zero manual steps.

---

## 🚀 Quick Install

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```

**Windows** *(PowerShell, elevated)*
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```

> **Windows:** Interactive menu appears — press **A** for the full workflow.  
> **WSL:** Run the Linux one-liner inside WSL, then run the Windows installer in an elevated PowerShell for Terminal + font.

---

## 📦 What Gets Installed

| Category | Tools |
|---|---|
| **Shell** | Bash (+ ble.sh), Zsh, Starship prompt |
| **Editor** | Neovim + LazyVim |
| **Terminal** | WezTerm, Windows Terminal (Catppuccin Mocha) |
| **CLI** | bat, ripgrep, fd, fzf, eza, zoxide, tmux, delta |
| **Font** | JetBrainsMono Nerd Font |

---

## 🗂️ Repo Structure

```
dotfiles/
├── home/               # GNU Stow packages — each folder symlinks into $HOME
│   ├── bash/           #   .bashrc, .bash_aliases, .bash_profile, .blerc
│   ├── zsh/            #   .zshrc
│   ├── git/            #   .gitconfig, .gitattributes, .gitignore
│   ├── shell/          #   .common_shell, .inputrc, .editorconfig
│   └── config/         #   ~/.config/: nvim, wezterm, starship, tmux, bat…
├── themes/             # Theme definitions sourced by ~/.config/dotfiles/theme.sh
│   └── windows/        #   PS1 variants for Windows Terminal
├── platform/           # OS-specific files
│   ├── windows/        #   PowerShell profile, Windows Terminal settings.json
│   └── packages/       #   ubuntu.txt, arch.txt, rhel.txt
├── scripts/            # install.sh, install.ps1, uninstall.sh, install-blesh.sh
│   └── install-blesh.sh      # ble.sh installer (manual step, see wiki)
├── Brewfile            # macOS Homebrew packages
├── Makefile            # make install / uninstall / theme-mocha / theme-latte
└── README.md
```

---

## 🔧 Local Workflow

```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install          # stow all packages + link default theme
make theme-mocha      # Catppuccin Mocha (dark, default)
make theme-latte      # Catppuccin Latte (light)
make uninstall        # remove all symlinks
make test             # validate installation
```

---

## 🎨 Switching Themes

```bash
make theme-mocha   # dark
make theme-latte   # light
```

Theme files live in `themes/`. All consumers (shell, bat, fzf, WezTerm, PSReadLine) source the active theme via `~/.config/dotfiles/theme.sh` (Linux/macOS) or `~/.config/dotfiles/theme.ps1` (Windows).

---

## ⚙️ Machine-Local Overrides

Create `~/.bash_local` for secrets, tokens, host-specific `$PATH`, GOPATH, rbenv, etc. — it is never committed to git:

```bash
# Example ~/.bash_local
export GITHUB_TOKEN="..."
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"
```

See [New Machine](https://github.com/deey001/dotfiles/wiki/New-Machine) in the wiki for a full list of examples.

---

## 🐚 ble.sh (Bash Line Editor)

ble.sh provides fish-style autosuggestions and syntax highlighting for Bash. Install manually after the main setup:

```bash
bash ~/dotfiles/scripts/install-blesh.sh
```

---

## 📖 Documentation

Full docs in the [GitHub Wiki](https://github.com/deey001/dotfiles/wiki):

- [Architecture & How GNU Stow Works](https://github.com/deey001/dotfiles/wiki/Architecture)
- [Tool Reference](https://github.com/deey001/dotfiles/wiki/Tool-Reference)
- [Theme System](https://github.com/deey001/dotfiles/wiki/Theming)
- [Windows Setup Details](https://github.com/deey001/dotfiles/wiki/Windows)
- [Adding a New Machine](https://github.com/deey001/dotfiles/wiki/New-Machine)
- [Troubleshooting](https://github.com/deey001/dotfiles/wiki/Troubleshooting)
