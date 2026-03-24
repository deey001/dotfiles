# Gemini Session Memory - March 23, 2026

This file serves as a persistent memory of the dotfiles overhaul session to ensure continuity and easy troubleshooting for future sessions.

## 🛠 Session Objectives Achieved
1.  **Cross-Platform Consistency:** Ensured a "same look and feel" across macOS, Linux (multiple distros), and Windows.
2.  **Unified Font Strategy:** Standardized to `JetBrainsMono Nerd Font` globally. Updated all installers and terminal configs (Alacritty `.yml` and `.toml`).
3.  **One-Liner Bootstrap:** Fixed the `unbound variable` error in `install.sh`. The script now automatically clones to `~/dotfiles` if run via `curl | bash`.
4.  **Dual-Shell Support (Bash & Zsh):** Created a robust `.zshrc` that sources shared aliases/functions. Standardized syntax highlighting and autosuggestions across both shells.
5.  **Architecture Awareness:** `install.sh` now detects **x86_64** vs **ARM64** and downloads correct binaries.
6.  **Neovim ARM Fix:** Implemented automatic architecture verification for Neovim. The script now detects and removes "Exec format error" binaries, swapping them for the correct ARM64 version.
7.  **Ubuntu Robustness:** Bypassed "broken" `bzip2` and `build-essential` dependencies on minimal images by installing compilers (`make`, `gcc`) individually first.
8.  **ble.sh UI Cleanup:** Completely suppressed the `-- MULTILINE --` marker and status line in `.blerc` for a cleaner pasting experience.
9.  **SSH Multiplexing:** Added automatic creation of `~/.ssh/sockets` to enable faster connection reuse.
10. **Windows Integration:** Added `Symlink-Dotfiles` and `Install-CoreTools` (winget) to `install.ps1`.
11. **Robust Uninstall:** Updated `uninstall.sh` to cleanly revert all symlinks, configurations, and packages added during this session.

## 📁 Key File Changes
- **`install.sh`**: Added architecture detection, bootstrap cloning, individual compiler loops, and Neovim arch-fix.
- **`.zshrc`**: Created native Zsh support with Starship and shared aliases.
- **`.blerc`**: Suppressed status line and multiline markers.
- **`.config/alacritty/`**: Standardized font family and size (14.0) across both `.yml` and `.toml` formats.
- **`uninstall.sh`**: Completed with full cleanup logic for all new components.
- **`Brewfile`**: Added `gawk`, `gcc`, `make`, and Zsh plugins.

## 🚀 Commands for Next Time
- **To Sync Changes:**
    - `git add .`
    - `git commit -m "Your message"`
    - `git push origin master` (Requires your Personal Access Token)
- **To Install Newest Changes:**
    - **Linux/Mac:** `curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/install.sh | bash`
    - **Windows:** `irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex`

## ⚠️ Potential Issues to Watch
- **Ubuntu ARM:** The `bzip2` dependency warning is safely handled/ignored by the script.
- **Windows Admin:** `install.ps1` requires Administrator for fonts and symlinks.
- **Terminal Font:** On macOS Terminal.app, you must manually select "JetBrainsMono Nerd Font" in Settings once.

## 📝 User Notes
- User is `deey001` on GitHub.
- Goal: Maintain the same look/feel for terminal across all environments.
