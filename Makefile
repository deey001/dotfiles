# ==============================================================================
# Makefile - Dotfiles Management Commands
# ==============================================================================
# This Makefile provides convenient shortcuts for common dotfiles operations.
#
# USAGE:
#   make install        # Install dotfiles
#   make uninstall      # Remove dotfiles
#   make test           # Run validation tests
#   make update         # Pull latest changes and reinstall
#   make help           # Show this help message
#
# EXAMPLES:
#   make install        # First time setup
#   make test           # Verify installation
#   make update         # Update to latest version
# ==============================================================================

.PHONY: help install uninstall test update backup clean stow-server stow-workstation stow-dry-run restow

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

##@ General Commands

help: ## Show this help message
	@echo "$(CYAN)Dotfiles Management Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\n$(GREEN)Usage:$(NC)\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(GREEN)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Installation

install: ## Install dotfiles and dependencies
	@echo "$(GREEN)Installing dotfiles...$(NC)"
	@chmod +x scripts/install.sh
	@./scripts/install.sh

uninstall: ## Remove dotfiles and restore backups
	@echo "$(YELLOW)Uninstalling dotfiles...$(NC)"
	@chmod +x scripts/uninstall.sh
	@./scripts/uninstall.sh

reinstall: uninstall install ## Uninstall and reinstall dotfiles

##@ Testing & Validation

test: ## Run validation tests
	@echo "$(GREEN)Running tests...$(NC)"
	@chmod +x scripts/test.sh
	@./scripts/test.sh

test-verbose: ## Run tests with verbose output
	@echo "$(GREEN)Running tests (verbose)...$(NC)"
	@chmod +x scripts/test.sh
	@./scripts/test.sh --verbose

##@ Updates

update: ## Update dotfiles from git and reinstall
	@echo "$(GREEN)Updating dotfiles...$(NC)"
	@git pull origin main || git pull origin master
	@$(MAKE) install

sync: ## Push local changes to remote repository
	@echo "$(GREEN)Syncing changes...$(NC)"
	@git add -A
	@git status
	@echo ""
	@echo "$(YELLOW)Ready to commit. Run 'git commit -m \"your message\"' and 'git push'$(NC)"

##@ Homebrew (macOS)

brew-install: ## Install packages from Brewfile (macOS only)
	@echo "$(GREEN)Installing Homebrew packages...$(NC)"
	@if [ -f Brewfile ]; then \
		brew bundle --file=Brewfile; \
	else \
		echo "$(YELLOW)Brewfile not found!$(NC)"; \
	fi

brew-dump: ## Update Brewfile with currently installed packages (macOS only)
	@echo "$(GREEN)Updating Brewfile...$(NC)"
	@brew bundle dump --force --file=Brewfile

brew-cleanup: ## Remove packages not in Brewfile (macOS only)
	@echo "$(YELLOW)Cleaning up Homebrew packages...$(NC)"
	@brew bundle cleanup --file=Brewfile

##@ GNU Stow

stow-server: ## Stow core packages (bash, tmux, nvim, etc.) — for headless servers
	@echo "$(GREEN)Stowing core packages (server profile)...$(NC)"
	@cd $(CURDIR) && stow --restow bash zsh git shell tmux nvim starship bat atuin fastfetch

stow-workstation: ## Stow all packages including GUI tools — for workstations/macOS
	@echo "$(GREEN)Stowing all packages (workstation profile)...$(NC)"
	@cd $(CURDIR) && stow --restow bash zsh git shell tmux nvim starship bat atuin fastfetch alacritty

stow-dry-run: ## Preview what stow would create (no changes made)
	@echo "$(GREEN)Dry run — no changes will be made:$(NC)"
	@cd $(CURDIR) && stow -nv bash zsh git shell tmux nvim starship bat atuin fastfetch alacritty

restow: ## Restow all packages (cleans up stale symlinks after repo changes)
	@echo "$(GREEN)Restowing all packages...$(NC)"
	@cd $(CURDIR) && stow --restow bash zsh git shell tmux nvim starship bat atuin fastfetch alacritty

##@ Utilities

backup: ## Create a backup of current dotfiles
	@echo "$(GREEN)Creating backup...$(NC)"
	@backup_dir="$$HOME/dotfiles_backup_$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$backup_dir"; \
	cp -r ~/.bashrc ~/.bash_aliases ~/.bash_exports ~/.bash_functions ~/.bash_wrappers ~/.bash_profile ~/.tmux.conf ~/.gitconfig ~/.inputrc ~/.blerc "$$backup_dir" 2>/dev/null || true; \
	cp -r ~/.config/starship.toml ~/.config/nvim ~/.config/alacritty ~/.config/bat ~/.config/fastfetch "$$backup_dir" 2>/dev/null || true; \
	echo "$(GREEN)Backup created at: $$backup_dir$(NC)"

clean: ## Remove temporary files and caches
	@echo "$(GREEN)Cleaning temporary files...$(NC)"
	@find . -type f -name "*.swp" -delete
	@find . -type f -name "*.swo" -delete
	@find . -type f -name "*~" -delete
	@find . -type f -name ".DS_Store" -delete
	@echo "$(GREEN)Cleanup complete!$(NC)"

check-deps: ## Check if required dependencies are installed
	@echo "$(GREEN)Checking dependencies...$(NC)"
	@command -v bash >/dev/null 2>&1 && echo "  ✓ bash" || echo "  ✗ bash (missing)"
	@command -v git >/dev/null 2>&1 && echo "  ✓ git" || echo "  ✗ git (missing)"
	@command -v tmux >/dev/null 2>&1 && echo "  ✓ tmux" || echo "  ✗ tmux (missing)"
	@command -v nvim >/dev/null 2>&1 && echo "  ✓ nvim" || echo "  ✗ nvim (optional)"
	@command -v starship >/dev/null 2>&1 && echo "  ✓ starship" || echo "  ✗ starship (optional)"
	@command -v eza >/dev/null 2>&1 && echo "  ✓ eza" || echo "  ✗ eza (optional)"
	@command -v bat >/dev/null 2>&1 && echo "  ✓ bat" || echo "  ✗ bat (optional)"

##@ Git Operations

git-status: ## Show git status
	@git status

git-diff: ## Show uncommitted changes
	@git diff

git-log: ## Show recent commits
	@git log --oneline --graph --decorate -10
