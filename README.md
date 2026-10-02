# Dotfiles

A small [Omarchy](https://omarchy.org)-style shell and editor setup. Built for headless Linux over SSH. Same files also run on an Omarchy desktop, macOS, and Windows.

On Omarchy the shell comes from Omarchy itself. Everywhere else this repo ships a copy of those defaults, so aliases, keys, and the prompt match. Copy from the shell, tmux, or Neovim on a server and it lands on the local clipboard. No plugin manager, no theme switcher, no login banner.

| Platform | Supported |
|---|---|
| Linux | Omarchy / Arch, Debian / Ubuntu, RHEL / Fedora / Oracle Linux |
| macOS | Homebrew (bash, not zsh) |
| Windows | PowerShell 7, Windows Terminal, PuTTY for session logging |

## Layout

Same idea as Omarchy: `config/` is what lands in `~/.config`, `default/` is the shell, `bin/` is commands, `install/` is the installer and is not linked.

```
repo                                  installed at
────────────────────────────────────  ──────────────────────────────────────────────
bin/clip                              ~/.local/bin/clip

config/**                             ~/.config/**
  nvim/  tmux/  wezterm/
  starship.toml  git/ignore

default/bashrc                        ~/.bashrc
default/bash_profile                  ~/.bash_profile
default/bash/**                       ~/.local/share/omarchy-shell/default/bash/**
default/portable                      ~/.local/share/omarchy-shell/portable
default/gitconfig                     ~/.gitconfig
default/gitattributes                 ~/.gitattributes

install/                              not linked
  install.sh  uninstall.sh
  install.ps1  uninstall.ps1
  packages/                           arch.txt  ubuntu.txt  rhel.txt  winget.txt
  windows/                            profile.ps1  links.ps1  putty.ps1  terminal.json

Brewfile                              macOS packages, not linked
```

Every file is a symlink. `install/` is not linked.

## Install

Clone, then run the installer from the checkout.

**Linux / macOS**

```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install/install.sh
```

**Windows** (elevated PowerShell, or Developer Mode on)

```powershell
git clone https://github.com/deey001/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install\install.ps1
```

Both install packages, then link. A file they would replace is moved to `~/.dotfiles-backup/<timestamp>/` first. Safe to run again after `git pull`.

```bash
bash install/install.sh                 # install or update
bash install/uninstall.sh               # remove links, restore the first backup
bash install/install.sh --test          # syntax check, changes nothing
bash install/install.sh --sync-omarchy  # refresh default/bash (run on Omarchy)
```

On Windows, `.\install\install.ps1` updates and `.\install\uninstall.ps1` undoes the links.

Package lists are `install/packages/` and `Brewfile`. Each package is installed on its own, so a missing name is skipped.

Do not pipe `master` into a shell. If you still want a one-liner, pin a commit, read the script, then run it.

Secrets stay in untracked locals. See [Machine-local settings](#machine-local-settings).

### What gets installed

| | Linux / macOS | Windows (winget) |
|---|---|---|
| Shell & prompt | bash, bash-completion, starship | PowerShell 7, starship, PSFzf |
| Editor | Neovim (upstream build if the distro's is older than 0.11.2) | Neovim, zig (C compiler for treesitter) |
| CLI tools | tmux, fzf, zoxide, eza, bat, fd, ripgrep, delta, lazygit, btop, jq | fzf, zoxide, eza, bat, fd, ripgrep, delta, lazygit, jq |
| Terminal | whatever you connect from | Windows Terminal, PuTTY, JetBrainsMono Nerd Font |

## Shell

`~/.bashrc` is Omarchy's stock bashrc. It sources `$OMARCHY_PATH/default/bash/rc`. Your own additions go below that line, or in `~/.bash_local`.

- **On Omarchy,** `OMARCHY_PATH` is `/usr/share/omarchy`.
- **Everywhere else,** `OMARCHY_PATH` is `~/.local/share/omarchy-shell`. That directory holds the copy of Omarchy's `default/bash`, plus `portable`:
  - `EDITOR` is `nvim`.
  - macOS keeps its own `open`.
  - Homebrew bash-completion and Debian's fzf key bindings are loaded.
  - `TERM` falls back to `xterm-256color` when the server does not know the terminal (Ghostty, Kitty, foot).

After an Omarchy update, run `bash install/install.sh --sync-omarchy` on an Omarchy machine and commit `default/bash`. Do not edit that tree by hand.

On Windows, `install/windows/profile.ps1` gives PowerShell the same aliases and keys.

### Aliases and functions (from Omarchy)

| Command | Does |
|---|---|
| `ls`, `lsa`, `lt`, `lta` | eza long list, with hidden files, tree, tree with hidden |
| `cd <dir>` | normal `cd`, or zoxide when `<dir>` is not a path |
| `ff`, `eff` | fuzzy-find a file with preview; open the result in `$EDITOR` |
| `n [file]` | Neovim (current folder when no argument) |
| `g`, `gcm`, `gcam`, `gcad` | `git`, commit -m, commit -a -m, commit -a --amend |
| `ga <branch>`, `gd` | create / remove a git worktree (`gd` needs `gum`) |
| `t` | attach to tmux, or start a session called `Work` |
| `d` | `docker` |
| `compress`, `decompress` | tar.gz a folder / extract one |
| `fip`, `dip`, `lip` | start / stop / list SSH port forwards |
| `..`, `...`, `....` | go up 1, 2, or 3 folders |
| `clip` | copy to the local clipboard |

**Keys:** Tab and Shift+Tab cycle completions. Up/Down search history for what you typed. Ctrl+R searches history with fzf. Ctrl+T finds files with fzf.

## Copy / paste over SSH

Copy uses **OSC 52**. The server asks your local terminal to write your local clipboard. No X11, Wayland, or xclip on the server.

| Where | Copy | Paste |
|---|---|---|
| Shell | `clip "text"`, `cmd \| clip`, `clip < file` | terminal paste key (Ctrl+Shift+V / Cmd+V) |
| tmux | `prefix [`, then `v` to select and `y`/Enter to copy, or drag with the mouse | terminal paste key, or `prefix ]` |
| Neovim | `y` (over SSH, yanks go to your local clipboard) | terminal paste key, or `p` for the last yank |
| Terminal selection | hold **Shift** while selecting inside tmux or Neovim | terminal paste key |

Your local terminal must allow OSC 52:

- **Works:** Ghostty, Kitty, Alacritty, WezTerm, foot, Windows Terminal.
- **iTerm2:** turn on *Applications in terminal may access clipboard*.
- **Not supported:** macOS Terminal.app and PuTTY. In PuTTY, Shift + mouse to select, right-click to paste.

Paste always uses the terminal paste key. Terminals do not let a remote program read the clipboard.

## tmux

Omarchy's key bindings, plus a Catppuccin status bar with Nerd Font icons. No plugins.

- **Prefix:** `Ctrl+Space`. `Ctrl+A` also works.
- **Panes:** split with `prefix -` / `prefix \`, or `Alt+Enter` / `Alt+Shift+Enter`. Move with `prefix h/j/k/l` or `Ctrl+Alt+arrows`. Resize with `Ctrl+Alt+Shift+arrows`. `prefix x` closes a pane. `prefix S` types into all panes.
- **Windows:** `Alt+1…9` or `Alt+Left/Right` switch. `Alt+Shift+Left/Right` reorders. `prefix c` creates a window. `prefix r` renames it.
- **Sessions:** `prefix C` creates one, `prefix R` renames it, `Alt+Up/Down` switches.
- **Other:** `prefix q` reloads the config. `prefix ?` lists every binding.
- **Status bar:** session (red while the prefix is held), current folder, date and time, LAN IP, ISP and WAN IP. `~/.config/tmux/scripts/wan_info.sh` asks ifconfig.co, at most once every 5 minutes. Icons need a Nerd Font in the terminal you connect from.

Per-machine changes go in `~/.config/tmux/local.conf`.

## Neovim

[LazyVim](https://www.lazyvim.org), with a few changes:

- 4-space indents, mouse off, column marker at 80
- `:w!!` saves with sudo
- OSC 52 clipboard over SSH
- color highlighting and Markdown rendering

On Omarchy the colorscheme follows the Omarchy theme. Everywhere else it is Catppuccin Mocha.

## Theming

bat (`BAT_THEME=ansi`), fzf, and starship use the terminal palette, so they follow Omarchy or your terminal. The tmux status bar, WezTerm, Windows Terminal, and PuTTY are fixed Catppuccin Mocha. The Windows installer sets that up.

## Windows

- **Windows Terminal** gets a fragment next to its settings. The fragment sets the font and colors on the PowerShell profiles. Your `settings.json` is not edited. If Terminal still opens Windows PowerShell 5, pick PowerShell 7 as the default profile once.
- **PuTTY** stays for session logging. The installer sets the Nerd Font, Catppuccin colors, UTF-8, and `xterm-256color` on Default Settings and every saved session. Logging goes to `~\logs\putty\<host>-<date>-<time>.log`, and only where logging was off. Sessions are exported to `~\.dotfiles-backup` before the first change. `uninstall.ps1` re-imports them.
- **Link list:** `install/windows/links.ps1`. Neovim goes to `%LOCALAPPDATA%\nvim`. The profile goes to PowerShell 7 and Windows PowerShell 5.

## Machine-local settings

Never commit these. `.gitignore` also ignores `.env*`, key material, and credential stores.

| File | Use |
|---|---|
| `~/.bash_local` | exports, aliases, tokens, extra `PATH` entries |
| `~\.pwsh_local.ps1` | the same for PowerShell |
| `~/.gitconfig.local` | credential helper, signing key, a work `user.email` |
| `~/.config/tmux/local.conf` | tmux overrides |

Git's name and email are set in `default/gitconfig`. A `user.email` in `~/.gitconfig.local` overrides it on that machine.
