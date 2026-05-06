# Keybinding Reference

## Readline (Bash + readline programs)

Configured in `.inputrc`. Also applies to python REPL, psql, gdb, etc.

### Navigation
| Key | Action |
|-----|--------|
| Ctrl+A | Beginning of line |
| Ctrl+E | End of line |
| Alt+B / Alt+Left | Back one word |
| Alt+F / Alt+Right | Forward one word |
| Ctrl+Left / Ctrl+Right | Forward/back one word |

### Editing
| Key | Action |
|-----|--------|
| Ctrl+K | Delete to end of line |
| Ctrl+U | Delete to beginning of line |
| Ctrl+W | Delete to previous slash (path-aware) |
| Alt+Backspace | Delete previous word (word-aware) |
| Alt+D | Delete word after cursor |
| Ctrl+L | Clear screen |
| Ctrl+X Ctrl+E | Open command in $EDITOR |

### History
| Key | Action |
|-----|--------|
| Up / Down | Search history by typed prefix |
| Ctrl+Up / Ctrl+Down | Sequential history (ignores prefix) |
| Ctrl+R | Reverse search (Bash/Zsh built-in; hstr if installed) |
| Alt+. | Insert last argument from previous command |

### Completion
| Key | Action |
|-----|--------|
| TAB | Cycle through completions |
| Shift+TAB | Cycle backwards |

## Tmux (Prefix: Ctrl+a)

### Panes
| Key | Action |
|-----|--------|
| Prefix + \\ / v | Split vertical (side-by-side) |
| Prefix + - / s | Split horizontal (stacked) |
| Prefix + h/j/k/l | Navigate panes (vim-style) |
| Alt+Arrow | Navigate panes (no prefix needed) |
| Prefix + Shift+Arrow | Resize pane (5 cells) |
| Prefix + H / L | Resize pane (20 cells) |
| Prefix + S | Toggle synchronized panes |

### Windows & Sessions
| Key | Action |
|-----|--------|
| Prefix + , | Rename window |
| Prefix + o | Session switcher (tmux-sessionx + zoxide) |
| Prefix + p | Floating terminal (tmux-floax) |
| Prefix + r | Reload config |

### Copy Mode (vi keys)
| Key | Action |
|-----|--------|
| Prefix + [ | Enter copy mode |
| v | Begin selection |
| y / Enter | Yank selection (via yank.sh) |
| Mouse drag | Auto-yank on release |

### Mouse & Plugins
| Key | Action |
|-----|--------|
| Prefix + m / M | Mouse ON / OFF |
| Prefix + I | Install TPM plugins |
| Prefix + U | Update TPM plugins |
| Prefix + u | Extract/open URLs from pane (fzf-url) |

## Neovim (LazyVim)

Full defaults: https://www.lazyvim.org/keymaps

### Most-used
| Key | Action |
|-----|--------|
| \<leader\>e | File explorer |
| \<leader\>\<leader\> | Find files |
| \<leader\>/ | Live grep |
| \<leader\>bb | Switch buffers |
| \<leader\>bd | Delete buffer |
| \<leader\>gg | Lazygit |
| \<leader\>z | Zen mode (custom) |
| \<leader\>n | Notification history (custom) |
| \<leader\>xx | Diagnostics (Trouble) |
| K | Hover documentation |
| gd / gr / gI | Go to definition / references / implementation |
| \<leader\>cf | Format document |
| \<leader\>cr | Rename symbol |
| \<leader\>ca | Code action |
| ]d / [d | Next/prev diagnostic |
| ]b / [b | Next/prev buffer |
| :w!! | Sudo save (custom) |

## Shell Aliases

### Navigation
`..`, `...`, `....`, `.....` — cd up N levels |
`-` — previous directory | `dc` — typo corrector for `cd`

### Git
`ga` add | `gst` status | `gd` diff | `gc` commit -m | `gp` push |
`gl` pull | `gco` checkout | `glog` log graph | `gti` typo corrector

### Editors
`v`, `vi`, `vim` — all open nvim

### Modern tool replacements (when installed)
`ls/ll/la/l/tree` eza | `cat` bat | `top` btop | `duu` dust |
`dff` duf | `prc` procs | `http` xh | `diff` colordiff

### Quick
`c` clear | `q` exit | `da` formatted date | `mkdir` with -p
