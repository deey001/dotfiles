# Session Memory — April 2026 Overhaul + Copilot Session

Persistent context for the dotfiles repo (github.com/deey001/dotfiles).
User: Danny.

---

## 🏗️ Architecture (Post-Overhaul, April 2026)

### Stow Meta-Packages
Individual tool packages were consolidated into logical groups:
```
stow/
  bash/       → ~/.bashrc, ~/.bash_aliases, ~/.blerc, ~/.bash_profile
  zsh/        → ~/.zshrc
  git/        → ~/.gitconfig
  shell/      → ~/.common_shell (env vars + mkcd only), ~/.inputrc, ~/.editorconfig
  tmux/       → ~/.tmux.conf
  config/     → All ~/.config/ items (nvim, wezterm, starship, bat, atuin, fastfetch)
```

### Windows-Specific Files
```
windows/
  Microsoft.PowerShell_profile.ps1  ← NEW (added Apr 2026 Copilot session)
  settings.json                     ← Windows Terminal (Catppuccin Mocha + PS7 + CMD profiles)
```

### The "Unified Shell Brain"
- **`.common_shell`**: ONLY env vars (EDITOR, VISUAL, PAGER, LANG, LC_ALL) and `mkcd` function.
  - Was previously bloated with duplicate aliases — cleaned up in Copilot session.
- **`.bash_aliases`**: ALL aliases (eza, bat, git shortcuts, nav, editors, etc.)
  - Sourced by both `.bashrc` AND `.zshrc`.
- **Source chain**: `.bash_profile` → `.bashrc` → `.common_shell` → `.bash_aliases` → tools

---

## 📦 Automated Installation

### macOS / Linux (One-Liner)
```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```
- Uses distro-specific package lists in `meta/packages/*.txt`
- Supports: Debian/Ubuntu (apt), Arch (pacman), RHEL/Fedora (dnf/yum), macOS (brew)
- Auto-clones repo if run via pipe
- Installs GNU Stow, then stows: bash, zsh, git, shell, tmux, config

### Windows (PowerShell 7+)
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```
Interactive menu (options 1–A). Complete workflow = option A.

---

## 🎨 Key Features & Theming

| Feature | Tool | Notes |
|:--- |:--- |:--- |
| **Theme** | Catppuccin Mocha | Nvim, Tmux, WezTerm, Windows Terminal, Starship, bat, fzf, PSReadLine, delta, ble.sh |
| **Prompt** | Starship | Smart SSH-only hostname/username, OS icon, git status, lang icons, right-aligned timer |
| **Terminal** | WezTerm | Primary. GPU-accelerated, Lua config, Ctrl+Shift+L scrollback dump |
| **Editor** | LazyVim (Neovim) | Config at ~/.config/nvim/ |
| **Tmux** | TPM plugins | catppuccin, sessionx (Prefix+o), floax (Prefix+p), resurrect, continuum, thumbs, fzf-url |
| **Bash extras** | ble.sh | Fish-style autosuggestions + syntax highlighting for Bash |
| **History** | atuin | SQLite history, fuzzy Ctrl+R, sync capable |
| **cd** | zoxide | Learns frequent dirs, `z partial` jumps there |
| **ls** | eza | Colors, icons, git status. Aliases: ls/ll/la/l/tree |
| **cat** | bat | Syntax highlighting, Catppuccin theme, git integration |
| **grep** | ripgrep (rg) | Fast, .gitignore-aware |
| **find** | fd | Simple syntax, fast, .gitignore-aware |
| **diff** | delta | Syntax-highlighted git diffs, Catppuccin theme |
| **completions** | carapace | 600+ tools, bridges fish/bash/zsh completions |

---

## ✅ Bugs Fixed — Copilot Session (April 8, 2026)

### Critical (were silently breaking Windows)
1. **`SymbolLink` → `SymbolicLink` typo** in `install.ps1` — ALL Windows symlinking was silently failing
2. **`STARSHIP_CONFIG` env var not set** — Starship fell back to defaults (no Catppuccin) on Windows
3. **`Configure-WindowsTerminal` only patched font** — color scheme from `windows/settings.json` was never applied
4. **No PowerShell profile in repo** — PS experience was completely bare (no aliases, no colors)
5. **Hard-coded `/home/danny` path** in `.bashrc` line 353 — broke all other installs

### Structural
6. **Removed duplicate eza/ls aliases** from `.common_shell` (were already in `.bash_aliases`)
7. **Fixed dead `~/.bash_functions` reference** in `.zshrc` (file was merged into `.bashrc` during overhaul)
8. **Fixed duplicate section numbers 12/13** in `.bashrc` (renumbered to 14–22)
9. **Added RHEL/Fedora install branch** to `install.sh` (meta/packages/rhel.txt existed but was never read)
10. **Fixed `mkdir -p` in `wezterm.lua`** — was Unix-only, now cross-platform conditional
11. **Updated `copilot-instructions.md`** — was referencing old `dots/` layout and non-existent make targets

### New Files / Features
- **`windows/Microsoft.PowerShell_profile.ps1`** — Full PS profile: PSReadLine Catppuccin colors, eza/nvim/git aliases, zoxide, Starship
- **`Configure-CMD` function** in `install.ps1` (option 6) — CMD prompt via Clink + Starship
- **PowerShell 7 (pwsh.exe) + CMD profiles** added to `windows/settings.json`
- **`Get-DotfilesDir` helper** in `install.ps1` — centralizes dotfiles dir resolution for all functions

---

## 🛠️ Maintenance Reference

| Script | Purpose |
|:--- |:--- |
| `scripts/install.sh` | Linux/macOS bootstrapper — package install + GNU Stow symlinks |
| `scripts/install.ps1` | Windows setup tool — fonts, WT theme, PS/CMD profile, tools, symlinks |
| `scripts/test.sh` | Validation suite — symlinks, commands, syntax, permissions |
| `scripts/uninstall.sh` | Remove all managed symlinks |
| `Makefile` | Shortcuts: `make`, `make test`, `make test-verbose`, `make uninstall` |

---

## 🔑 Key Conventions

- `set -euo pipefail` in all shell scripts — strict error handling
- `command -v` guards on all alias blocks — never assume a tool is installed
- `old*` prefix aliases preserve originals (`oldcat`, `oldtop`, `oldfind`)
- `IS_SSH`, `IS_WSL`, `IS_DOCKER`, `IS_TMUX`, `IS_ONLINE` flags exported by `.bashrc`
- Machine-specific config: `~/.bash_local` (from `templates/.bash_local.template`, never committed)
- Zsh-specific local: `~/.zsh_local`

---

## ⚠️ Known Gotchas

- **Starship on Windows**: requires `STARSHIP_CONFIG` env var pointing to `~/.config/starship.toml`. Set by `Configure-PowerShell` in `install.ps1`. If Starship uses defaults, re-run option 5.
- **CMD Starship**: requires [Clink](https://mridgers.github.io/clink/) (`winget install clink`). Run install.ps1 option 6 after installing Clink.
- **ble.sh**: installed separately via `scripts/install-blesh.sh`. Requires bash-completion ≥ 2.12 and fzf ≥ 0.61 (older versions cause `read` errors).
- **Tmux plugins**: after first install, press `Prefix+I` (Ctrl+a then I) to install TPM plugins. Theme won't load until TPM runs.
- **RHEL bat**: `bat` may not be in default RHEL repos. Enable COPR: `dnf copr enable atim/bat`.
- **fd on RHEL**: package is named `fd-find`; binary may be `fdfind` on some versions.
- **WezTerm transparency**: requires compositor on Linux (picom, etc.). On Windows, requires DWM.
