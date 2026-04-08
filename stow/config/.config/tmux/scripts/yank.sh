#!/bin/bash
# ==============================================================================
# yank.sh — Cross-platform tmux clipboard helper
# ==============================================================================
# Reads selected text from stdin (via tmux copy-pipe) and copies it to the
# system clipboard. Tries native tools first, then falls back to OSC 52.
#
# USAGE (in .tmux.conf):
#   bind -T copy-mode-vi y copy-pipe-and-cancel "~/.config/tmux/scripts/yank.sh"
#
# HOW IT WORKS:
#   1. Reads all of stdin into a buffer (tmux pipes the selected text here)
#   2. Tries native clipboard tools in order: pbcopy → xclip → xsel → wl-copy
#   3. If no native tool is available, falls back to OSC 52 escape sequences
#      which work over SSH if the terminal emulator supports them
#
# CLIPBOARD TOOL PRIORITY:
#   pbcopy   — macOS (always available)
#   xclip    — X11 Linux (install: apt install xclip)
#   xsel     — X11 Linux alternative (install: apt install xsel)
#   wl-copy  — Wayland Linux (install: apt install wl-clipboard)
#   OSC 52   — Universal fallback (requires terminal support)
#
# OSC 52 FALLBACK METHODS (tried in order):
#   Method 1: Write directly to tmux client's TTY (most reliable in tmux 3.2+)
#   Method 2: DCS passthrough via /dev/tty (for older tmux versions)
#   Method 3: Direct to /dev/tty (works outside tmux, e.g., plain SSH)
#
# DEPENDENCIES:
#   Required: base64 (coreutils), cat
#   Optional: pbcopy, xclip, xsel, wl-copy, tmux (for client_tty detection)
#
# ERROR HANDLING:
#   - Each method exits immediately on success (exit 0)
#   - If all methods fail, the script exits silently (no error message)
#   - The final /dev/tty write has 2>/dev/null to suppress errors on headless systems
# ==============================================================================

# Read the entire selection from stdin into a buffer
buf=$(cat)

# --- Try native clipboard tools first ----------------------------------------
# Each tool is checked with `command -v` for portability (no `which`)

# macOS — pbcopy is always available on macOS
if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$buf" | pbcopy
    exit 0
# X11 Linux — xclip copies to the CLIPBOARD selection (not PRIMARY)
elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$buf" | xclip -selection clipboard
    exit 0
# X11 Linux alternative — xsel with --clipboard flag
elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$buf" | xsel --clipboard --input
    exit 0
# Wayland Linux — wl-copy from wl-clipboard package
elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$buf" | wl-copy
    exit 0
fi

# --- Fallback: OSC 52 escape sequence ----------------------------------------
# Works over SSH if the terminal supports it (Alacritty, iTerm2, WezTerm, etc.)
# Base64-encode the text; strip newlines to form a single-line payload
encoded=$(printf '%s' "$buf" | base64 | tr -d '\n')

# Method 1: Write directly to the tmux client's TTY device
# This bypasses the pane's pseudo-terminal and sends the escape sequence
# straight to the real terminal, which is the most reliable approach
if command -v tmux >/dev/null 2>&1; then
    client_tty=$(tmux display-message -p '#{client_tty}' 2>/dev/null)
    if [ -n "$client_tty" ] && [ -w "$client_tty" ]; then
        printf '\033]52;c;%s\a' "$encoded" > "$client_tty"
        exit 0
    fi
fi

# Method 2: DCS passthrough for older tmux versions (< 3.2)
# Wraps OSC 52 in tmux's Device Control String so it reaches the outer terminal
# Only used when we're inside tmux (TMUX env var is set)
if [ -n "${TMUX:-}" ]; then
    printf '\033Ptmux;\033\033]52;c;%s\007\033\\' "$encoded" > /dev/tty 2>/dev/null
    exit 0
fi

# Method 3: Direct to /dev/tty — works outside tmux (plain SSH sessions)
printf '\033]52;c;%s\a' "$encoded" > /dev/tty 2>/dev/null
