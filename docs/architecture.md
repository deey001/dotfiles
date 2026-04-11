# Architecture

## File Layout

```
dotfiles/
├── home/                    # Stow packages (each dir mirrors $HOME)
│   ├── bash/                # .bashrc, .bash_profile, .bash_aliases, .blerc
│   ├── zsh/                 # .zshrc
│   ├── git/                 # .gitconfig, .gitignore, .gitattributes
│   ├── shell/               # .inputrc, .common_shell, .editorconfig
│   └── config/              # .config/ subtree (nvim, tmux, starship, wezterm, etc.)
├── scripts/                 # install.sh, uninstall.sh, test.sh, install-blesh.sh
├── themes/                  # Catppuccin theme files (mocha, latte)
├── platform/                # OS-specific package lists + Windows configs
├── docs/                    # Reference documentation
└── Makefile                 # Management targets
```

## Shell Load Order

### Bash (login shell)
```
/etc/profile → ~/.bash_profile → ~/.profile → ~/.bashrc
                                                  ├─ ble.sh (early, attach=none)
                                                  ├─ history, shell options
                                                  ├─ terminal colors
                                                  ├─ ~/.common_shell (env, PATH, fzf, EDITOR)
                                                  ├─ ~/.bash_aliases
                                                  ├─ PATH dedup
                                                  ├─ bash-completion, carapace
                                                  ├─ fzf keybindings
                                                  ├─ zoxide, atuin, direnv, starship
                                                  ├─ ~/.bash_local
                                                  ├─ fastfetch (login only)
                                                  └─ ble.sh (attach)
```

### Zsh
```
~/.zshrc
  ├─ ~/.common_shell (env, PATH, fzf, EDITOR)
  ├─ history, completion (compinit)
  ├─ carapace, fzf-tab
  ├─ completion styling
  ├─ key bindings
  ├─ ~/.bash_aliases
  ├─ zoxide, fzf keybindings
  ├─ zsh plugins (syntax-highlighting, autosuggestions, history-substring-search)
  ├─ atuin, direnv, starship
  ├─ ~/.zsh_local / ~/.bash_local
  └─ fastfetch
```

### Shared files
- `.common_shell` — env vars (EDITOR, PAGER, LANG, LESS, BAT, FZF, PATH), mkcd()
- `.bash_aliases` — all aliases (sourced by both bash and zsh)
- Theme files — sourced by .common_shell via `~/.config/dotfiles/theme.sh` symlink

## Neovim Load Order (LazyVim)
```
init.lua → config/lazy.lua (bootstrap lazy.nvim)
             ├─ LazyVim defaults
             ├─ config/options.lua (before plugins)
             └─ plugins/*.lua (colorscheme, snacks, custom, colorizer)
```

## Theme System

Themes are shell scripts exporting color variables. One is symlinked as the active theme:
```
themes/catppuccin-mocha.sh ──symlink──> ~/.config/dotfiles/theme.sh
```

Switch with `make theme-mocha` or `make theme-latte`. The symlink is sourced by
`.common_shell` on every shell start, setting BAT_THEME, DOTFILES_FZF_COLORS,
DOTFILES_WEZTERM_THEME, and the full DOTFILES_COLOR_* palette.

## Stow

GNU Stow manages symlinks. `.stowrc` sets `--dir=. --target=~`.
`home/` is a single stow package whose structure mirrors `$HOME` directly.
`stow -R home` creates symlinks for all dotfiles and the `.config/` subtree.

## Dependencies

**Required:** bash, git, stow, curl (for remote bootstrap)
**Core tools:** tmux, nvim, starship
**Optional (guarded):** eza, bat, fzf, fd, zoxide, atuin, ripgrep, direnv,
carapace, delta, dust, duf, procs, btop, xh, ble.sh

## Platforms

- **macOS** — Homebrew (Brewfile)
- **Debian/Ubuntu** — apt (platform/packages/ubuntu.txt)
- **Arch** — pacman (platform/packages/arch.txt)
- **RHEL/Fedora** — dnf/yum (platform/packages/rhel.txt)
- **Windows** — PowerShell (scripts/install.ps1, platform/windows/)
