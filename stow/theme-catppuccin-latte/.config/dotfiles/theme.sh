# ==============================================================================
# .config/dotfiles/theme.sh — Active Theme Loader (Catppuccin Latte)
# ==============================================================================
# See stow/theme-catppuccin-mocha/.config/dotfiles/theme.sh for full docs.
# This version loads the Latte (light) palette.
# ACTIVATE: make theme-latte
# ==============================================================================

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

if [ -n "$_DOTFILES_THEMES_DIR" ] && [ -f "$_DOTFILES_THEMES_DIR/catppuccin-latte.sh" ]; then
    # shellcheck source=../../../themes/catppuccin-latte.sh
    source "$_DOTFILES_THEMES_DIR/catppuccin-latte.sh"
fi

unset _dotfiles_theme_dir _DOTFILES_THEMES_DIR
