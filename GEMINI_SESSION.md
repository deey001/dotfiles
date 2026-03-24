# Gemini Session Memory - March 23, 2026

This file serves as a persistent memory of the dotfiles overhaul session to ensure continuity and easy troubleshooting for future sessions.

## 🛠 Session Objectives Achieved
1.  **Cross-Platform Consistency:** Ensured a "same look and feel" across macOS, Linux (multiple distros), and Windows.
2.  **Unified Font Strategy:** Standardized to `JetBrainsMono Nerd Font` globally. Updated all installers (`install.sh`, `install.ps1`, `local-setup.ps1`) and terminal configs.
3.  **One-Liner Bootstrap (NEW):** Fixed the `unbound variable` error in `install.sh`. The script now automatically clones the repository to `~/dotfiles` if run via `curl | bash`, making it truly a "one-liner" installer.
4.  **Dual-Shell Support (Bash & Zsh):** Created a robust `.zshrc` that sources your existing aliases/functions. Standardized the terminal experience (Starship, syntax highlighting, autosuggestions) across both shells. No shell switch required on macOS!
5.  **Architecture Awareness (NEW):** Made `install.sh` architecture-aware. It now detects if the system is **x86_64** or **ARM64** (Apple Silicon, Ubuntu ARM) and downloads the correct binaries for Neovim, Lazygit, Glow, etc.
6.  **Portable Alacritty:** Removed hardcoded shell paths to make `alacritty.yml` work out-of-the-box on Windows/macOS/Linux.
4.  **Windows Integration:** Added a robust `Symlink-Dotfiles` function to `install.ps1`. It now links `.bashrc`, `.tmux.conf`, and `.config/nvim` to the correct Windows user profile paths.
5.  **Neovim Reliability:**
    - Added `gcc`, `make`, and `unzip` to all Linux/macOS installers for Treesitter support.
    - Added `Install-CoreTools` to Windows (`winget`) to install Neovim, Git, Ripgrep, etc.
    - Added automatic Neovim plugin syncing (`Lazy! sync`) to the installation process.
6.  **Quick Install:** Added one-liner commands to the top of `README.md` for both Linux/Mac and Windows.

## 📁 Key File Changes
- **`install.sh`**: Robust distro detection (Arch, Debian, RedHat), standardized font paths, added build tools, and Neovim sync.
- **`install.ps1`**: Added winget tool installation, AppData symlinking, and interactive menu options.
- **`alacritty.yml`**: Standardized font family and removed `/bin/bash` dependency.
- **`Brewfile`**: Updated to `font-jetbrains-mono-nerd-font` and added `gcc/make`.
- **`.tmux.conf`**: Improved portability by removing `/bin/bash` from status scripts.
- **`.bash_local.template`**: Created for machine-specific overrides.

## 🚀 Commands for Next Time
- **To Sync Changes:**
    - `git add .`
    - `git commit -m "Your message"`
    - `git push origin master` (Requires your Personal Access Token)
- **To Install Newest Changes:**
    - **Linux/Mac:** `bash install.sh` or `make update`
    - **Windows:** `powershell ./install.ps1` (Choose Option 8 for full setup)

## ⚠️ Potential Issues to Watch
- **Windows Admin:** `install.ps1` needs to be run as Administrator to install fonts and create symlinks.
- **GitHub PAT:** Pushing changes via HTTPS requires a Personal Access Token instead of a password.
- **SSH Keys:** `MDC_public.pub` is present, but the matching private key is not in `~/.ssh`. Authentication currently relies on HTTPS + PAT.

## 📝 User Notes
- User is `deey001` on GitHub.
- Environment: Darwin (macOS).
- Goal: Maintain the same look/feel for terminal across all environments.
