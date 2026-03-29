# Session Memory — March 2026

Persistent context for the dotfiles repo (github.com/deey001/dotfiles).
User: Danny. Machines: macOS dev (dannyvillazon), ARM64 Ubuntu server (danny@containers / danny@10.10.1.250).

---

## Current Architecture

Dotfiles use **GNU Stow** for symlink management. All configs live under `stow/`:

```
stow/
  bash/       → ~/.bashrc, ~/.bash_aliases, ~/.bash_exports, ~/.bash_functions,
                  ~/.bash_wrappers, ~/.bash_profile, ~/.blerc, ~/.inputrc
  zsh/        → ~/.zshrc
  git/        → ~/.gitconfig
  shell/      → ~/.inputrc (shared)
  tmux/       → ~/.tmux.conf, ~/.config/tmux/scripts/
  nvim/       → ~/.config/nvim/
  starship/   → ~/.config/starship.toml
  bat/        → ~/.config/bat/themes/
  atuin/      → ~/.config/atuin/config.toml
  fastfetch/  → ~/.config/fastfetch/config.jsonc
  alacritty/  → ~/.config/alacritty/  (macOS only)
```

Key files: `.stowrc` (--dir=stow --target=~ --no-folding), `scripts/install.sh` (handles stow + legacy symlink removal).

---

## Install / Update

```bash
# Fresh install
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash

# Update existing install
git pull && bash scripts/install.sh

# Apply config changes only (no full reinstall)
git pull && source ~/.blerc   # for bash/ble.sh changes
```

No Makefile — removed as unnecessary complexity.

---

## ble.sh — REMOVED

ble.sh was removed from bash config due to an incompatibility with bash 5.2
on ARM64 Linux. bash 5.2 added strict `read` validation that rejected empty
variable names. ble.sh's completion engine triggered this on every keystroke.

Standard bash + readline (`.inputrc`) is used instead. TAB completion, history
search (atuin Ctrl+R), and starship prompt all work without ble.sh.

To re-enable ble.sh later (e.g., on a system where it works):
```bash
bash scripts/install-blesh.sh
# Then add to .bashrc: source ~/.local/share/blesh/ble.sh --noattach
# And at end of .bashrc: ble-attach
```

---

---

## Theme: Catppuccin Mocha

Applied everywhere: Starship, Neovim (LazyVim), Tmux, bat, git-delta, fzf, Alacritty.
Starship uses `palette = "catppuccin_mocha"` in `stow/starship/.config/starship.toml`.

---

## Key Shell Features

| Feature | Tool | Notes |
|---------|------|-------|
| Prompt | Starship | Pure-inspired 2-line, Catppuccin Mocha |
| Syntax highlight | — | Removed (ble.sh had bash 5.2 incompatibility) |
| Autosuggestions | — | Removed with ble.sh |
| History search | atuin | Ctrl+R fuzzy search |
| Completions | carapace | Multi-shell, loaded in both bash/zsh |
| Navigation | zoxide | `z dir` to jump, `zi` for fuzzy |
| System info | fastfetch | Runs once per session (_FASTFETCH_RAN guard) |

---

## Known Working State

- **macOS**: stow working, starship colors/icons OK, zsh fully functional
- **Linux (ARM64)**: stow working, bash+ble.sh functional, ble.sh read error being fixed
- **fastfetch double-run**: fixed with `_FASTFETCH_RAN` export guard
- **Starship palette**: full Catppuccin Mocha defined in starship.toml

---

## Files Reference

| Script | Purpose |
|--------|---------|
| `scripts/install.sh` | Full install: packages + stow |
| `scripts/uninstall.sh` | Full cleanup |
| `scripts/test.sh` | Validate symlinks/commands |
| `scripts/install-blesh.sh` | Build+install ble.sh from git master |

---

## Tmux Prefix: Ctrl+a

Key bindings: `v`/`s` splits, `h/j/k/l` navigation, `Prefix+o` session switcher (sessionx), `Prefix+p` floating terminal (floax), `Prefix+I` install plugins.
