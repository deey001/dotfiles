# Dotfiles

A small, [Omarchy](https://omarchy.org)-style shell and editor setup, built mainly for headless Linux servers reached over SSH. It also works on Omarchy desktops, Arch, Debian/Ubuntu, RHEL/Fedora/Oracle Linux, macOS, and Windows.

On Omarchy, these files sit on top of Omarchy's own defaults and change only what's personal. Everywhere else, a portable copy of those defaults is loaded instead, so every machine behaves the same way.

## Install

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```

**Windows** (elevated PowerShell)
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```

On Windows this installs the tools with winget (Git, PowerShell 7, Windows Terminal, PuTTY, Neovim, starship, fzf, zoxide, eza, bat, fd, ripgrep, delta, lazygit, jq, zig, and JetBrainsMono Nerd Font) plus the PSFzf module. It then links the configs, sets up Windows Terminal through a settings fragment (so your own `settings.json` is never edited), and sets PuTTY's default session settings. Undo it with `.\scripts\uninstall.ps1`.

On Linux and macOS, the install script installs packages, then links `home/` into `$HOME` with GNU Stow. Before linking, it moves any existing file it would replace to `~/.dotfiles-backup/<timestamp>/`. You can run it again safely at any time.

```bash
make install        # install packages + link
make uninstall      # remove links, restore the files install backed up
make test           # syntax check + stow dry run
make sync-omarchy   # refresh the bundled Omarchy shell defaults (on Omarchy)
```

## Layout

The shell setup follows Omarchy's own layout exactly. `~/.bashrc` is Omarchy's stock `.bashrc`: it sources `$OMARCHY_PATH/default/bash/rc`, and your own additions go below that line.

- **On Omarchy,** `OMARCHY_PATH` is `/usr/share/omarchy`, so the rc comes from Omarchy itself.
- **Everywhere else,** `OMARCHY_PATH` points to `~/.local/share/omarchy-shell`. That folder holds an unmodified copy of Omarchy's `default/bash` (aliases, functions, inputrc, and so on), plus a small `portable` file that swaps out Omarchy-only pieces such as `omarchy-launch-editor`.

To refresh the copy after an Omarchy update, run `make sync-omarchy` on an Omarchy machine and commit the result.

```
home/                               stowed into $HOME
  .bashrc                           Omarchy's stock .bashrc + fallback path
  .bash_profile
  .local/share/omarchy-shell/       copy of Omarchy's default/bash + portable fix-ups
  .local/bin/clip                   copy to the local clipboard via OSC 52
  .gitconfig                        identity comes from ~/.gitconfig.local
  .config/nvim/                     LazyVim + a few overrides
  .config/tmux/                     Omarchy keys + Catppuccin status bar, no plugins
  .config/starship.toml             Omarchy-style prompt
  .config/wezterm/                  terminal for macOS / non-Omarchy Linux
  .config/git/ignore                global gitignore
platform/packages/                  per-distro package lists
platform/windows/profile.ps1        PowerShell profile: Omarchy's aliases, keys and tools
platform/windows/terminal.json      Windows Terminal fragment (font + colors)
platform/windows/putty.ps1          PuTTY default session: font, colours, logging
platform/windows/links.ps1          where each file is linked on Windows
platform/packages/winget.txt        Windows packages
scripts/                            install / uninstall (+ FIPS path, see docs/FIPS.md)
Brewfile                            macOS packages
```

On macOS the config is bash-only, like Omarchy. The Brewfile installs a current bash; switch to it with `chsh -s /opt/homebrew/bin/bash` (add that path to `/etc/shells` first).

## Clipboard over SSH

Copying works the same way everywhere, whether you're at the machine, SSH'd into a server, or inside tmux on that server. It uses OSC 52, a terminal escape sequence that asks *your local terminal* to put text on *your local clipboard*. The server needs no X11, Wayland, or xclip.

| Where | Copy | Paste |
|---|---|---|
| Terminal | select with the mouse (hold Shift inside tmux) | terminal paste key (Ctrl+Shift+V / Cmd+V) |
| Shell | `clip "text"`, `cmd \| clip`, `clip < file` | terminal paste key |
| tmux | `prefix [`, select with `v`, copy with `y`/Enter, or drag with the mouse | terminal paste key, or `prefix ]` |
| Neovim | `y` (goes to the `+` register) | terminal paste key, or `p` for the last yank |

This relies on the *local* terminal supporting OSC 52 writes:

- **Work out of the box:** Ghostty, Kitty, Alacritty, WezTerm, foot, and Windows Terminal.
- **iTerm2:** turn on *Applications in terminal may access clipboard* first.
- **No OSC 52 support:** macOS Terminal.app and PuTTY.

**PuTTY** is still installed and configured for its session logging. The install script applies the following to *Default Settings and every saved session*:

- the same font and colours as the other terminals
- UTF-8 and `xterm-256color`
- logging to `~\logs\putty\<host>-<date>-<time>.log`, but only for sessions where logging was off, so an existing log setup is left alone

The original sessions are exported to `~\.dotfiles-backup` before the first change, and `uninstall.ps1` re-imports them. Because PuTTY ignores OSC 52, copy there with PuTTY's own selection: select with the mouse (hold **Shift** inside tmux or nvim, which otherwise take the mouse) and right-click to paste. `y` in tmux or nvim won't reach the Windows clipboard from PuTTY.

Pasting always goes through the terminal's own paste key, because terminals don't let remote programs read your clipboard.

## Theming

The terminal is the only place a theme is set. bat (`BAT_THEME=ansi`), fzf, tmux, and starship all use ANSI colors, so they follow the terminal's palette automatically.

- **Omarchy:** `omarchy-theme-set` themes everything, including Neovim through Omarchy's `plugins/theme.lua`.
- **Elsewhere:** WezTerm and Neovim use Catppuccin Mocha.

## tmux status bar

The status bar shows the session name (it turns red while the prefix is held), then the current directory, the date and time, the LAN IP, and the ISP with the WAN IP. `~/.config/tmux/scripts/wan_info.sh` looks up the WAN IP and ISP from ifconfig.co at most once every 5 minutes and caches the result. The icons need a Nerd Font in the terminal you connect *from*.

## Machine-local overrides

These files are never committed:

| File | Use |
|---|---|
| `~/.bash_local` / `~\.pwsh_local.ps1` | tokens, extra `PATH` entries (Go, npm, etc.) |
| `~/.gitconfig.local` | `user.name`, `user.email`, credential helper, signing key |
| `~/.config/tmux/local.conf` | tmux overrides |

```bash
git config -f ~/.gitconfig.local user.name  "Your Name"
git config -f ~/.gitconfig.local user.email "you@example.com"
```
