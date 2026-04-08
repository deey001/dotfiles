# Session Memory — April 2026 Overhaul

Persistent context for the dotfiles repo (github.com/deey001/dotfiles).
User: Danny. 

---

## 🏗️ New Simplified Architecture

The repository underwent a major simplification overhaul in April 2026 to reduce maintenance overhead and improve cross-platform reliability.

### Stow Meta-Packages
Individual tool packages were consolidated into logical groups:
```
stow/
  bash/       → ~/.bashrc, ~/.bash_aliases, ~/.blerc, ~/.bash_profile
  zsh/        → ~/.zshrc
  git/        → ~/.gitconfig
  shell/      → ~/.common_shell (Shared logic), ~/.inputrc
  tmux/       → ~/.tmux.conf
  config/     → All ~/.config/ items (nvim, wezterm, starship, bat, atuin, fastfetch)
```

### The "Unified Shell Brain"
*   **`.common_shell`**: All shared aliases, environment variables (EDITOR, PAGER), and functions now live here.
*   **Source Logic**: Both `.bashrc` and `.zshrc` source `~/.common_shell`. Update once, use everywhere.
*   **Consolidation**: Legacy fragments (`.bash_exports`, `.bash_functions`, `.bash_wrappers`) were merged directly into `.bashrc`.

---

## 📦 Automated Installation

### macOS / Linux (One-Liner)
```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```
*   **New Logic**: Uses distro-specific package lists in `meta/packages/*.txt`.
*   **Auto-Clone**: Automatically clones the repo to `~/dotfiles` if run via pipe.
*   **Repo Tools**: Use `make install`, `make test`, or `make uninstall`.

### Windows (PowerShell 7+)
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```
*   **Features**: Auto-installs Git/Nerd Fonts, cleans PowerShell profiles, and creates Windows-native symlinks for Git Bash/WSL compatibility.
*   **Starship**: Double-linked to `~/.config/starship.toml` and `~/starship.toml` for maximum compatibility.

---

## 🎨 Key Features & Theming

| Feature | Tool | Notes |
|:--- |:--- |:--- |
| **Theme** | Catppuccin Mocha | Applied to Nvim, Tmux, WezTerm, Fzf, and Prompt. |
| **Prompt** | Starship | "Smart" SSH-only username/host, native OS icon colors, right-aligned timer. |
| **Terminal** | WezTerm | Primary terminal with Lua config and auto-SSH logging. |
| **Editor** | LazyVim | Enhanced with `nvim-colorizer` for hex color backgrounds. |
| **Tmux** | Community Plugins | Replaced custom 150-line network script with `0xAF/tmux-public-ip`. |

---

## ✅ Known Working State (April 2026)

- **Ubuntu 24.04+**: All symlinks verified, Starship icons and colors OK.
- **Windows 11**: `install.ps1` handles auto-elevation and profile "Power-Wash" correctly.
- **Git Bash**: Correctly inherits Bash/Starship settings via Windows-native symlinks.
- **Encoding**: All Windows-side scripts use ASCII-safe icons to prevent parsing errors.

---

## 🛠️ Maintenance Reference

| Script | Purpose |
|:--- |:--- |
| `scripts/install.sh` | Clean, package-list based bootstrapper (Linux/macOS). |
| `scripts/install.ps1` | Full-featured Windows setup tool with interactive menu. |
| `scripts/test.sh` | Validation suite (13+ symlink checks). |
| `Makefile` | Standard shortcuts: `make`, `make test`, `make clean`. |
