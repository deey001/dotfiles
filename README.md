# 🚀 Danny's Dotfiles — Cross-Platform Power Environment

A high-performance, cross-platform configuration for **macOS**, **Linux** (Debian/Ubuntu, Arch, RHEL), and **Windows**. Every tool is chosen deliberately, every setting has a reason, and the entire stack is unified under a single **Catppuccin Mocha** theme.

> **Philosophy:** Fast shell startup, consistent experience everywhere, zero manual steps after cloning.

---

## 📚 Table of Contents

- [Quick Install](#-quick-install)
- [Repo Structure](#️-repo-structure)
- [How It Works: GNU Stow](#-how-it-works-gnu-stow)
- [Unified Shell Architecture](#-unified-shell-architecture)
- [Environment Detection Flags](#️-environment-detection-flags)
- [Tool Reference](#️-tool-reference)
  - [Starship Prompt](#-starship-prompt)
  - [ble.sh — Bash Line Editor](#-blesh--bash-line-editor)
  - [WezTerm](#️-wezterm)
  - [Neovim / LazyVim](#-neovim--lazyvim)
  - [Tmux](#️-tmux)
  - [atuin — Shell History](#-atuin--shell-history)
  - [zoxide — Smart cd](#-zoxide--smart-cd)
  - [fzf — Fuzzy Finder](#-fzf--fuzzy-finder)
  - [eza — ls Replacement](#-eza--ls-replacement)
  - [bat — cat Replacement](#-bat--cat-replacement)
  - [carapace — Completions](#-carapace--completions)
  - [direnv — Per-Directory Env](#-direnv--per-directory-env)
  - [delta — Git Diff Viewer](#-delta--git-diff-viewer)
  - [ripgrep & fd](#-ripgrep--fd)
  - [fastfetch](#-fastfetch)
- [Catppuccin Mocha Theme](#-catppuccin-mocha-theme)
- [Windows Setup](#-windows-setup)
- [Make Targets](#️-make-targets)
- [Customisation: Machine-Local Config](#-customisation-machine-local-config)
- [Adding a New Machine](#-adding-a-new-machine)
- [Troubleshooting](#-troubleshooting)

---

## ⚡ Quick Install

The same one-liner works for every supported OS and distro — the script auto-detects your platform.

| Platform | One-liner |
|---|---|
| **macOS** | `curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh \| bash` |
| **Ubuntu / Debian** | same as above — `apt` packages are auto-selected |
| **Arch Linux** | same as above — `pacman` packages are auto-selected |
| **RHEL / Fedora** | same as above — `dnf` packages are auto-selected |
| **Windows (PS7+)** | `irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" \| iex` |

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
```

### Windows (PowerShell 7+, elevated window)

```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex
```

> The Windows installer runs an interactive menu — choose **A** for the full workflow (fonts → repo clone → theme → tools → shell profiles).

### macOS / Linux (from local clone)

```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install
```

> **WSL users:** Run the **Linux** one-liner *inside* your WSL distribution. Then run the Windows installer in an elevated PowerShell to set up Windows Terminal, the Nerd Font, and the theme.

---

## 🏗️ Repo Structure

```
dotfiles/
├── stow/
│   ├── bash/           # Bash-specific: .bashrc, .bash_aliases, .bash_profile, .blerc
│   ├── zsh/            # Zsh-specific: .zshrc
│   ├── git/            # .gitconfig (delta pager, aliases, signing)
│   ├── shell/          # Cross-shell: .common_shell, .inputrc, .editorconfig
│   ├── tmux/           # .tmux.conf
│   └── config/         # Everything that lands in ~/.config/:
│       ├── nvim/       #   LazyVim Neovim config
│       ├── wezterm/    #   WezTerm Lua config
│       ├── starship.toml
│       ├── bat/        #   bat theme config
│       ├── atuin/      #   atuin history config
│       └── fastfetch/  #   fastfetch layout config
├── windows/
│   ├── Microsoft.PowerShell_profile.ps1   # Full PS7 profile
│   └── settings.json                      # Windows Terminal config (Catppuccin Mocha)
├── scripts/
│   ├── install.sh        # Linux/macOS installer (GNU Stow + packages)
│   ├── install.ps1       # Windows installer (menu-driven)
│   ├── uninstall.sh      # Remove all managed symlinks
│   ├── test.sh           # Validate symlinks and tool presence
│   └── install-blesh.sh  # Standalone ble.sh installer
├── meta/
│   └── packages/
│       ├── ubuntu.txt    # apt package list
│       ├── arch.txt      # pacman package list
│       └── rhel.txt      # dnf package list
├── templates/
│   └── .bash_local.template   # Template for machine-local overrides
├── docs/                 # Extra guides (WezTerm + KeePass, etc.)
└── Makefile
```

### What goes where — the decision rule

| You want to configure… | Edit file in… |
|---|---|
| Something both Bash **and** Zsh should share | `stow/shell/.common_shell` |
| Bash-only behaviour | `stow/bash/.bashrc` or `.bash_aliases` |
| Zsh-only behaviour | `stow/zsh/.zshrc` |
| A `~/.config/` application | `stow/config/.config/<appname>/` |
| This machine only (never committed) | `~/.bash_local` or `~/.zsh_local` |

---

## 🔗 How It Works: GNU Stow

**GNU Stow** is a symlink farm manager. It takes a directory ("package") and creates symlinks in a target directory (defaulting to the parent of the package). Here, the target is `$HOME`.

```
~/dotfiles/stow/bash/.bashrc
        ↕  (symlink created by stow)
~/.bashrc
```

### Why Stow instead of a copy script?

- **Edits are live:** Change `~/dotfiles/stow/bash/.bashrc` and the change is immediately active at `~/.bashrc` — no re-running the installer.
- **Safety:** Your configs live inside the git repo; they can never get out of sync.
- **Clean uninstall:** `stow -D` removes all symlinks, leaving the system pristine. No files are ever deleted.
- **No per-file special cases:** Adding a new config is just dropping a file into the right `stow/` subdirectory.

### How the installer uses Stow

```bash
stow -v -d ~/dotfiles/stow -t "$HOME" bash
stow -v -d ~/dotfiles/stow -t "$HOME" zsh
stow -v -d ~/dotfiles/stow -t "$HOME" git
stow -v -d ~/dotfiles/stow -t "$HOME" shell
stow -v -d ~/dotfiles/stow -t "$HOME" tmux
stow -v -d ~/dotfiles/stow -t "$HOME" config
```

The `-d` flag sets the stow directory; `-t` sets the target. Each package mirrors the structure relative to `$HOME`. For example, `stow/config/.config/starship.toml` becomes `~/.config/starship.toml`.

### Conflict resolution

If Stow complains about "existing target is neither a link nor stow", a real file exists where Stow wants to place a symlink. Back it up and re-run:

```bash
mv ~/.bashrc ~/.bashrc.pre-dotfiles
make install
```

---

## 🐚 Unified Shell Architecture

Instead of duplicating aliases and exports across `.bashrc` and `.zshrc`, the setup uses a **shared brain** model:

```
.bashrc  ──┐
           ├──▶  .common_shell  (aliases, exports, functions, tool inits)
.zshrc   ──┘
```

### `stow/shell/.common_shell`

This is the heart of the shell configuration. It contains:

- **`$PATH` construction** — adds `~/.local/bin`, `~/.npm-global/bin`, Go bin, Cargo bin, etc.
- **Tool exports** — `EDITOR=nvim`, `PAGER="bat --plain"`, `MANPAGER="sh -c 'col -bx | bat -l man'"`, `BAT_THEME=Catppuccin-mocha`, etc.
- **All aliases** — `ls`→`eza`, `cat`→`bat`, git shortcuts, docker shortcuts, and more.
- **Shell functions** — `mkcd`, `extract`, `up`, etc.
- **Tool initialisations** — `eval "$(zoxide init bash)"`, `eval "$(atuin init bash)"`, `eval "$(carapace _carapace)"`, `eval "$(direnv hook bash)"`, etc.

### `stow/bash/.bashrc` — the Bash loader

`.bashrc` handles Bash-specific concerns then sources `.common_shell`:

1. Sets Bash options (`globstar`, `histappend`, `checkwinsize`, `cmdhist`, etc.)
2. Detects the environment and sets IS_* flags (see next section)
3. Sources `~/.common_shell`
4. Loads ble.sh with `--attach=none` early, then `ble-attach` at the very end (critical — see ble.sh section)
5. Sources `~/.bash_local` if it exists (machine-specific overrides, never committed)
6. Shows fastfetch on login shells (if not already inside Tmux)

### `stow/zsh/.zshrc` — the Zsh loader

`.zshrc` handles Zsh-specific concerns then sources `.common_shell`:

1. Sets Zsh options (`setopt`, `bindkey`)
2. Loads and runs `compinit` for completions
3. Sources `~/.common_shell`
4. Sources `~/.zsh_local` if it exists

---

## 🏷️ Environment Detection Flags

`.bashrc` detects the running context at startup and exports boolean flags. All flags are `1` (true) or `0` (false). They're available to every script and alias sourced afterwards.

| Flag | Detection method | What it controls |
|---|---|---|
| `IS_SSH` | `$SSH_CLIENT` or `$SSH_TTY` is non-empty | Starship shows hostname segment only when this is `1` |
| `IS_WSL` | `/proc/version` contains `microsoft` (case-insensitive) | Can trigger WSL-specific PATH additions or clipboard integration |
| `IS_DOCKER` | `/.dockerenv` exists | Can disable heavy UI features (fastfetch, etc.) inside containers |
| `IS_TMUX` | `$TMUX` env var is set | Prevents Tmux auto-attach loops; can skip fastfetch in sub-panes |
| `IS_ONLINE` | `ping -c1 -W1 1.1.1.1` succeeds (cached 5 min in `/run/user/$UID/.is_online`) | Skips slow network operations (atuin sync, etc.) when offline |

**Using these flags in your own scripts:**

```bash
[[ $IS_SSH    -eq 1 ]] && echo "Running over SSH — hostname is $(hostname)"
[[ $IS_WSL    -eq 1 ]] && export BROWSER="wslview"
[[ $IS_ONLINE -eq 1 ]] && atuin sync --force
[[ $IS_DOCKER -eq 0 ]] && fastfetch
```

---

## 🛠️ Tool Reference

### Quick-reference table

| Tool | Category | Config location | Key binding / alias |
|---|---|---|---|
| Starship | Prompt | `~/.config/starship.toml` | — |
| ble.sh | Bash UX | `~/.blerc` | inline suggestion: `→` |
| WezTerm | Terminal emulator | `~/.config/wezterm/` | `Ctrl+Shift+L` (dump log) |
| Neovim/LazyVim | Editor | `~/.config/nvim/` | `v`, `vi`, `vim` |
| Tmux | Multiplexer | `~/.tmux.conf` | prefix `Ctrl+a` |
| atuin | History | `~/.config/atuin/` | `Ctrl+R` |
| zoxide | Smart cd | shell init | `z <partial>`, `zi` |
| fzf | Fuzzy finder | env vars in `.common_shell` | `Ctrl+T`, `Alt+C` |
| eza | ls replacement | aliases in `.common_shell` | `ls`, `ll`, `la`, `l`, `tree` |
| bat | cat replacement | `~/.config/bat/` | `cat`, `PAGER` |
| carapace | Completions | shell init | `Tab` |
| direnv | Per-dir env | `.envrc` files | automatic on `cd` |
| delta | Git diff | `~/.gitconfig` | automatic with git |
| ripgrep | Search | — | `rg` |
| fd | Find | — | `fd` |
| fastfetch | System info | `~/.config/fastfetch/` | on login |

---

### ✨ Starship Prompt

**What it is:** Starship is a cross-shell prompt written in Rust. It works identically in Bash, Zsh, Fish, and PowerShell using a single config file.

**Why it's used here:** It is faster than Powerlevel10k and requires no shell-specific plugin manager. The same `starship.toml` works on Linux, macOS, and Windows — zero divergence.

**Config:** `~/.config/starship.toml` (managed at `stow/config/.config/starship.toml`)

**Theme:** Catppuccin Mocha applied via Starship's built-in `palettes` feature:

```toml
palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo  = "#f2cdcd"
pink      = "#f5c2e7"
mauve     = "#cba6f7"
red       = "#f38ba8"
maroon    = "#eba0ac"
peach     = "#fab387"
yellow    = "#f9e2af"
green     = "#a6e3a1"
teal      = "#94e2d5"
sky       = "#89dceb"
sapphire  = "#74c7ec"
blue      = "#89b4fa"
lavender  = "#b4befe"
text      = "#cdd6f4"
subtext1  = "#bac2de"
subtext0  = "#a6adc8"
overlay2  = "#9399b2"
overlay1  = "#7f849c"
overlay0  = "#6c7086"
surface2  = "#585b70"
surface1  = "#45475a"
surface0  = "#313244"
base      = "#1e1e2e"
mantle    = "#181825"
crust     = "#11111b"
```

**What the prompt shows:**

| Segment | Example | When shown |
|---|---|---|
| OS icon | 🐧 / 🍎 / 🪟 | Always |
| Directory | `~/dotfiles/stow/bash` | Always; truncated to 3 path levels |
| Git branch | ` main` | Inside any git repository |
| Git status | `✚1 ●2` | When staged (`✚`) or unstaged (`●`) changes exist |
| Language icons | `` Node 20, 🦀 Rust 1.78 | When relevant project files are detected in the CWD |
| Command duration | `took 3s` | For commands that took longer than 2 seconds |
| Hostname | `user@hostname` | **Only when `IS_SSH=1`** (ssh_only = true) |

**Hostname is SSH-only by design.** On your local machine the hostname is noise. Over SSH it immediately orients you. The `[hostname]` module is configured with `ssh_only = true`, which checks the same SSH environment variables as the `IS_SSH` flag.

**Initialisation (sourced in `.bashrc` and `.zshrc`):**

```bash
eval "$(starship init bash)"   # in .bashrc
eval "$(starship init zsh)"    # in .zshrc
```

**Debugging a misbehaving prompt:**

```bash
starship explain    # shows every active module and why it fired
starship timings    # shows how long each module takes to render
```

---

### 🖊️ ble.sh — Bash Line Editor

**What it is:** `ble.sh` (Bash Line Editor) brings **Fish-shell-level interactive features to Bash**:

- **Syntax highlighting** as you type — valid commands turn blue/green, unknown commands turn red, strings are coloured, etc.
- **Inline autosuggestions** — a ghosted suggestion from your history appears to the right of the cursor. Press `→` to accept it fully, or `Ctrl+→` to accept word-by-word.
- **Improved completion menu** — a visual popup list replaces the raw text dump from vanilla bash completion.
- **Enhanced vi/emacs mode** — better cursor shape changes, more consistent key bindings.

**Why not just switch to Fish or Zsh?** Bash is the universal default shell on every Linux server. Having Fish-level UX in Bash means SSH sessions to remote machines feel familiar immediately — without needing to install anything on the server (ble.sh runs purely client-side in your interactive shell).

**Config:** `~/.blerc` (managed at `stow/bash/.blerc`). Contains colour assignments to match Catppuccin Mocha via `ble-face` directives.

**The two-step load pattern (critical to understand):**

```bash
# ── Near the TOP of .bashrc ──────────────────────────────────────
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --attach=none

# ... all other .bashrc content (completions, PATH, tool inits) ...

# ── At the VERY BOTTOM of .bashrc ────────────────────────────────
[[ ${BLE_VERSION-} ]] && ble-attach
```

`--attach=none` loads ble.sh's code into memory **without** attaching to readline yet. This is required because readline must be fully initialised before ble.sh takes control. If you source it normally at the top, it breaks completions registered later. `ble-attach` at the very end performs the actual attachment after everything else is initialised.

**Install ble.sh:**

```bash
bash ~/dotfiles/scripts/install-blesh.sh
# installs to ~/.local/share/blesh/
```

This is run automatically by `install.sh`, but the standalone script lets you reinstall it on an existing setup.

---

### 🖥️ WezTerm

**What it is:** WezTerm is a **GPU-accelerated terminal emulator** configured entirely in **Lua**. It supports multiplexing (tabs, panes), image rendering, ligatures, and a powerful event/callback system.

**Why WezTerm over Alacritty or Kitty?** Lua config provides programmable control that static YAML/INI files cannot. For example: conditionally changing the background colour based on the current SSH host, or running arbitrary code when a tab is created. WezTerm also has the Catppuccin Mocha theme built in (no manual hex colours needed).

**Config:** `~/.config/wezterm/` (managed at `stow/config/.config/wezterm/`)

**Key settings:**

| Setting | Value | Reason |
|---|---|---|
| Color scheme | `Catppuccin Mocha` (built-in) | Consistent with the whole stack |
| Font | JetBrainsMono Nerd Font, size 13 | Full icon/glyph support (nerd font required for all icons) |
| GPU rendering | Enabled by default | Smooth scrolling even through large log outputs |
| Scrollback lines | Large buffer (configurable) | Retain context for long-running commands |

**Scrollback dump — `Ctrl+Shift+L`:**

Pressing `Ctrl+Shift+L` runs a WezTerm action that dumps the **entire scrollback buffer** to `~/logs/wezterm-<timestamp>.txt`. The `~/logs/` directory is created automatically on first use. This is the single most useful WezTerm feature: capturing command output that has already scrolled past, without needing to have thought ahead with `tee`.

**Relationship with Tmux:** WezTerm provides the GPU-rendered outer window and the font/colour layer. **Tmux** manages the sessions, windows, and panes inside it. You don't need to use WezTerm's built-in multiplexing.

---

### 📝 Neovim / LazyVim

**What it is:** Neovim is a modern, extensible fork of Vim. **LazyVim** is an opinionated Neovim distribution that pre-configures LSP, Treesitter, and dozens of quality-of-life plugins — all lazily loaded for fast startup (typically < 50ms).

**Config:** `~/.config/nvim/` (managed at `stow/config/.config/nvim/`)

**Aliases:**

```bash
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
```

**Key features from LazyVim:**

| Feature | Plugin(s) | What it gives you |
|---|---|---|
| LSP | `nvim-lspconfig` + `mason.nvim` | Language servers auto-installed; go-to-definition, hover docs, inline diagnostics |
| Syntax | `nvim-treesitter` | Semantic highlighting (understands code structure, not just regex) |
| File search | `telescope.nvim` / `fzf-lua` | Fuzzy file/symbol/text search inside Neovim |
| Git | `gitsigns.nvim` | Inline git blame, change markers in the gutter |
| Colorscheme | `catppuccin/nvim` | Full Catppuccin Mocha integration |
| Completion | `nvim-cmp` | LSP, snippet, and path completion |

**Opening dotfiles quickly:**

```bash
v ~/.common_shell
v ~/dotfiles/stow/config/.config/starship.toml
v ~/dotfiles/stow/tmux/.tmux.conf
```

---

### 🪟 Tmux

**What it is:** Tmux is a **terminal multiplexer** — it lets you run multiple terminal sessions inside one window, split your terminal into panes, and crucially, **detach and reattach to sessions**. An SSH session that gets disconnected doesn't kill your work; reattach and everything is where you left it.

**Config:** `~/.tmux.conf` (managed at `stow/tmux/.tmux.conf`)

**Prefix key:** `Ctrl+a`
Changed from the default `Ctrl+b` — ergonomically it's a single-hand chord, and it matches GNU Screen muscle memory for anyone who used Screen before Tmux.

#### Plugin Manager: TPM

All plugins are managed by **TPM** (Tmux Plugin Manager).

**Install TPM (once):**
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

**Install all plugins (inside Tmux):**
```
Ctrl+a  I         (capital I — Install plugins)
```

**Update all plugins:**
```
Ctrl+a  U         (capital U — Update plugins)
```

#### Installed plugins

| Plugin | What it does | Binding |
|---|---|---|
| `catppuccin/tmux` | Applies Catppuccin Mocha to the status bar, pane borders, and window tabs | Automatic on load |
| `tmux-plugins/tmux-sessionx` | Visual, fzf-powered session switcher with preview | `prefix + o` |
| `tmux-plugins/tmux-floax` | Floating terminal popup (scratchpad-style) | `prefix + p` |
| `tmux-plugins/tmux-resurrect` | Save and restore complete session state (windows, panes, cwd, running commands) across reboots | `prefix + Ctrl+s` save, `prefix + Ctrl+r` restore |
| `tmux-plugins/tmux-continuum` | Automatically saves session every 15 minutes; auto-restores on Tmux server start | Automatic |
| `tmux-plugins/tmux-thumbs` | Scan the visible terminal output for patterns (URLs, IPs, hashes, file paths) and let you copy them with a single keystroke hint | `prefix + Space` |
| `wfxr/tmux-fzf-url` | Open any URL visible in the terminal buffer using fzf and your `$BROWSER` | `prefix + u` |

#### Essential Tmux key bindings (with this config)

```
# Sessions
prefix + o          → sessionx visual switcher (fzf-powered, shows preview)
prefix + $          → rename current session
tmux new -s name    → (from shell) create named session
tmux attach -t name → (from shell) reattach to session
tmux ls             → (from shell) list all sessions

# Windows (tabs)
prefix + c          → new window
prefix + ,          → rename current window
prefix + n          → next window
prefix + p          → previous window (but see floax below)
prefix + 1–9        → jump to window N

# Panes
prefix + |          → split vertically (custom; default is %)
prefix + -          → split horizontally (custom; default is ")
prefix + h/j/k/l    → navigate panes vim-style (custom binding)
prefix + z          → toggle zoom (maximise/restore current pane)
prefix + x          → close current pane

# Power features
prefix + p          → floax: floating scratchpad terminal
prefix + Space      → thumbs: copy anything visible on screen
prefix + u          → fzf-url: open a URL from the screen
prefix + Ctrl+s     → resurrect: save session
prefix + Ctrl+r     → resurrect: restore session
```

---

### 🕐 atuin — Shell History

**What it is:** atuin replaces your shell's flat `$HISTFILE` with an **SQLite database**. Every command is stored with full metadata: working directory, exit code, duration, hostname, and timestamp.

**Why not just use HISTFILE?** The default history is a plain text file with no deduplication, no search beyond linear grep, and no metadata. atuin gives you:

- **Fuzzy full-text search** across every command ever run, on any machine
- **Rich context** — filter by directory, exit code, time range, host
- **Statistics** — `atuin stats` shows most-used commands, busiest days, etc.
- **Optional encrypted sync** — sync history across machines via atuin.sh or a self-hosted server

**Config:** `~/.config/atuin/` (managed at `stow/config/.config/atuin/`)

**Key binding:** `Ctrl+R` — opens the atuin TUI. Start typing to filter, use arrow keys to navigate, `Enter` to execute, `Tab` to edit before executing. `Esc` cancels and returns to the prompt without executing.

**Initialisation (in `.common_shell`):**
```bash
eval "$(atuin init bash)"   # or zsh
```

**Useful atuin commands:**
```bash
atuin stats             # command usage statistics
atuin search <query>    # non-interactive search, print results
atuin import auto       # import existing shell history into atuin's DB
atuin sync              # manually sync with remote (if configured)
atuin login             # set up sync with atuin.sh
```

---

### 🎯 zoxide — Smart cd

**What it is:** zoxide is a `cd` replacement written in Rust. It tracks every directory you visit and builds a **frecency** score (frequency × recency combined). When you type `z partial`, it jumps to the highest-scoring directory that matches the partial string — without you needing to type the full path.

**Why use it?** After a few days of normal use, `z dot` jumps to `~/dotfiles`, `z conf nv` jumps to `~/.config/nvim`, `z proj api` jumps to `~/projects/my-api`. You never type full paths again.

**Usage:**
```bash
z dotfiles          # cd ~/dotfiles  (highest-scoring match for "dotfiles")
z conf nvim         # cd ~/.config/nvim
z -                 # go back to previous directory (like cd -)
zi                  # interactive: pick from scored list using fzf
zoxide query -l     # list all tracked dirs with their scores
zoxide add .        # manually add current dir to the database
```

**Initialisation (in `.common_shell`):**
```bash
eval "$(zoxide init bash)"   # or zsh
```

This hooks into `cd` so every directory change updates the zoxide database.

---

### 🔍 fzf — Fuzzy Finder

**What it is:** fzf is a general-purpose command-line fuzzy finder. It reads lines from stdin and presents a filterable, interactive picker. It is both a standalone tool and a shell integration that adds powerful key bindings.

**Config (env vars in `.common_shell`):**

```bash
# Use fd instead of find for speed and .gitignore awareness
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Catppuccin Mocha colours
export FZF_DEFAULT_OPTS="  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8   --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc   --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8   --color=selected-bg:#45475a   --multi --height 60% --border"
```

**Shell key bindings (set up by `fzf --bash` / `fzf --zsh`):**

| Binding | What it does |
|---|---|
| `Ctrl+T` | Fuzzy file picker — pastes selected file path at the cursor |
| `Alt+C` | Fuzzy directory picker — `cd` into the selected directory |
| `Ctrl+R` | Fuzzy history search (atuin takes this in this setup; fzf is the fallback when atuin is absent) |

**Using fzf in one-liners:**
```bash
# Open a file in nvim, selected interactively
nvim $(fzf)

# Checkout a git branch interactively
git checkout $(git branch --all | fzf | tr -d '  ')

# Interactively pick a running process to send SIGTERM
ps aux | fzf --header-lines=1 | awk '{print $2}' | xargs -r kill

# Preview file contents while searching
fzf --preview 'bat --color=always {}'
```

---

### 📂 eza — ls Replacement

**What it is:** eza is a modern, opinionated `ls` replacement written in Rust. It adds colour coding by file type, **file icons** (requires Nerd Font), **git status** per file, and better default formatting.

**Why eza over ls?** Plain `ls` output is monochrome in many configurations, has no icons, and can't show git status. eza makes directory listings immediately informative at a glance.

**Aliases (from `.common_shell`):**

```bash
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias la='eza -lah --icons --group-directories-first --git'
alias l='eza -lah --icons --group-directories-first --git'
alias tree='eza --tree --icons'
```

**What each alias shows:**

| Alias | Includes hidden? | Long format? | Git status? | Notes |
|---|---|---|---|---|
| `ls` | No | No | No | Quick glance |
| `ll` | No | Yes | Yes | Everyday listing |
| `la` / `l` | Yes | Yes | Yes | Full listing including dotfiles |
| `tree` | No | No | No | Recursive tree (replaces the `tree` command) |

**`--git` flag** shows a two-character git status column: `M` (modified), `A` (added), `D` (deleted), `?` (untracked), `-` (ignored), `N` (new).

---

### 🦇 bat — cat Replacement

**What it is:** bat is a `cat` clone with **syntax highlighting**, **line numbers**, **git change markers** (lines that differ from HEAD are marked in the gutter), and automatic paging for long files.

**Why bat over cat?** Reading a config file with plain `cat` is a wall of monochrome text. `bat` immediately colour-codes the syntax, shows you the filename and language, paginates long files, and marks which lines were recently changed.

**Config:** `~/.config/bat/` (managed at `stow/config/.config/bat/`)

**Theme:** Catppuccin Mocha, applied via the config file and `BAT_THEME` env var.

**Aliases and integrations (from `.common_shell`):**

```bash
alias cat='bat'
export BAT_THEME="Catppuccin-mocha"
export PAGER="bat --plain"                           # bat as the system pager
export MANPAGER="sh -c 'col -bx | bat -l man'"      # man pages rendered with bat
```

**Showing a file without bat features (for scripts/piping):**
```bash
bat --plain --no-pager file.txt    # no line numbers, no pager
command cat file.txt               # bypass alias entirely, use raw cat
```

**bat as a pager for git:**
```bash
# In .gitconfig (handled by delta, but bat is also useful):
GIT_PAGER="bat --plain" git show HEAD
```

---

### 🔧 carapace — Completions

**What it is:** carapace-bin is a completion engine providing rich, spec-driven completions for **600+ CLI tools** across Bash, Zsh, Fish, PowerShell, and others — from a single source.

**Why not rely on each tool's built-in completions?** Many tools either don't ship completions, only ship them for one shell, or their completions are outdated. carapace provides consistent, up-to-date completions for everything from `git` to `docker` to `kubectl` to `aws`.

**Initialisation (in `.common_shell`):**
```bash
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
eval "$(carapace _carapace)"
```

After initialisation, `<Tab>` completion for any carapace-supported tool provides structured completions: subcommands, flags, and often valid values (e.g., container names for `docker exec <Tab>`, branch names for `git checkout <Tab>`).

---

### 📁 direnv — Per-Directory Env

**What it is:** direnv automatically **loads and unloads environment variables** when you enter or leave a directory containing an `.envrc` file.

**Why use it?** Instead of manually running `export AWS_PROFILE=dev` before working on a project, put that export in the project's `.envrc`. The moment you `cd` into the directory, the variable is active. Leave the directory, it's automatically unset. No cross-project variable pollution.

**Usage:**
```bash
cd ~/projects/my-api
cat > .envrc << 'EOF'
export DATABASE_URL="postgres://localhost/mydb"
export AWS_PROFILE="dev"
export NODE_ENV="development"
EOF
direnv allow    # one-time trust grant for this directory
# env vars are now live whenever you're in this directory
```

**Initialisation (in `.common_shell`):**
```bash
eval "$(direnv hook bash)"   # or zsh
```

**Security model:** direnv **never auto-trusts** a new `.envrc`. You must run `direnv allow` in each new project directory. This prevents a malicious cloned repo from executing arbitrary code the moment you `cd` into it. `direnv deny` revokes trust.

```bash
direnv allow    # trust current directory's .envrc
direnv deny     # revoke trust
direnv reload   # re-evaluate .envrc (after editing it)
direnv status   # show current status
```

---

### 🎨 delta — Git Diff Viewer

**What it is:** delta is a **syntax-highlighting pager** for `git diff`, `git show`, `git log -p`, and `git blame`. It replaces the raw `+`/`-` output with coloured, syntax-highlighted, optionally side-by-side diffs with line numbers.

**Config (in `~/.gitconfig`, managed at `stow/git/.gitconfig`):**

```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true          # press n/N to jump between diff hunks
    side-by-side = true      # show old and new side by side
    syntax-theme = Catppuccin-mocha
    line-numbers = true
    hyperlinks = true        # make file paths clickable in supported terminals
```

**You do not need to change any git commands.** Because delta is set as git's pager, it is used automatically by `git diff`, `git show`, `git log -p`, `git stash show`, and interactive staging (`git add -p`).

**Key bindings during a delta view:**
- `n` / `N` — jump forward/backward between diff sections (requires `navigate = true`)
- `q` — quit
- `Space` / `b` — page down / up

---

### ⚡ ripgrep & fd

#### ripgrep (`rg`)

A search tool that recursively searches directories for a regex pattern. Typically **10–100× faster than grep** because it uses Rust's regex engine, respects `.gitignore` automatically, skips binary files, and parallelises across CPU cores.

```bash
rg "TODO"                    # search all files in cwd for TODO
rg "fn main" src/            # search in src/ directory
rg -l "import os"            # list files containing the pattern (not lines)
rg -t py "class.*Model"      # search only .py files
rg -i "error" logs/          # case-insensitive search
rg --hidden "secret"         # include hidden files
rg -C 3 "panic!"             # show 3 lines of context around each match
```

Used internally by **fzf** (`FZF_DEFAULT_COMMAND` falls back to rg when fd isn't present) and **Neovim** (Telescope live_grep).

#### fd

A fast, user-friendly alternative to `find`. Respects `.gitignore`, uses colour by default, excludes `.git/` automatically, and has a much simpler syntax than `find`.

```bash
fd config                    # find files/dirs named "config" anywhere in tree
fd -e toml                   # find all .toml files
fd -t f -e py src/           # find regular .py files in src/
fd -t d node_modules         # find directories named node_modules
fd --hidden .env             # find hidden .env files
fd -x wc -l                  # find files and run wc -l on each (parallel)
```

Used internally by **fzf** (`FZF_DEFAULT_COMMAND='fd --type f --hidden ...'`) so `Ctrl+T` uses fd for file discovery.

---

### 🖥 fastfetch

**What it is:** fastfetch is a **neofetch replacement** written in C. It displays system information — OS, kernel, CPU, GPU, memory, disk, uptime, shell, terminal, and more — alongside an ASCII art logo when you open a terminal.

**Why fastfetch over neofetch?** Neofetch can take 1–2 seconds to start (Python, slow subprocess calls). fastfetch is near-instant (compiled C, parallel info gathering) and is actively maintained (neofetch is abandoned).

**Config:** `~/.config/fastfetch/` (managed at `stow/config/.config/fastfetch/`). The config file controls which modules are shown, their order, and formatting.

**When it runs:** Triggered near the end of `.bashrc`/`.zshrc` for interactive login shells, but **only when not already inside Tmux** (to avoid printing on every new pane/window):

```bash
[[ $- == *i* ]] && [[ -z "$TMUX" ]] && fastfetch
```

---

## 🎨 Catppuccin Mocha Theme

Catppuccin Mocha is a warm, dark pastel colour scheme. The design goal is consistent, legible colours across every tool — so everything looks like it belongs to the same system.

### Where it's applied

| Tool | How Catppuccin Mocha is applied |
|---|---|
| **Neovim** | `colorscheme catppuccin-mocha` via the catppuccin/nvim plugin in LazyVim config |
| **Tmux** | `catppuccin/tmux` TPM plugin; configured in `~/.tmux.conf` |
| **WezTerm** | `color_scheme = "Catppuccin Mocha"` — built into WezTerm, no external file needed |
| **Windows Terminal** | Full Mocha palette JSON in `windows/settings.json`, applied as a named colour scheme |
| **Starship** | `palette = "catppuccin_mocha"` with full hex palette defined in `starship.toml` |
| **bat** | `BAT_THEME="Catppuccin-mocha"` env var + theme file in `~/.config/bat/themes/` |
| **fzf** | `FZF_DEFAULT_OPTS` set with full hex colour map in `.common_shell` |
| **delta** | `syntax-theme = Catppuccin-mocha` in `~/.gitconfig` |
| **ble.sh** | `ble-face` colour assignments in `~/.blerc` |
| **PSReadLine** | `Set-PSReadLineOption -Colors @{...}` in the PowerShell profile |

### Palette quick reference

| Catppuccin name | Hex | Semantic use |
|---|---|---|
| Base | `#1e1e2e` | Main background |
| Mantle | `#181825` | Darker background (status bars, sidebars) |
| Surface0 | `#313244` | Selection / highlighted background |
| Surface2 | `#585b70` | Comments, disabled text |
| Text | `#cdd6f4` | Default foreground |
| Blue | `#89b4fa` | Commands, functions, keywords (some tools) |
| Green | `#a6e3a1` | Strings, success indicators |
| Red | `#f38ba8` | Errors, dangerous actions, keywords (some tools) |
| Yellow | `#f9e2af` | Warnings, constants |
| Mauve | `#cba6f7` | Types, special identifiers |
| Peach | `#fab387` | Numbers, attributes |
| Teal | `#94e2d5` | Types (some tools), success accent |
| Lavender | `#b4befe` | Cursor, accent |

---

## 🪟 Windows Setup

The Windows side of this dotfiles repo is a **first-class citizen**. The goal is to give PowerShell 7 the same quality of experience as the Linux shell, and to share as much config as possible (Starship, Neovim, bat, etc. all read the same files).

### Prerequisites

- **PowerShell 7** (`winget install Microsoft.PowerShell`)
- **Windows Terminal** (from the Microsoft Store or `winget install Microsoft.WindowsTerminal`)
- Run the installer from an **elevated** PowerShell 7 window (Start → right-click PowerShell → Run as Administrator)

### Running `install.ps1`

```powershell
# From an elevated PowerShell 7 window:
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex

# Or from a local clone:
.\scripts\install.ps1
```

A numbered menu appears. **Option A** runs all steps in sequence. Individual steps can be run selectively:

#### Step 1: Install JetBrainsMono Nerd Font

Downloads the font ZIP from the Nerd Fonts GitHub release and installs it system-wide (to `C:\Windows\Fonts`). **This is the most important step.** Without a Nerd Font, all icons in Starship, eza, and the terminal theme render as garbled boxes (□□□).

```powershell
# Manual verification:
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
(New-Object System.Drawing.Text.InstalledFontCollection).Families | Where-Object {$_.Name -like "*JetBrains*"}
```

#### Step 2: Configure Windows Terminal

Merges the `windows/settings.json` into Windows Terminal's actual `settings.json` (located at `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json`). Applies:

- Catppuccin Mocha as the default colour scheme (full hex palette)
- JetBrainsMono Nerd Font as the default font face
- Font size 12, ligatures enabled

#### Step 3: Configure PuTTY font

If PuTTY is installed, updates the registry key `HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings` to use JetBrainsMono Nerd Font. Ensures SSH sessions via PuTTY also render icons correctly.

#### Step 4: Install core tools via winget

```powershell
winget install Neovim.Neovim
winget install Git.Git
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
winget install Starship.Starship
winget install eza-community.eza
winget install fastfetch-cli.fastfetch
```

These are the minimal tools needed for parity with the Linux setup. `zoxide`, `bat`, `delta`, `fzf`, `carapace`, and `atuin` also have Windows binaries and can be installed the same way.

#### Step 5: Configure PowerShell profile

- Sets `$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"` as a permanent user environment variable
- Creates `$PROFILE` if it doesn't exist
- Appends a dot-source line pointing to `windows/Microsoft.PowerShell_profile.ps1`:
  ```powershell
  . "$HOME\dotfiles\windows\Microsoft.PowerShell_profile.ps1"
  ```

This pattern dot-sources the dotfiles profile without replacing `$PROFILE`, so any existing personal additions in `$PROFILE` are preserved.

#### Step 6: Configure CMD via Clink + Starship

Clink extends CMD with readline-style line editing and the ability to load Lua scripts (including a Starship integration). This gives CMD a Starship prompt.

```powershell
# Install Clink first:
winget install clink

# Then run install.ps1 option 6 — it places the Starship Lua script in Clink's scripts folder
```

#### Step 7: Symlink dotfiles into `%USERPROFILE%`

Creates Windows symlinks (`New-Item -ItemType SymbolicLink`) so the shared configs are read directly from the repo:

```
~\.config\starship.toml  →  dotfiles\stow\config\.config\starship.toml
~\.config
vim\          →  dotfiles\stow\config\.config
vim~\.configat\           →  dotfiles\stow\config\.configat~\.configtuin\         →  dotfiles\stow\config\.configtuin~\.configastfetch\     →  dotfiles\stow\config\.configastfetch```

> **Note:** Creating symlinks requires either running PowerShell as Administrator, or enabling **Developer Mode** in Windows Settings → System → For Developers.

---

### PowerShell Profile: `windows/Microsoft.PowerShell_profile.ps1`

This profile brings the full Linux shell quality of life to PowerShell 7. Loaded via a dot-source from `$PROFILE`.

#### PSReadLine — Catppuccin Mocha colours

```powershell
Set-PSReadLineOption -Colors @{
    Command            = '#89b4fa'   # Blue    — command names
    String             = '#a6e3a1'   # Green   — string literals
    Keyword            = '#f38ba8'   # Red     — keywords (if, for, function...)
    Comment            = '#585b70'   # Surface2 — comments
    Parameter          = '#cba6f7'   # Mauve   — command parameters
    Number             = '#fab387'   # Peach   — numeric literals
    Variable           = '#cdd6f4'   # Text    — variables
    Type               = '#94e2d5'   # Teal    — type names
    Operator           = '#89dceb'   # Sky     — operators
    Member             = '#b4befe'   # Lavender — object members
    InlinePrediction   = '#585b70'   # Surface2 — greyed-out suggestion
}
```

#### PSReadLine — History prediction

```powershell
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
```

`PredictionSource History` shows completions from your command history. `ListView` renders them as a dropdown list below the cursor (rather than inline ghost text), which is more readable in PowerShell's wider terminal.

#### Aliases and functions

```powershell
# ls replacements (wrapping eza)
function eza-ls { eza --icons --group-directories-first @args }
function eza-ll { eza -lh --icons --group-directories-first --git @args }
function eza-la { eza -lah --icons --group-directories-first --git @args }
Set-Alias ls   eza-ls
Set-Alias ll   eza-ll
Set-Alias la   eza-la

# Editor
Set-Alias v   nvim
Set-Alias vi  nvim
Set-Alias vim nvim

# Git
function g    { git @args }
function ga   { git add @args }
function gst  { git status }
function gd   { git diff @args }
function gc   { git commit @args }
function gp   { git push @args }
function gl   { git pull @args }
function gco  { git checkout @args }
function glog { git log --oneline --graph --decorate @args }

# Docker
function d  { docker @args }
function dc { docker compose @args }

# Utilities
function mkcd {
    New-Item -ItemType Directory -Path $args[0] -Force | Set-Location
}
function which { (Get-Command @args).Source }
```

#### zoxide init

```powershell
Invoke-Expression (& { (zoxide init powershell | Out-String) })
```

Same `z <partial>` and `zi` behaviour as on Linux.

#### Starship init (must be last)

```powershell
Invoke-Expression (&starship init powershell)
```

Starship must be the **last thing** in the profile. Anything that modifies the prompt (`$function:prompt`) after this line will overwrite Starship's prompt.

---

### Windows Terminal `settings.json`

Located at `windows/settings.json`. Key sections that get merged into Windows Terminal:

```jsonc
{
  "profiles": {
    "defaults": {
      "colorScheme": "Catppuccin Mocha",
      "font": {
        "face": "JetBrainsMono Nerd Font",
        "size": 12,
        "weight": "normal"
      },
      "useAtlasEngine": true
    }
  },
  "schemes": [
    {
      "name": "Catppuccin Mocha",
      "background": "#1E1E2E",
      "foreground": "#CDD6F4",
      "cursorColor": "#F5E0DC",
      "selectionBackground": "#45475A",
      "black":   "#45475A", "brightBlack":   "#585B70",
      "red":     "#F38BA8", "brightRed":     "#F38BA8",
      "green":   "#A6E3A1", "brightGreen":   "#A6E3A1",
      "yellow":  "#F9E2AF", "brightYellow":  "#F9E2AF",
      "blue":    "#89B4FA", "brightBlue":    "#89B4FA",
      "purple":  "#CBA6F7", "brightPurple":  "#CBA6F7",
      "cyan":    "#94E2D5", "brightCyan":    "#94E2D5",
      "white":   "#BAC2DE", "brightWhite":   "#A6ADC8"
    }
  ]
}
```

---

## ⚙️ Make Targets

The `Makefile` at the repo root provides convenience targets:

```bash
make install        # Run scripts/install.sh — full Linux/macOS setup
make uninstall      # Run scripts/uninstall.sh — remove all Stow-managed symlinks
make test           # Run scripts/test.sh — validate symlinks and tool presence
make test-verbose   # Run scripts/test.sh --verbose — detailed output per check
```

### What `scripts/install.sh` does

1. Detects the OS and installs packages from `meta/packages/<distro>.txt` (apt/pacman/dnf/brew)
2. Runs `stow` for all packages (bash, zsh, git, shell, tmux, config)
3. Installs ble.sh via `install-blesh.sh`
4. Clones TPM for Tmux if not already present
5. Prints a checklist of post-install manual steps (Tmux plugin install, Neovim first-open, etc.)

### What `scripts/test.sh` checks

- Each expected symlink exists and points to the correct target in `~/dotfiles/`
- Each required tool is on `$PATH`: `starship`, `nvim`, `tmux`, `eza`, `bat`, `fzf`, `rg`, `fd`, `zoxide`, `atuin`, `delta`, `carapace`, `direnv`, `fastfetch`
- Key config files are readable: `~/.config/starship.toml`, `~/.tmux.conf`, `~/.blerc`
- TPM directory exists at `~/.tmux/plugins/tpm`

```bash
make test-verbose   # see the full per-check output
```

---

## 🔧 Customisation: Machine-Local Config

Some settings are machine-specific and must never be committed: API keys, work proxies, a different git email for a work laptop, non-standard tool locations, etc.

### `~/.bash_local` (Bash)

Sourced at the **end of `.bashrc`**, so it can override anything set earlier.

Create from the template:
```bash
cp ~/dotfiles/templates/.bash_local.template ~/.bash_local
```

The template contains commented-out examples:
```bash
# ~/.bash_local — machine-specific overrides. Never committed to git.

# Work machine git identity
# export GIT_AUTHOR_EMAIL="danny@company.com"
# git config --global user.email "danny@company.com"

# Corporate proxy
# export HTTP_PROXY="http://proxy.company.com:8080"
# export HTTPS_PROXY="$HTTP_PROXY"
# export NO_PROXY="localhost,127.0.0.1,.company.com"

# Non-standard tool path
# export PATH="$PATH:/opt/proprietary-tools/bin"

# Override the default editor
# export EDITOR="code --wait"

# Disable fastfetch on this machine
# unset -f fastfetch 2>/dev/null; alias fastfetch=':'
```

### `~/.zsh_local` (Zsh)

Same concept, sourced at the end of `.zshrc`. Create it manually (no template):
```bash
touch ~/.zsh_local
```

---

## 🆕 Adding a New Machine

Complete checklist for getting from zero to fully operational on a fresh Linux/macOS machine.

### 1. Install prerequisites

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y git curl stow make build-essential

# Arch Linux
sudo pacman -Sy --needed git curl stow make base-devel

# RHEL / Fedora
sudo dnf install -y git curl stow make gcc

# macOS (install Homebrew first if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install stow
```

### 2. Clone the repo

```bash
git clone https://github.com/deey001/dotfiles.git ~/dotfiles
```

### 3. Run the installer

```bash
cd ~/dotfiles
make install
# or equivalently:
bash scripts/install.sh
```

### 4. Post-install steps

These require a running terminal/session and can't be automated:

```bash
# A) Install Tmux plugins
# Start a Tmux session, then press prefix+I (Ctrl+a then capital I)
tmux new -s setup
# Inside Tmux: press Ctrl+a then I — wait for plugins to clone and install

# B) Install Neovim plugins
# LazyVim auto-installs on first open; just wait for it to finish
nvim
# When prompted (or when the lazy.nvim UI appears), let it complete, then :q

# C) Reload your shell
exec bash   # (or exec zsh)

# D) Trust direnv in any project that uses .envrc
cd ~/some-project && direnv allow
```

### 5. Create machine-local overrides

```bash
cp ~/dotfiles/templates/.bash_local.template ~/.bash_local
# Edit with your machine-specific settings:
nvim ~/.bash_local
```

### 6. Verify everything

```bash
make test
# Expect: all checks pass
```

### 7. (Optional) Set up atuin sync

```bash
atuin register   # create account on atuin.sh
atuin login      # authenticate
atuin sync       # sync history from any other machines
```

---

## 🔍 Troubleshooting

### Icons show as boxes □□□ or question marks

**Cause:** The terminal is not using a Nerd Font.

**Fix on Linux (WezTerm):** Verify the font is installed:
```bash
fc-list | grep -i jetbrains
```
If no output, install JetBrainsMono Nerd Font:
```bash
# Download from https://www.nerdfonts.com/font-downloads
# Extract to ~/.local/share/fonts/ then:
fc-cache -fv
```

**Fix on macOS:** Install via Homebrew:
```bash
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

**Fix on Windows:** Run `install.ps1` option 1 (installs font system-wide). Then ensure Windows Terminal is set to use it (option 2).

**SSH note:** Icons need the Nerd Font on the **client** terminal, not the server. Fix your local terminal, not the remote machine.

---

### Stow fails with "existing target" error

```
WARNING! stowing bash would cause conflicts:
  * existing target is neither a link nor stow: .bashrc
```

**Cause:** A real (non-symlink) file exists at the target path, left over from before dotfiles were installed.

**Fix:**
```bash
# Back up conflicting files
mv ~/.bashrc ~/.bashrc.pre-dotfiles
mv ~/.gitconfig ~/.gitconfig.pre-dotfiles
# ... repeat for each conflicting file ...

# Then re-run
make install
```

---

### ble.sh doesn't load / shell has errors on startup

**Symptom:** You see errors like `~/.local/share/blesh/ble.sh: No such file or directory`, or the shell starts but has no syntax highlighting.

**Fix:**
```bash
bash ~/dotfiles/scripts/install-blesh.sh
# Verify:
ls ~/.local/share/blesh/ble.sh
```

**Check the load order:** In `.bashrc`:
- `source ~/.local/share/blesh/ble.sh --attach=none` must be near the **top**
- `ble-attach` must be at the very **bottom**

If `ble-attach` is missing, ble.sh loads but never attaches to readline.

---

### Tmux plugins not loading (no theme, bindings don't work)

**Symptom:** Tmux opens with default styling; `prefix + o` (sessionx) does nothing; `prefix + p` (floax) does nothing.

**Step 1:** Ensure TPM is installed:
```bash
ls ~/.tmux/plugins/tpm
# If missing:
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

**Step 2:** Install plugins from inside Tmux:
```
Ctrl+a  I     (capital I — Install)
```

Wait for the cloning to complete (you'll see progress at the bottom of the screen).

**Step 3:** If plugins were installed but stopped working after editing `.tmux.conf`:
```
Ctrl+a  :source-file ~/.tmux.conf
```

---

### Starship prompt not showing git info

**Symptom:** Starship shows the directory but no branch or git status.

**Check 1:** Are you inside a git repository?
```bash
git rev-parse --is-inside-work-tree
```

**Check 2:** Is git on PATH?
```bash
which git
```

**Check 3:** Debug Starship:
```bash
starship explain    # shows every active module and its reason
starship timings    # shows render time per module (useful to identify slow modules)
```

**Common cause:** Very large repos can make Starship's git module slow. Configure a timeout in `starship.toml`:
```toml
[git_status]
disabled = false

[git_branch]
disabled = false
```

---

### zoxide `z` command not found

**Cause:** zoxide is not installed, or its `eval` init isn't running.

**Check:**
```bash
which zoxide || echo "not installed"
grep -n zoxide ~/.common_shell
```

**Install:**
```bash
# Ubuntu/Debian
sudo apt install zoxide

# Arch
sudo pacman -S zoxide

# macOS
brew install zoxide

# Universal (requires Rust)
cargo install zoxide --locked
```

Open a new shell after installation for the `eval "$(zoxide init bash)"` to take effect.

---

### atuin `Ctrl+R` does nothing or shows the wrong UI

**Cause 1:** atuin is not installed or not initialised.
```bash
which atuin || echo "not installed"
grep -n atuin ~/.common_shell
```

**Cause 2:** The `eval "$(atuin init bash)"` line isn't being sourced, possibly because `.common_shell` has a syntax error above it.
```bash
bash -n ~/.common_shell   # syntax check
```

**Cause 3:** Another keybind is overriding `Ctrl+R` after atuin's init. Make sure `eval "$(atuin init bash)"` runs **after** all other readline/bind calls in `.common_shell`.

---

### Windows: PowerShell aliases not available

**Symptom:** `ll`, `v`, `g` etc. produce "command not found" errors in PowerShell.

**Diagnose:**
```powershell
$PROFILE                          # Print the profile path
Test-Path $PROFILE                # Should be True
Select-String "dotfiles" $PROFILE # Should find the dot-source line
```

**Fix if profile is missing or empty:**
```powershell
# Create it if needed
if (-not (Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }

# Add the dot-source line
Add-Content -Path $PROFILE -Value ". `"$HOME\dotfiles\windows\Microsoft.PowerShell_profile.ps1`""
```

Then open a new PowerShell window.

---

### Windows: symlinks fail with "requires elevation" or "not allowed"

**Cause:** Windows requires Administrator rights OR Developer Mode to create symlinks.

**Fix option 1 — Developer Mode (recommended, no elevation needed later):**
Settings → System → For Developers → Developer Mode → On

**Fix option 2 — Run as Administrator:**
Right-click Windows Terminal / PowerShell → Run as Administrator → re-run `install.ps1`

---

### `make test` reports a tool as missing despite it being installed

**Cause:** The tool is installed to a path not currently in `$PATH`.

**Diagnose:**
```bash
echo $PATH
which nvim 2>/dev/null || echo "not in PATH"
find ~/.local /usr/local /opt -name nvim 2>/dev/null   # find where it actually is
```

**Fix:** Add the tool's directory to `$PATH` in `~/.bash_local`:
```bash
export PATH="$PATH:/opt/some-tool/bin"
```

---

*For new tool additions or issues not covered here, open an issue at [github.com/deey001/dotfiles](https://github.com/deey001/dotfiles).*
