# ==============================================================================
# Dotfiles Makefile
# ==============================================================================
# This Makefile provides a convenient interface for managing your dotfiles.
# Instead of remembering long scripts, just run 'make'!
# ==============================================================================

.PHONY: all install uninstall test help

# Default target: Install everything
all: install

# Setup the environment and symlink configurations
install:
	@echo "--- Starting Dotfiles Installation ---"
	@bash scripts/install.sh

# Remove all symlinks from the home directory
uninstall:
	@echo "--- Removing Dotfiles Symlinks ---"
	@bash scripts/uninstall.sh

# Run the validation test suite
test:
	@echo "--- Running Validation Tests ---"
	@bash scripts/test.sh

# Run the validation test suite with detailed output
test-verbose:
	@echo "--- Running Detailed Validation Tests ---"
	@bash scripts/test.sh --verbose

# Display help information
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install       Setup dependencies and symlink configs (default)"
	@echo "  uninstall     Remove symlinks from home directory"
	@echo "  test          Run validation suite"
	@echo "  test-verbose  Run validation suite with detailed output"
	@echo "  help          Show this message"
