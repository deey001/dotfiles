# Dotfiles


### Quick Install


**Any Linux/Mac:**
```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```


**Windows:**
```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```


A modern, cross-platform dotfiles configuration for macOS and Linux (Debian/Ubuntu, RHEL/Fedora, Arch). Themed with **Catppuccin Mocha** throughout — terminal, editor, tmux, git diffs, and prompt.


---


## Features


### Catppuccin Mocha Theme — Everywhere
- **Starship Prompt**: Pure-inspired minimal two-line prompt
- **Neovim**: LazyVim distribution with full Catppuccin integration
- **Tmux**: Hand-crafted status pills with rounded separators
- **Alacritty**: Terminal colors and cursor
- **bat**: Syntax-highlighted cat replacement
- **git-delta**: Beautiful diff viewer
- **fzf**: Fuzzy finder colors

### Modern Shell Experience (Bash + Zsh)
- **Starship Prompt**: Minimal two-line Pure-inspired prompt — OS icon, directory, git, language versions on line 1, ❯ on line 2
- **Smart Completions**: carapace multi-shell completion engine with rich descriptions + fzf-tab vertical dropdown (zsh)
- **Predictive Text**: ble.sh for bash (syntax highlighting, autosuggestions, menu-complete dropdown)
- **Shell History**: atuin — magical fuzzy shell history search with sync support (replaces Ctrl+R)
- **Fuzzy Finder**: fzf with Catppuccin colors for files, history, and completions
- **Smart Navigation**: zoxide learns your cd patterns, fcd() for fuzzy directory jump
- **Shell Detection**: Install script auto-detects active shell (bash/zsh) and configures accordingly
- **Environment Detection**: Automatically detects SSH, WSL, Docker, and Tmux sessions

### Neovim — LazyVim Distribution
- **LazyVim**: Full-featured Neovim distribution — batteries included
- **Snacks.nvim**: Dashboard, file explorer, fuzzy picker, zen mode, lazygit, notifications, smooth scroll
- **Noice.nvim**: Floating popup for `:` commands with autocompletion
- **Which-key**: Press `Space` to see all available keybindings
- **Built-in**: Treesitter, Telescope, LSP, Mason, Gitsigns, Lualine, Flash, Autopairs, Indent guides
- **Custom**: render-markdown.nvim for beautiful markdown, 18 treesitter parsers

### Tmux
- **Catppuccin Status Bar**: Rounded pill separators with network status, date/time, directory
- **Session Persistence**: Auto-save/restore with tmux-resurrect + tmux-continuum
- **Session Switcher**: tmux-sessionx fuzzy session manager (`Prefix + o`)
- **Floating Terminal**: tmux-floax popup pane (`Prefix + p`)
- **URL Extraction**: tmux-fzf-url finds/opens URLs in panes
- **Quick Copy**: tmux-thumbs for instant text extraction
- **Vim Navigation**: h/j/k/l pane movement, v/s splits
- **Network Monitor**: Real-time LAN/VPN/WAN IP with ISP detection
- **Scrollback**: 1,000,000 lines

### Modern CLI Tools
| Tool | Replaces | What it does |
|------|----------|--------------|
| eza | ls | Icons, git status, tree view |
| bat | cat | Syntax highlighting (no pager) |
| ripgrep (rg) | grep | Fast, respects .gitignore |
| fd | find | Simple, fast file search |
| zoxide | cd | Learns your navigation patterns |
| dust | du | Visual disk usage tree |
| duf | df | Colorful disk free display |
| procs | ps | Modern process viewer |
| btop | top | Beautiful resource monitor |
| git-delta | diff | Syntax-highlighted git diffs |
| atuin | Ctrl+R | Magical shell history search |
| carapace | — | Multi-shell completion engine |
| lazygit | — | Terminal UI for git |
| lazydocker | — | Terminal UI for Docker |
| xh | curl | Modern HTTP client |
| fzf | — | Fuzzy finder for everything |
| tldr | man | Simplified command examples |
| glow | — | Markdown renderer |
| fastfetch | — | System information display |

All originals accessible via `old*` prefix: `oldcat`, `oldfind`, `olddu`, `olddf`, `oldps`, `oldtop`.

---

## Neovim Cheat Sheet (LazyVim)

### Navigation
| Key | Action |
|-----|--------|
| `Space` | Show all keybindings (which-key) |
| `Space Space` | Smart find files |
| `Space /` | Grep across project |
| `Space ,` | Switch buffers |
| `Space e` | Toggle file explorer |
| `Ctrl+h/j/k/l` | Navigate between windows |
| `s` + char | Flash jump to character |

### Files & Search
| Key | Action |
|-----|--------|
| `Space f f` | Find files |
| `Space f g` | Live grep |
| `Space f r` | Recent files |
| `Space f b` | Open buffers |
| `Space f t` | Find TODOs |
| `Space f c` | Commands |

### Git
| Key | Action |
|-----|--------|
| `Space g g` | Open Lazygit |
| `Space g b` | Toggle git blame |
| `Space g d` | Git diff current file |
| `Space g p` | Preview hunk |
| `]h` / `[h` | Next/previous git hunk |

### Code & LSP
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `Space c a` | Code actions |
| `Space c r` | Rename symbol |
| `]d` / `[d` | Next/previous diagnostic |

### Quality of Life
| Key | Action |
|-----|--------|
| `Space z` | Zen mode (distraction-free) |
| `Space n` | Notification history |
| `:` | Floating command palette with autocompletion |
| `/` | Search with buffer completion |
| `Space u` | Toggle UI elements |
| `Space q q` | Quit all |
| `Space q s` | Restore session |

---

## Tmux Cheat Sheet

**Prefix**: `Ctrl+a` (not default Ctrl+b)

### Sessions & Windows
| Key | Action |
|-----|--------|
| `Prefix + o` | Fuzzy session switcher (sessionx) |
| `Prefix + p` | Floating terminal pane (floax) |
| `Prefix + c` | New window |
| `Prefix + ,` | Rename window |
| `Prefix + &` | Close window |
| `Prefix + 1-9` | Switch to window N |
| `Prefix + d` | Detach session |

### Panes
| Key | Action |
|-----|--------|
| `Prefix + v` or `\\` | Split vertical |
| `Prefix + s` or `-` | Split horizontal |
| `Prefix + h/j/k/l` | Vim-style pane navigation |
| `Alt + Arrow` | Pane navigation (no prefix) |
| `Prefix + Shift+Arrow` | Resize pane |
| `Prefix + S` | Synchronize panes (type in all) |
| `Prefix + x` | Close pane |

### Copy Mode
| Key | Action |
|-----|--------|
| `Prefix + [` | Enter copy mode |
| `v` | Start selection (in copy mode) |
| `y` | Copy to clipboard (in copy mode) |
| `Prefix + ]` | Paste |

### Plugins
| Key | Action |
|-----|--------|
| `Prefix + I` | Install plugins (TPM) |
| `Prefix + U` | Update plugins |
| `Prefix + u` | Open URLs in pane (fzf-url) |
| `Prefix + r` | Reload config |
| `Prefix + m/M` | Toggle mouse on/off |

### Status Bar
- **Left**: Session name pill (green, turns red on prefix)
- **Right**: Directory > Date/Time (12h) > Network (LAN/WAN/ISP)
- All styled with Catppuccin Mocha rounded pills

---

## Shell Shortcuts & QoL

### Navigation Functions
| Command | Action |
|---------|--------|
| `fcd` | Fuzzy find and cd into a directory |
| `fv` | Fuzzy find and open a file in nvim |
| `fp` | Fuzzy find a running process |
| `..` / `...` / `....` | Go up 1/2/3 directories |
| `-` | Go to previous directory |

### Git Aliases
| Alias | Command |
|-------|---------|
| `ga` | `git add` |
| `gst` | `git status` |
| `gd` | `git diff` |
| `gc "msg"` | `git commit -m "msg"` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gco branch` | `git checkout branch` |
| `glog` | Pretty git log graph |

### Quick Aliases
| Alias | What it does |
|-------|-------------|
| `v` / `vi` / `vim` | Opens Neovim |
| `c` | Clear screen |
| `q` | Exit shell |
| `tree` | `eza --tree --icons` |
| `mkdir` | Always creates parent dirs (-p) |
| `da` | Show full date and timezone |

### Shell History (Atuin)
- **Ctrl+R**: Opens atuin fuzzy history search
- Type to filter, Enter to execute
- Syncs across machines (optional)
- Filters secrets (TOKEN, KEY, PASSWORD) from history

### Tab Completion
- **Zsh**: fzf-tab vertical dropdown with carapace descriptions
- **Bash**: ble.sh menu-complete dropdown with carapace descriptions
- Press **Tab** to trigger, arrow keys to navigate, Enter to select

---

## Installation

### Windows Users: Local Setup First!

You **MUST** run the local setup script first to install Nerd Fonts, or icons will show as broken squares.

1. Open **PowerShell as Administrator**
2. Run:
   ```powershell
   irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
   ```
3. Type `4` for "Full Local Setup" (installs font, configures terminals)
4. Restart all terminal windows

<details>
<summary>Windows Troubleshooting</summary>

| Problem | Solution |
|---------|----------|
| "Script is disabled" error | Run: `Set-ExecutionPolicy Bypass -Scope Process` |
| "Could not create SSL/TLS channel" | Re-run the command (auto-fixes) |
| Icons are broken squares | Restart terminal; check font is "JetBrainsMono Nerd Font" |
| Permission Denied | Use Run as Administrator |

</details>

### Quick Install (Server/Mac/Linux)

```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
cd ~/dotfiles && bash scripts/install.sh
```

**Post-install:**
- **Tmux**: Press `Prefix + I` (`Ctrl+a` then `I`) to install plugins
- **Neovim**: Open `nvim` — LazyVim auto-installs ~40 plugins on first launch
- **macOS**: Run `brew bundle --file=~/dotfiles/Brewfile` for all CLI tools
- **Reload Shell**: `exec $SHELL`

---

## File Structure

### Shell Configuration
| File | Purpose |
|------|---------|
| `.bashrc` | Main bash config (carapace, fzf, atuin, ble.sh) |
| `.zshrc` | Main zsh config (fzf-tab, carapace, atuin, syntax-highlighting) |
| `.bash_aliases` | Command aliases with modern tool fallbacks |
| `.bash_exports` | Environment variables (EDITOR, BAT_THEME, PATH) |
| `.bash_functions` | Utility functions (fcd, fv, fp, extract, cd override) |
| `.bash_wrappers` | Custom functions (colored man pages, whatsgoingon) |
| `.bash_profile` | Login shell sourcing |
| `.bash_local` | Machine-specific settings (not tracked) |
| `.blerc` | ble.sh config for bash (menu-complete, autosuggestions) |
| `.inputrc` | Readline config with smart completion |

### Application Configs
| File | Purpose |
|------|---------|
| `.tmux.conf` | Tmux with catppuccin pills, 12 plugins, vim nav |
| `.gitconfig` | Git config with delta pager, aliases, Catppuccin diffs |
| `.config/nvim/` | LazyVim distribution (init.lua + lua/{config,plugins}/) |
| `.config/starship.toml` | Pure-inspired prompt with Catppuccin Mocha |
| `.config/atuin/config.toml` | Shell history config (fuzzy, compact, secret filter) |
| `.config/alacritty/` | Terminal config with Catppuccin Mocha colors |
| `.config/bat/themes/` | Catppuccin Mocha bat theme |
| `.config/tmux/scripts/` | Network status bar script |
| `.config/fastfetch/` | System info display config |
| `.editorconfig` | Editor formatting rules |
| `.ssh/config` | SSH client config template |

### Management
| File | Purpose |
|------|---------|
| `scripts/install.sh` | Main installer (shell detection, cross-platform) |
| `scripts/uninstall.sh` | Full cleanup/factory reset |
| `scripts/test.sh` | Installation validation |
| `Brewfile` | macOS Homebrew package declarations |

---

## Uninstallation

```bash
./scripts/uninstall.sh
```

Performs a full factory reset: removes symlinks, configs, tools (ble.sh, fonts), SSH keys, and optionally uninstalls system packages. Handles all package managers (apt, dnf, pacman, brew).

---

## Technical Details

### Shell Detection
The install script detects the active shell via `$SHELL`:
- Both bash and zsh configs are always symlinked
- Active shell dependencies are hard requirements; secondary shell uses `|| true`
- ble.sh only installs when bash is available
- carapace configures both shells

### Theme Configuration
- **bat**: `BAT_THEME="Catppuccin Mocha"` + `BAT_PAGING=never`
- **Starship**: Catppuccin Mocha colors in Pure-inspired layout
- **git-delta**: `syntax-theme = Catppuccin Mocha` with line numbers
- **fzf**: Catppuccin Mocha colors in `FZF_DEFAULT_OPTS`
- **Nerd Font**: JetBrainsMono Nerd Font for all icon support

### Plugin Load Order (Zsh)
```
compinit > carapace > fzf-tab > completion styles > fzf >
syntax-highlighting > autosuggestions > history-substring-search > atuin > starship
```

### Plugin Load Order (Bash)
```
history > env > shell opts > aliases > completion >
carapace > fzf > atuin > starship > ble.sh
```

### Tmux Status Bar
- Left: session pill (green/red on prefix) — hand-crafted with Nerd Font powerline separators
- Right: directory (rosewater) + date/time 12h (sapphire) + network (blue)
- Window tabs: catppuccin/tmux v2 plugin with rounded style
- Network: 5-min cached WAN/ISP via ip-api.com with jq JSON decode

### Alias System
All modern tools have conditional aliases with fallbacks:
```bash
if command -v duf >/dev/null 2>&1; then
    alias df='duf'       # Modern command
    alias olddf='/bin/df' # Original command
fi
```

---

## Troubleshooting

### Clipboard Copy Not Working
Your terminal must support **OSC 52** (Windows Terminal, Alacritty, iTerm2, WezTerm). PuTTY requires "Allow terminal to access clipboard" enabled.

### Network Icons Missing
Install **JetBrainsMono Nerd Font** on your local machine and set it as the terminal font.

### Bash 5.2 "read: not a valid identifier"
If you see this error while typing in Bash 5.2+ (common on Ubuntu 22.04), it is due to an incompatibility between the new strict `read` validation and older versions of `bash-completion` (2.11) or `fzf` (< 0.61).
**Fix**: This repo includes a `read()` wrapper in `~/.blerc` that automatically silences these errors while keeping `ble.sh` functionality. Ensure you have run `scripts/install.sh` and sourced `~/.bashrc`.

### git-delta Not Found
If git commands fail with "cannot run delta": install with `brew install git-delta` or use `git -c core.pager=cat` as workaround.

### LazyVim Plugins Not Loading
Ensure both init.lua AND lua/ are symlinked:
```bash
ls -la ~/.config/nvim/
# Should show init.lua -> .../dotfiles/.config/nvim/init.lua
#           lua      -> .../dotfiles/.config/nvim/lua
```
If lua/ is missing: `ln -sf ~/dotfiles/.config/nvim/lua ~/.config/nvim/lua`

---
