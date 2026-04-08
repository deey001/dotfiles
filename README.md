# 🚀 Modern & Minimal Dotfiles

A high-performance, cross-platform configuration for macOS and Linux (Debian/Ubuntu, Arch, RHEL). This repository uses a **unified shell architecture** and is themed with **Catppuccin Mocha** throughout.

---

### 📦 Quick Install (The One-Liner)

**macOS / Linux (Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```

**Windows (PowerShell 7+):**
*Run this in an elevated PowerShell window to install fonts and tools:*
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```

---

## 🏗️ Architecture: The "Why" and "How"

### Cross-Platform Support
- **Linux/macOS:** Handled by `scripts/install.sh` using **GNU Stow**. It manages symlinks and system packages.
- **Windows:** Handled by `scripts/install.ps1`. It focuses on **Nerd Fonts** (critical for icons), **Windows Terminal** themes, and creating Windows-native symlinks so that **Git Bash** can share your Linux configurations.
- **WSL:** You should run the **Linux** installer inside your WSL distribution.

### Why GNU Stow?
We use **GNU Stow** because it is the safest way to manage dotfiles.
*   **Safety:** It uses symlinks (`~/.bashrc` → `~/dotfiles/stow/bash/.bashrc`). Your real files stay in the repository.
*   **Speed:** You can edit a file in the repo, and the change is active in your home folder immediately.
*   **Cleanup:** Uninstalling is as simple as deleting the symlinks.

### Why the Unified Shell?
Instead of maintaining separate logic for Bash and Zsh, we use a **Shared Brain** model:
1.  **`stow/shell/.common_shell`**: Contains 90% of your aliases, environment variables (EDITOR, PAGER), and custom functions.
2.  **`.bashrc` / `.zshrc`**: These shells act as "loaders" that source the common shell.
3.  **Benefit:** Add an alias once; use it everywhere.

---

## 🛠️ Repository Structure

| Directory | Purpose | How it works |
|:--- |:--- |:--- |
| `scripts/` | **Control Center** | Contains `install.sh` (setup), `uninstall.sh` (cleanup), and `test.sh` (validation). |
| `stow/` | **Configuration** | Configs managed by GNU Stow. |
| `stow/config/` | **Apps Config** | Everything in `~/.config/` (Neovim, WezTerm, Starship, etc). |
| `stow/bash/` | **Bash Config** | `.bashrc`, `.bash_aliases`, `.blerc`. |
| `stow/shell/` | **Shared Brain** | `.common_shell` (Shared aliases/exports), `.inputrc`. |
| `meta/packages/` | **Dependencies** | Simple `.txt` files listing required system packages for each OS. |
| `docs/` | **Knowledge** | Guides for manual integrations (e.g., WezTerm + KeePass). |

---

## ⌨️ Feature Highlights

### 🎨 Theming: Catppuccin Mocha
- Consistent colors across **Neovim**, **Tmux**, **WezTerm**, **Fzf**, and your **Prompt**.

### 🐚 Shell: Power & Prediction
- **Starship Prompt:** 2-line minimal prompt with native OS colors and right-aligned execution timer.
- **ble.sh:** Full syntax highlighting and Fish-style autosuggestions inside Bash.
- **atuin:** Magical fuzzy history search (Ctrl-R) with sync capabilities.
- **zoxide:** Smart `cd` replacement that learns your habits.

### 📝 Editor: LazyVim (Neovim)
- A pre-configured distribution with LSP, Treesitter, and a built-in **Hex Colorizer** plugin.

### 🖥️ Terminal: WezTerm
- GPU-accelerated terminal with Lua-based configuration and automatic **SSH session logging**.

---

## 🧹 Maintenance

### Updating
To pull new changes and refresh your symlinks:
```bash
cd ~/dotfiles && git pull && bash scripts/install.sh
```

### Testing
To verify that all your symlinks are healthy:
```bash
bash ~/dotfiles/scripts/test.sh
```

### Uninstalling
To remove all symlinks and revert to system defaults:
```bash
bash ~/dotfiles/scripts/uninstall.sh
```
