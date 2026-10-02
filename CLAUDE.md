# CLAUDE.md

Context for Claude Code sessions working on this repo. See README.md for user-facing docs.

## What this repo is

Personal dotfiles for deey001, used mainly on **headless Linux servers reached over SSH**, and also on an Omarchy desktop, macOS, and Windows. The September 2026 rewrite slimmed it from about 9.4k lines to about 1.5k (not counting the bundled Omarchy copy), following Omarchy's layout.

## Decisions already made (don't re-litigate)

- **Shell = Omarchy's config, verbatim.** `default/bashrc` is Omarchy's stock `.bashrc` plus a fallback that points `OMARCHY_PATH` at `~/.local/share/omarchy-shell`. `default/bash/` is an **unmodified** copy of `/usr/share/omarchy/default/bash`. Never edit it by hand. Put portability fixes in `default/portable`, and refresh the copy with `install/install.sh --sync-omarchy` on an Omarchy machine.
- **No personal aliases file.** The user chose Omarchy's aliases. Their own additions go under the "Add your own" line in `.bashrc` or in `~/.bash_local`.
- **bash only.** zsh, ble.sh, carapace, fastfetch, the theme switcher, TPM, and the tmux plugins were all removed on purpose.
- **Layout matches Omarchy.** `config/` lands in `~/.config`, `bin/` in `~/.local/bin`, `default/` is the shell (`default/bash` is the unmodified copy). `install/` is the installer and is not linked. Links are plain symlinks. **No Stow** (Oracle Linux 10 does not ship it). **No Makefile.** **No wiki.** The README is the only documentation.
- **tmux:** Omarchy's key bindings, with the user's **Catppuccin status bar and Nerd Font icons kept**: session pill, path, date, LAN IP, and ISP:WAN IP through `config/tmux/scripts/wan_info.sh`. It uses fixed hex colours on purpose. Prefix is `C-Space`, with `C-a` as a second prefix.
- **Clipboard:** OSC 52 everywhere. tmux `set-clipboard on`, Neovim uses OSC 52 over SSH (`lua/config/options.lua`), and `bin/clip` copies from the shell.
- **Windows:** `install/install.ps1` has no menu. It installs `install/packages/winget.txt`, links the files listed in `install/windows/links.ps1`, configures Windows Terminal through a *fragment* (`terminal.json`, never edits `settings.json`), and runs `install/windows/putty.ps1`.
- **PuTTY is required** because the user relies on its session logging. `putty.ps1` applies the font, Catppuccin colours, UTF-8, and xterm-256color to Default Settings **and every saved session**. It turns logging on only where it's off, and backs up the sessions `.reg` first.
- **Git identity** (`deey001` / `dvillazon@gmail.com`) lives in `default/gitconfig`, with the user's permission. `~/.gitconfig.local` is included afterwards for per-machine overrides.
- **Install/uninstall parity:** both platforms install packages, then back up to `~/.dotfiles-backup/<timestamp>/`, then link. Uninstall removes only the links and restores the first backup.
- **One install tree.** `install/install.sh` is the only Linux/macOS path.

## Testing without touching the real $HOME

- Linux: `HOME=/tmp/somewhere bash install/install.sh --test` runs a syntax check and does not link. To test the link step alone, copy the section from `echo "--- Linking` to the end of `install/install.sh` and run it with a fake `HOME`.
- Non-Omarchy shell path on an Omarchy box: hide Omarchy with `unshare -rm bash -c 'mount -t tmpfs none /usr/share/omarchy && env -i HOME=... bash -ic ...'`.
- PowerShell: parse the scripts with `[System.Management.Automation.Language.Parser]::ParseFile`. A portable Linux `pwsh` tarball works for this, and for load-testing `install/windows/profile.ps1`.

## Open items / not yet verified

- **Windows has never been run on a real machine:** winget installs, symlinks, the PuTTY registry changes, and Windows PowerShell 5. Treat the first run as a test.
- Windows Terminal fragment `updates` for font/colorScheme on the built-in PowerShell profiles is believed to work, but hasn't been confirmed.
- Omarchy's `completions` file uses `complete -I` (bash 5+), which errors on bash 4.4 (RHEL 8).
- If PuTTY had no sessions key before the first install, there's nothing to restore on uninstall.
- A real SSH round-trip test of OSC 52 (server tmux/nvim to desktop clipboard) hasn't been done.

## Conventions

- Keep things minimal. The goal of this repo is less code, not more features.
- Commits: Conventional Commits style (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`), authored as `deey001 <dvillazon@gmail.com>`. The default branch is `master`. Confirm with the user before pushing.
