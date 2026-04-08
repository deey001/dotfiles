# Copilot Instructions

## What This Repo Is

Cross-platform dotfiles for headless servers (macOS, Debian/Ubuntu, RHEL/Fedora, Arch, Windows via PowerShell/CMD). The goal is an identical terminal experience across all environments: Bash/Zsh shell with Starship prompt (Catppuccin Mocha theme), Neovim (LazyVim), Tmux, and modern CLI tool replacements.

## Commands

```bash
make install          # Run scripts/install.sh (installs deps + symlinks dotfiles via GNU Stow)
make uninstall        # Run scripts/uninstall.sh
make test             # Run scripts/test.sh (validates symlinks, commands, syntax, permissions)
make test-verbose     # Same with --verbose flag
```

Windows (PowerShell 7+):
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```

## Architecture

### Directory Layout

- `stow/` — All dotfiles organized as GNU Stow packages. Each subdirectory is a package stowed into `$HOME`.
  - `stow/bash/`   → `.bashrc`, `.bash_aliases`, `.bash_profile`, `.blerc`
  - `stow/zsh/`    → `.zshrc`
  - `stow/git/`    → `.gitconfig`
  - `stow/shell/`  → `.common_shell` (shared env vars/functions), `.inputrc`, `.editorconfig`
  - `stow/tmux/`   → `.tmux.conf`
  - `stow/config/` → All `~/.config/` items (nvim, wezterm, starship, bat, atuin, fastfetch)
- `scripts/` — `install.sh`, `uninstall.sh`, `test.sh`, `install.ps1`, `install-blesh.sh`.
- `windows/` — Windows-specific files: `settings.json` (Windows Terminal), `Microsoft.PowerShell_profile.ps1`.
- `meta/packages/` — Per-distro package lists: `ubuntu.txt`, `arch.txt`, `rhel.txt`.
- `templates/` — `.bash_local.template` for machine-specific overrides (not tracked in git).
- `docs/` — Setup guides.

### Shell Config: The "Unified Shell Brain"

`.bash_profile` → `.bashrc` (sources in order):
1. `.common_shell` — Shared environment variables (EDITOR, PAGER, LANG) and `mkcd` function. Sourced by both Bash and Zsh.
2. `.bash_aliases` — All aliases (modern tool replacements with `command -v` guards; `old*` prefix preserves originals).
3. Tool initializations inline: fzf, zoxide, atuin, direnv, starship, carapace, ble.sh.

`.zshrc` sources `.common_shell` and `.bash_aliases` directly for consistent aliases across shells.

### Windows PowerShell

`windows/Microsoft.PowerShell_profile.ps1` is the tracked PS profile. `Configure-PowerShell` in `install.ps1` dot-sources it from all PS profile locations. It provides:
- PSReadLine with Catppuccin Mocha colors
- Equivalent aliases to `.bash_aliases` (eza for ls/ll/la, nvim shortcuts, git shortcuts)
- Starship prompt init with `STARSHIP_CONFIG` pointing to `~/.config/starship.toml`

### Install Script Behavior

`scripts/install.sh`:
1. Bootstraps itself when piped via `curl | bash` (clones repo if not present)
2. Detects OS and distro (Debian/Ubuntu, Arch, RHEL/Fedora, macOS)
3. Installs system packages via apt/dnf/yum/pacman/brew
4. Installs GNU Stow if missing
5. Stows all packages into `$HOME`

`scripts/install.ps1` interactive menu (Windows):
- Options 1-6: Individual setup steps (font, WT theme, PuTTY, tools, PS profile, CMD prompt)
- Option 7: Full local setup (1-6)
- Option 8: Symlink dotfiles
- Option A: Complete workflow (1-8)

## Key Conventions

- **All shell scripts use `set -euo pipefail`** — strict error handling.
- **Every config file has a header comment block** with description and section separators.
- **Modern tools always have fallback guards** — `command -v` before replacing builtins. Originals via `old*` prefix.
- **Cross-platform conditionals** — detect OS via `uname`, distro via `/etc/*-release`.
- **Environment detection flags** — `.bashrc` exports `IS_SSH`, `IS_WSL`, `IS_DOCKER`, `IS_TMUX`.
- **Secrets go in `.bash_local`** — never committed. Use `templates/.bash_local.template`.
- **Theme: Catppuccin Mocha** everywhere — Starship, Nvim, WezTerm, Windows Terminal, PSReadLine, fzf, bat, tmux.
