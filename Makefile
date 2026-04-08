# ==============================================================================
# Makefile — Dotfiles Management Shortcuts
# ==============================================================================
# Provides a simple interface for the most common dotfiles operations.
# Run 'make help' to see all available targets.
#
# USAGE:
#   make              → Install (default target: runs install.sh)
#   make install      → Install packages + symlink all dotfiles via GNU Stow
#   make uninstall    → Remove all managed symlinks from $HOME
#   make test         → Run the validation suite (13+ checks)
#   make test-verbose → Same, with symlink targets and tool versions printed
#   make theme-mocha  → Switch to Catppuccin Mocha (dark, default)
#   make theme-latte  → Switch to Catppuccin Latte (light)
#   make theme        → Show currently active theme
#   make help         → Display this usage message
#
# WORKFLOW — First-time setup on a new Linux/macOS machine:
#   git clone https://github.com/deey001/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && make install
#
# WORKFLOW — After pulling updates:
#   cd ~/dotfiles && git pull && make install
#   (Stow's -R/--restow is idempotent — safe to run multiple times)
#
# WORKFLOW — Switching themes:
#   cd ~/dotfiles && make theme-latte   # switch to light mode
#   source ~/.config/dotfiles/theme.sh  # apply in current shell (or restart)
#
# WINDOWS:
#   Use scripts/install.ps1 instead — Makefile targets are Unix-only.
#   See README.md → Windows Setup for details.
#
# DEPENDENCIES:
#   - bash (all targets shell out to bash scripts)
#   - GNU Stow (installed automatically by install.sh if missing)
# ==============================================================================

.PHONY: all install uninstall test test-verbose \
        theme theme-mocha theme-latte \
        help

# ── Default Target ────────────────────────────────────────────────────────────
# Running 'make' with no arguments triggers the full install.
all: install

# ── Install ───────────────────────────────────────────────────────────────────
# Runs scripts/install.sh which:
#   1. Detects OS (macOS / Debian / Arch / RHEL)
#   2. Installs system packages from meta/packages/<distro>.txt
#   3. Installs GNU Stow if missing
#   4. Stows all packages (bash, zsh, git, shell, tmux, config) into $HOME
#   5. Stows the default theme package (theme-catppuccin-mocha)
install:
	@echo "--- Starting Dotfiles Installation ---"
	@bash scripts/install.sh

# ── Uninstall ─────────────────────────────────────────────────────────────────
# Removes all symlinks created by 'make install'.
# Does NOT delete the repo or any backed-up files.
# After uninstalling, your shell will fall back to system defaults.
uninstall:
	@echo "--- Removing Dotfiles Symlinks ---"
	@bash scripts/uninstall.sh

# ── Test ──────────────────────────────────────────────────────────────────────
# Validates the installation with 4 test groups:
#   [1/4] Symlinks     — each $HOME dotfile points back into the repo
#   [2/4] Commands     — required tools (git, tmux, nvim, starship) are installed
#   [3/4] Optional     — modern CLI tools (eza, bat, fzf, zoxide, rg)
#   [4/4] Syntax       — bash -n on all Bash config files
# Exit 0 = all passed. Exit 1 = failures printed above summary.
test:
	@echo "--- Running Validation Tests ---"
	@bash scripts/test.sh

# ── Test Verbose ──────────────────────────────────────────────────────────────
# Same as 'make test' but prints symlink targets and tool version strings
# for every passing test. Useful when debugging a partially-installed machine.
test-verbose:
	@echo "--- Running Detailed Validation Tests ---"
	@bash scripts/test.sh --verbose

# ── Theme: Show Active ────────────────────────────────────────────────────────
# Prints which theme is currently stowed and active.
# The active theme is the stow/theme-*/ package whose files are symlinked into
# ~/.config/dotfiles/theme.sh.
theme:
	@if [ -L "$$HOME/.config/dotfiles/theme.sh" ]; then \
	    target=$$(readlink "$$HOME/.config/dotfiles/theme.sh"); \
	    echo "Active theme: $$target"; \
	    if [ -f "$$HOME/.config/dotfiles/theme.sh" ]; then \
	        slug=$$(bash -c 'source "$$HOME/.config/dotfiles/theme.sh" 2>/dev/null && echo $$DOTFILES_THEME' HOME="$$HOME"); \
	        echo "  Theme slug:  $${slug:-unknown}"; \
	    fi; \
	elif [ -f "$$HOME/.config/dotfiles/theme.sh" ]; then \
	    echo "Active theme: (non-symlink file) $$HOME/.config/dotfiles/theme.sh"; \
	else \
	    echo "No theme stowed. Run: make theme-mocha"; \
	fi

# ── Theme: Catppuccin Mocha (dark, default) ───────────────────────────────────
# Unstows any active theme-* package, then stows theme-catppuccin-mocha.
# After switching, reload the theme in your current shell with:
#   source ~/.config/dotfiles/theme.sh
# Or simply open a new terminal — .common_shell sources it on every start.
theme-mocha:
	@echo "--- Switching theme → Catppuccin Mocha ---"
	@stow -d . -t "$$HOME" --ignore='.DS_Store' -D theme-catppuccin-latte 2>/dev/null || true
	@stow -d . -t "$$HOME" --ignore='.DS_Store' -R theme-catppuccin-mocha
	@echo "[OK] Theme set to Catppuccin Mocha"
	@echo "     Run: source ~/.config/dotfiles/theme.sh (or open a new terminal)"

# ── Theme: Catppuccin Latte (light) ──────────────────────────────────────────
# Unstows any active theme-* package, then stows theme-catppuccin-latte.
# Note: After switching to Latte you may also want to update your terminal
# background color to match (WezTerm reads DOTFILES_WEZTERM_THEME automatically).
theme-latte:
	@echo "--- Switching theme → Catppuccin Latte ---"
	@stow -d . -t "$$HOME" --ignore='.DS_Store' -D theme-catppuccin-mocha 2>/dev/null || true
	@stow -d . -t "$$HOME" --ignore='.DS_Store' -R theme-catppuccin-latte
	@echo "[OK] Theme set to Catppuccin Latte"
	@echo "     Run: source ~/.config/dotfiles/theme.sh (or open a new terminal)"

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  dotfiles — Management Targets"
	@echo "  ─────────────────────────────────────────────────"
	@echo "  make install        Install packages + symlink configs (default)"
	@echo "  make uninstall      Remove symlinks from home directory"
	@echo "  make test           Run validation suite"
	@echo "  make test-verbose   Run validation suite with detailed output"
	@echo ""
	@echo "  make theme          Show currently active theme"
	@echo "  make theme-mocha    Switch to Catppuccin Mocha (dark, default)"
	@echo "  make theme-latte    Switch to Catppuccin Latte (light)"
	@echo ""
	@echo "  Windows: use scripts/install.ps1 (see README.md)"
	@echo ""
