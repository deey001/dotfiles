#!/bin/bash
# ==============================================================================
# yank.sh — Cross-platform tmux clipboard helper
# ==============================================================================
# Reads selected text from stdin (via tmux copy-pipe) and copies it to the
# system clipboard. Tries native tools first, then falls back to OSC 52.
#
# USAGE (in .tmux.conf):
#   bind -T copy-mode-vi y copy-pipe-and-cancel "~/.config/tmux/scripts/yank.sh"
# ==============================================================================

buf=$(cat)

# --- Try native clipboard tools first ----------------------------------------
if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$buf" | pbcopy
    exit 0
elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$buf" | xclip -selection clipboard
    exit 0
elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$buf" | xsel --clipboard --input
    exit 0
elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$buf" | wl-copy
    exit 0
fi

# --- Fallback: OSC 52 escape sequence ----------------------------------------
# Works over SSH if the terminal supports it (Alacritty, iTerm2, WezTerm, etc.)
encoded=$(printf '%s' "$buf" | base64 | tr -d '\n')

# Method 1: Write directly to the tmux client's TTY
# This bypasses the pane PTY and reaches the actual terminal.
if command -v tmux >/dev/null 2>&1; then
    client_tty=$(tmux display-message -p '#{client_tty}' 2>/dev/null)
    if [ -n "$client_tty" ] && [ -w "$client_tty" ]; then
        printf '\033]52;c;%s\a' "$encoded" > "$client_tty"
        exit 0
    fi
fi

# Method 2: Use DCS passthrough (works in older tmux versions)
# Wraps OSC 52 in tmux's DCS passthrough so it reaches the terminal.
if [ -n "${TMUX:-}" ]; then
    printf '\033Ptmux;\033\033]52;c;%s\007\033\\' "$encoded" > /dev/tty 2>/dev/null
    exit 0
fi

# Method 3: Direct to /dev/tty (works outside tmux, e.g. plain SSH)
printf '\033]52;c;%s\a' "$encoded" > /dev/tty 2>/dev/null
