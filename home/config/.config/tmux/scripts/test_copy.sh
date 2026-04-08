#!/bin/bash

# ==============================================================================
# test_copy.sh — OSC 52 Clipboard Test Utility
# ==============================================================================
# Sends a test string to the system clipboard using OSC 52 escape sequences.
# Use this script to verify that your terminal emulator supports OSC 52
# clipboard access, which is required for remote copy/paste over SSH.
#
# USAGE:
#   bash test_copy.sh
#   Then try pasting (Ctrl+V / Cmd+V) — you should see "Hello from the Server!"
#
# WHEN TO USE:
#   - After setting up a new terminal emulator (Alacritty, iTerm2, PuTTY, etc.)
#   - After configuring tmux's clipboard passthrough (allow-passthrough on)
#   - When debugging clipboard issues over SSH
#
# HOW IT WORKS:
#   OSC 52 is an ANSI escape sequence that tells the terminal emulator to
#   copy data to the system clipboard. The text is base64-encoded in the
#   escape sequence. Two methods are tried:
#     Method 1: Direct OSC 52 — works when running outside tmux
#     Method 2: DCS passthrough — wraps OSC 52 for use inside tmux
#
# DEPENDENCIES:
#   - base64 command (coreutils — available on virtually all Unix systems)
#   - A terminal that supports OSC 52 (Alacritty, iTerm2, WezTerm, kitty,
#     PuTTY with "Allow terminal to access clipboard" enabled)
#
# TERMINAL SUPPORT:
#   ✓ Alacritty, iTerm2, WezTerm, kitty, foot, Windows Terminal
#   ✓ PuTTY (needs "Allow terminal to access clipboard" in settings)
#   ✗ GNOME Terminal, Konsole (no OSC 52 support as of 2024)
# ==============================================================================

TEXT="Hello from the Server!"
echo "Attempting to copy: '$TEXT' to your client clipboard."

# Base64-encode the text for embedding in the OSC 52 escape sequence
# tr -d '\n' strips any newline that base64 might add for line wrapping
encoded=$(echo -n "$TEXT" | base64 | tr -d '\n')

# Method 1: Direct OSC 52 — works when NOT inside tmux
# Sequence: ESC ] 52 ; c ; <base64-data> BEL
#   ESC ]   = OSC (Operating System Command) introducer
#   52      = clipboard operation
#   c       = clipboard target (system clipboard)
#   BEL (\a) = sequence terminator
echo "Method 1: Direct OSC 52 (Works if outside tmux)"
printf "\033]52;c;%s\a" "$encoded"
echo

# Method 2: DCS passthrough — required when running INSIDE tmux
# Wraps the OSC 52 sequence in tmux's DCS (Device Control String) passthrough
# so the escape sequence reaches the outer terminal instead of being consumed by tmux
# Sequence: ESC P tmux; ESC ESC ] 52 ; c ; <base64-data> BEL ESC \
echo "Method 2: Tmux Passthrough (Required inside tmux)"
printf "\033Ptmux;\033\033]52;c;%s\007\033\\" "$encoded"

echo
echo "Done. Try pasting on Windows (Ctrl+V) now."
echo "If this worked, PuTTY is configured correctly."
echo "If this failed, PuTTY 'Allow terminal to access clipboard' is NOT working or supported."
