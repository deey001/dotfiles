# Gemini Session Memory - March 27, 2026

This file serves as a persistent memory of the dotfiles overhaul and reorganization session to ensure continuity and easy troubleshooting for future sessions.

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
10. **Tmux Modernization:** Moved status bar to the **top**, applied **Catppuccin** theme, and added **SessionX** (fuzzy project switcher via `Prefix + o`).
11. **Tmux Status Restoration:** Reintegrated the custom network IP address script into the modern Catppuccin status bar.
12. **`cat` (bat) Optimization:** Added `--paging=never` and `BAT_PAGER="less -X"` to ensure syntax-highlighted output remains on screen after exit.
13. **Windows Integration:** Added `Symlink-Dotfiles` and `Install-CoreTools` (winget) to `install.ps1`.
14. **Robust Uninstall:** Updated `uninstall.sh` to cleanly revert all symlinks, configurations, and packages added during this session.
15. **Repository Reorganization (NEW):**
    - Cleaned up the root directory by moving files into logical subdirectories:
        - `dots/`: Core dotfiles (e.g., `.bashrc`, `.zshrc`, `.tmux.conf`).
        - `scripts/`: Execution and installation scripts (`install.sh`, `install.ps1`, etc.).
        - `docs/`: Documentation and setup guides.
        - `templates/`: Configuration templates.
    - Deleted redundant/orphaned files: `local-setup.ps1`, `packer_install.vim`, `setup-windows.bat`, `.screenrc`.
    - Updated all scripts and the `Makefile` to reflect new paths.

## 📁 Key File Changes
- **`scripts/install.sh`**: Updated with root-directory detection and subfolder symlinking.
- **`scripts/install.ps1`**: Updated to source dotfiles from the `dots\` directory.
- **`Makefile`**: Updated to point to scripts in the `scripts/` folder.
- **`.zshrc`**: Created native Zsh support with Starship and shared aliases.
- **`.config/alacritty/`**: Standardized font family and size (14.0) across both formats.
- **`README.md`**: Updated Quick Install one-liners to point to the new `scripts/` paths.

## 🚀 Commands for Next Time
- **To Sync Changes:**
    - `git add .`
    - `git commit -m "Your message"`
    - `git push origin master` (Requires your Personal Access Token)
- **To Install Newest Changes:**
    - **Linux/Mac:** `curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash`
    - **Windows:** `irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex`

## ⚠️ Potential Issues to Watch
- **Ubuntu ARM:** The `bzip2` dependency warning is safely handled/ignored by the script.
- **Windows Admin:** `install.ps1` requires Administrator for fonts and symlinks.
- **Terminal Font:** On macOS Terminal.app, you must manually select "JetBrainsMono Nerd Font" in Settings once.

## 📝 User Notes
- User is `deey001` on GitHub.
- Environment: Darwin (macOS).
- Goal: Maintain the same look/feel for terminal across all environments.
