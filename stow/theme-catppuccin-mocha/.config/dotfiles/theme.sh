# ==============================================================================
# .config/dotfiles/theme.sh — Active Theme Loader
# ==============================================================================
#
# LOCATION:  ~/.config/dotfiles/theme.sh  (symlinked from stow/theme-*/...)
# SOURCED BY: ~/.common_shell
#
# This file is the theme selector: it knows which theme is active (by virtue
# of which stow/theme-<name>/ package is currently stowed) and sources the
# correct theme definition file from the dotfiles repo.
#
# STOW PACKAGES (only ONE should be stowed at a time):
#   stow/theme-catppuccin-mocha/  → this file loads themes/catppuccin-mocha.sh
#   stow/theme-catppuccin-latte/  → this file loads themes/catppuccin-latte.sh
#
# SWITCH THEMES:
#   make theme-latte    # unstow mocha, stow latte
#   make theme-mocha    # unstow latte, stow mocha
# ==============================================================================

# Locate the dotfiles repo: check common clone locations.
# The themes/ directory must exist alongside scripts/, stow/, etc.
_dotfiles_theme_dir() {
    for candidate in \
        "$HOME/dotfiles" \
        "$HOME/.dotfiles" \
        "$HOME/code/dotfiles" \
        "$HOME/dev/dotfiles"
    do
        if [ -d "$candidate/themes" ]; then
            echo "$candidate/themes"
            return
        fi
    done
}

_DOTFILES_THEMES_DIR="$(_dotfiles_theme_dir)"

if [ -n "$_DOTFILES_THEMES_DIR" ] && [ -f "$_DOTFILES_THEMES_DIR/catppuccin-mocha.sh" ]; then
    # shellcheck source=../../../themes/catppuccin-mocha.sh
    source "$_DOTFILES_THEMES_DIR/catppuccin-mocha.sh"
fi

unset _dotfiles_theme_dir _DOTFILES_THEMES_DIR
