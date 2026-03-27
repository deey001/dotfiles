# Copilot Instructions

## What This Repo Is

Cross-platform dotfiles for headless servers (macOS, Debian/Ubuntu, RHEL/Fedora, Arch, Windows via PowerShell). The goal is an identical terminal experience across all environments: Bash shell with Starship prompt, Neovim (LazyVim), Tmux, and modern CLI tool replacements.

## Commands

```bash
make install          # Run scripts/install.sh (installs deps + symlinks dotfiles)
make uninstall        # Run scripts/uninstall.sh
make test             # Run scripts/test.sh (validates symlinks, commands, syntax, permissions)
make test-verbose     # Same with --verbose flag
make brew-install     # Install packages from Brewfile (macOS only)
make check-deps       # Quick check for required/optional tools
```

## Architecture

### Directory Layout

- `dots/` — All dotfiles (`.bashrc`, `.tmux.conf`, `.gitconfig`, etc.). These get symlinked into `$HOME` by the installer.
- `scripts/` — `install.sh`, `uninstall.sh`, `test.sh`, `install.ps1`. All executable logic lives here.
- `.config/` — App configs (nvim, starship, bat, fastfetch, alacritty, tmux scripts) symlinked into `~/.config/`.
- `templates/` — `.bash_local.template` for machine-specific secrets/overrides (not tracked in git).
- `docs/` — Setup guides (Windows, installer preview).

### Bash Config Load Order

`.bash_profile` → `.bashrc` → sources these in order:
1. `.bash_exports` — Environment variables, PATH, EDITOR
2. `.bash_aliases` — Aliases (modern tool replacements with `command -v` guards)
3. `.bash_functions` — Utility functions (`extract`, `mkdirg`, `ftext`, `up`)
4. `.bash_wrappers` — Wrapper functions (colored man pages)
5. `.bash_local` — Machine-specific overrides (from `templates/.bash_local.template`, gitignored)
6. `.blerc` — ble.sh config (syntax highlighting/autosuggestions for Bash)

### Install Script Behavior

`scripts/install.sh` does the following in order:
1. Bootstraps itself when piped via `curl | bash` (clones repo, re-execs)
2. Detects OS and CPU architecture (x86_64 vs ARM64)
3. Checks internet connectivity (supports air-gapped mode)
4. Validates `.bashrc` syntax before linking (prevents shell lockout)
5. Installs system packages via the detected package manager (apt/dnf/pacman/brew)
6. Installs pinned tools (Neovim v0.11.0, Starship, lazygit, etc.)
7. Symlinks everything from `dots/` into `$HOME` and `.config/` into `~/.config/`
8. Backs up any existing configs to `~/dotfiles_backup_<timestamp>/`

## Key Conventions

- **All shell scripts use `set -euo pipefail`** — strict error handling throughout.
- **Every config file has a header comment block** with a description, usage examples, and section separators using `# ====` and `# ----` lines.
- **Modern tools always have fallback guards** — aliases check `command -v` before replacing builtins. Original commands available via `old*` prefix (e.g., `oldcat`, `oldls`).
- **Cross-platform conditionals** — scripts detect OS via `uname` and distro via package manager presence. Never assume a specific platform.
- **Environment detection flags** — `.bashrc` exports `IS_SSH`, `IS_WSL`, `IS_DOCKER`, `IS_TMUX` for conditional behavior.
- **Secrets go in `.bash_local`** — never commit tokens or machine-specific config. Use `templates/.bash_local.template` as a starting point.
- **Tool versions are pinned** at the top of `scripts/install.sh` (e.g., `NEOVIM_VERSION="0.11.0"`).
- **EditorConfig enforces formatting** — shell scripts use 4-space indent; YAML/JSON/TOML use 2-space; Makefiles use tabs.
