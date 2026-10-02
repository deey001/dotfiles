# Dotfiles

A small, [Omarchy](https://omarchy.org)-style shell and editor setup, built mainly for **headless Linux servers reached over SSH**. It also works on Omarchy desktops, macOS, and Windows.

- **One shell setup everywhere.** On Omarchy these files sit on top of Omarchy's own defaults. Everywhere else, a copy of those same defaults ships with the repo, so every machine has the same aliases, keys, and prompt.
- **Copy/paste that works over SSH.** Copy from the shell, tmux, or Neovim on a remote server, and it lands on your local clipboard.
- **Nothing extra.** No plugin managers, no theme switcher, no login banners. It's about 1,500 lines, not counting the bundled copy of Omarchy's shell files.

| Platform | Supported |
|---|---|
| Linux | Omarchy / Arch, Debian / Ubuntu, RHEL / Fedora / Oracle Linux |
| macOS | via Homebrew (bash, not zsh) |
| Windows | PowerShell 7 + Windows Terminal, and PuTTY for session logging |

---

## Install

**Recommended:** clone, then run the installer from the checkout. You control the revision, and nothing is piped into a shell from the network.

**Linux / macOS**
```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
cd ~/dotfiles
# optional: git checkout <tag-or-sha>   # pin before install
bash scripts/install.sh
```

**Windows** (from an elevated PowerShell, or with Developer Mode on)
```powershell
git clone https://github.com/deey001/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
# optional: git checkout <tag-or-sha>
.\scripts\install.ps1
```

Both installers install packages and link the configs into your home folder. Any existing file they would replace is moved to `~/.dotfiles-backup/<timestamp>/` first. Both are safe to run again at any time, for example after a `git pull`.

### One-liner (optional, pinned)

Piping a remote script into `bash` / `iex` is a supply-chain risk: the URL can change under you, and `master` moves. If you still want a one-liner, **pin a commit SHA**, review the script first, then exec.

Example pin (current `HEAD` as of this doc: `8879ae5` / `8879ae54aa55021cf909a9fbe9b834d93cdc5fab`):

**Linux / macOS**
```bash
# Review first:
#   curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/8879ae54aa55021cf909a9fbe9b834d93cdc5fab/scripts/install.sh
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/8879ae54aa55021cf909a9fbe9b834d93cdc5fab/scripts/install.sh | bash
```

**Windows**
```powershell
# Review first:
#   irm "https://raw.githubusercontent.com/deey001/dotfiles/8879ae54aa55021cf909a9fbe9b834d93cdc5fab/scripts/install.ps1"
irm "https://raw.githubusercontent.com/deey001/dotfiles/8879ae54aa55021cf909a9fbe9b834d93cdc5fab/scripts/install.ps1" | iex
```

Prefer a release **tag** when one exists (`…/refs/tags/vX.Y.Z/…` or `git checkout vX.Y.Z` after clone). Re-check the SHA/tag before each install; do not leave `master` in the URL.

Secrets (tokens, keys, work email) belong in untracked locals — see [Machine-local settings](#machine-local-settings). Never put them in tracked files.

### What gets installed

| | Linux / macOS | Windows (winget) |
|---|---|---|
| Shell & prompt | bash, bash-completion, starship | PowerShell 7, starship, PSFzf |
| Editor | Neovim (upstream build if the distro's is older than 0.11.2) | Neovim, zig (C compiler for treesitter) |
| CLI tools | tmux, fzf, zoxide, eza, bat, fd, ripgrep, delta, lazygit, btop, jq | fzf, zoxide, eza, bat, fd, ripgrep, delta, lazygit, jq |
| Terminal | (whatever you connect from) | Windows Terminal, PuTTY, JetBrainsMono Nerd Font |

The package lists live in `platform/packages/` (`arch.txt`, `ubuntu.txt`, `rhel.txt`, `winget.txt`) and in `Brewfile`. Packages are installed one at a time, so a name that's missing on an older release is skipped instead of stopping the install.

### Everyday commands

```bash
cd ~/dotfiles
git pull && scripts/install.sh      # update
scripts/uninstall.sh                # remove links and restore the original files
scripts/install.sh --test           # syntax check + stow dry run, changes nothing
scripts/install.sh --sync-omarchy   # refresh the bundled Omarchy shell defaults (run on Omarchy)
```

On Windows, run `.\scripts\install.ps1` to update and `.\scripts\uninstall.ps1` to undo.

---

## How the shell is set up

`~/.bashrc` is Omarchy's stock `.bashrc`. It sources `$OMARCHY_PATH/default/bash/rc`, and your own additions go below that line.

- **On Omarchy,** `OMARCHY_PATH` is `/usr/share/omarchy`, so everything comes from Omarchy itself and follows its updates.
- **Everywhere else,** `OMARCHY_PATH` points to `~/.local/share/omarchy-shell`. That folder holds an unmodified copy of Omarchy's `default/bash`, plus a small `portable` file that fixes the few Omarchy-only pieces:
  - `EDITOR` becomes `nvim`.
  - macOS keeps its own `open`.
  - Homebrew bash-completion and Debian's fzf key bindings are loaded.
  - `TERM` falls back to `xterm-256color` when the server doesn't know your terminal (Ghostty, Kitty, foot).

After an Omarchy update, run `scripts/install.sh --sync-omarchy` on an Omarchy machine and commit the result.

On Windows, `platform/windows/profile.ps1` gives PowerShell the same aliases and keys.

### Aliases and functions (from Omarchy)

| Command | Does |
|---|---|
| `ls`, `lsa`, `lt`, `lta` | eza long list, with hidden files, tree, tree with hidden |
| `cd <dir>` | normal `cd`, or jumps with zoxide when `<dir>` isn't a path |
| `ff`, `eff` | fuzzy-find a file with preview; open the result in `$EDITOR` |
| `n [file]` | Neovim (opens the current folder with no argument) |
| `g`, `gcm`, `gcam`, `gcad` | `git`, commit -m, commit -a -m, commit -a --amend |
| `ga <branch>`, `gd` | create / remove a git worktree for a branch (`gd` needs `gum`) |
| `t` | attach to tmux, or start a session called `Work` |
| `d` | `docker` |
| `compress`, `decompress` | tar.gz a folder / extract one |
| `fip`, `dip`, `lip` | start / stop / list SSH port forwards |
| `..`, `...`, `....` | go up 1, 2, or 3 folders |
| `clip` | copy to your local clipboard (see below) |

**Keys:** Tab and Shift+Tab cycle completions. Up/Down search history for what you've typed. Ctrl+R searches history with fzf, and Ctrl+T finds files with fzf.

---

## Copy / paste over SSH

Copying works the same way at the machine, over SSH, and inside tmux on a server. It uses **OSC 52**, a terminal escape sequence that asks *your local terminal* to put text on *your local clipboard*. The server needs no X11, Wayland, or xclip.

| Where | Copy | Paste |
|---|---|---|
| Shell | `clip "text"`, `cmd \| clip`, `clip < file` | terminal paste key (Ctrl+Shift+V / Cmd+V) |
| tmux | `prefix [`, then `v` to select and `y`/Enter to copy, or drag with the mouse | terminal paste key, or `prefix ]` |
| Neovim | `y` (over SSH, yanks go to your local clipboard) | terminal paste key, or `p` for the last yank |
| Terminal selection | hold **Shift** while selecting inside tmux or Neovim | terminal paste key |

Your *local* terminal must allow OSC 52:

- **Works out of the box:** Ghostty, Kitty, Alacritty, WezTerm, foot, Windows Terminal.
- **iTerm2:** turn on *Applications in terminal may access clipboard*.
- **Not supported:** macOS Terminal.app and PuTTY.

In PuTTY, use its own selection instead: Shift + mouse to select, then right-click to paste.

Paste always goes through your terminal's paste key, because terminals don't let remote programs read your clipboard.

---

## tmux

tmux uses Omarchy's key bindings and a Catppuccin status bar with Nerd Font icons. No plugins are needed.

- **Prefix:** `Ctrl+Space`, with `Ctrl+A` also working.
- **Panes:**
  - Split with `prefix -` / `prefix \`, or `Alt+Enter` / `Alt+Shift+Enter`.
  - Move with `prefix h/j/k/l` or `Ctrl+Alt+arrows`, and resize with `Ctrl+Alt+Shift+arrows`.
  - `prefix x` closes a pane, and `prefix S` types into all panes at once.
- **Windows:**
  - Switch with `Alt+1…9` or `Alt+Left/Right`, and reorder with `Alt+Shift+Left/Right`.
  - `prefix c` creates a window and `prefix r` renames it.
- **Sessions:** `prefix C` creates one, `prefix R` renames it, and `Alt+Up/Down` switches between them.
- **Other:** `prefix q` reloads the config, and `prefix ?` lists every binding.
- **Status bar:** shows the session (red while the prefix is held), the current folder, the date and time, the LAN IP, and the ISP with the WAN IP.
  - `~/.config/tmux/scripts/wan_info.sh` gets the WAN details from ifconfig.co, at most once every 5 minutes.
  - The icons need a Nerd Font in the terminal you connect *from*.

For per-machine changes, create `~/.config/tmux/local.conf`.

---

## Neovim

Neovim runs [LazyVim](https://www.lazyvim.org) with a few changes:

- 4-space indents, mouse off, a column marker at 80
- `:w!!` saves with sudo
- OSC 52 clipboard over SSH
- color highlighting and Markdown rendering

On Omarchy, the colorscheme follows the Omarchy theme. Everywhere else it's Catppuccin Mocha.

---

## Theming

Colors come from the terminal where possible.

- **Terminal palette:** bat (`BAT_THEME=ansi`), fzf, and starship use the terminal's colors, so they follow Omarchy's theme or your terminal's color scheme.
- **Fixed Catppuccin Mocha:** the tmux status bar, WezTerm, Windows Terminal, and PuTTY. The installers set this up for the Windows terminals.

---

## Windows details

- **Windows Terminal** gets a *fragment* file, installed alongside its settings, that sets the font and colors on the PowerShell profiles. Your own `settings.json` is never edited. If Terminal still opens Windows PowerShell 5, choose PowerShell 7 as the default profile once in Terminal's settings.
- **PuTTY** is kept for its session logging. The installer applies the following to *Default Settings and every saved session*:
  - the Nerd Font, Catppuccin colors, UTF-8, and `xterm-256color`
  - logging to `~\logs\putty\<host>-<date>-<time>.log`, but only for sessions where logging was off, so an existing log setup is left alone

  Your sessions are exported to `~\.dotfiles-backup` before the first change, and `uninstall.ps1` re-imports them.
- **Where files are linked** is listed in `platform/windows/links.ps1`. For example, Neovim's config goes to `%LOCALAPPDATA%\nvim`, and the profile goes to both PowerShell 7 and Windows PowerShell 5.
- **For servers**, clone (or use a SHA-pinned one-liner) on each server — see [Install](#install).

---

## Machine-local settings

These files are never committed (listed in `.gitignore`, along with `.env*`, key material, and credential stores). Put secrets and machine-only tweaks here — not in tracked configs. Create them as needed:

| File | Use |
|---|---|
| `~/.bash_local` | exports, aliases, tokens, extra `PATH` entries (Go, npm, etc.) |
| `~\.pwsh_local.ps1` | the same for PowerShell |
| `~/.gitconfig.local` | credential helper, signing key, a different `user.email` for work |
| `~/.config/tmux/local.conf` | tmux overrides |

Git's name and email are set in `home/.gitconfig`. A `user.email` in `~/.gitconfig.local` overrides it on that machine.

---

## Repo layout

```
home/                                 linked into $HOME (GNU Stow on Linux/macOS)
  .bashrc, .bash_profile              Omarchy's stock files + fallback path
  .local/share/omarchy-shell/         copy of Omarchy's default/bash + portable fix-ups
  .local/bin/clip                     copy to the local clipboard (OSC 52)
  .gitconfig, .gitattributes          git settings
  .config/git/ignore                  global gitignore
  .config/nvim/                       LazyVim + overrides
  .config/tmux/                       tmux.conf + wan_info.sh for the status bar
  .config/starship.toml               prompt
  .config/wezterm/                    WezTerm (macOS / Linux desktops)
platform/
  packages/                           arch.txt, ubuntu.txt, rhel.txt, winget.txt
  windows/                            profile.ps1, terminal.json, putty.ps1, links.ps1
scripts/                              install / uninstall for each platform
Brewfile                              macOS packages
```
