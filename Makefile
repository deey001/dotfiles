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
# WINDOWS:
#   Use scripts/install.ps1 instead — Makefile targets are Unix-only.
#   See README.md → Windows Setup for details.
#
# DEPENDENCIES:
#   - bash (all targets shell out to bash scripts)
#   - GNU Stow (installed automatically by install.sh if missing)
# ==============================================================================

.PHONY: all install uninstall test test-verbose help

# ── Default Target ────────────────────────────────────────────────────────────
# Running 'make' with no arguments triggers the full install.
all: install

# ── Install ───────────────────────────────────────────────────────────────────
# Runs scripts/install.sh which:
#   1. Detects OS (macOS / Debian / Arch / RHEL)
#   2. Installs system packages from meta/packages/<distro>.txt
#   3. Installs GNU Stow if missing
#   4. Stows all packages (bash, zsh, git, shell, tmux, config) into $HOME
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

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  dotfiles — Management Targets"
	@echo "  ─────────────────────────────────────"
	@echo "  make install        Install packages + symlink configs (default)"
	@echo "  make uninstall      Remove symlinks from home directory"
	@echo "  make test           Run validation suite"
	@echo "  make test-verbose   Run validation suite with detailed output"
	@echo "  make help           Show this message"
	@echo ""
	@echo "  Windows: use scripts/install.ps1 (see README.md)"
	@echo ""
