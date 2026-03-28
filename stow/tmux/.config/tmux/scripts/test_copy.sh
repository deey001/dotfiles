#!/bin/bash
# test_copy.sh
# Sends a test string to the system clipboard using OSC 52 escape sequences.

TEXT="Hello from the Server!"
echo "Attempting to copy: '$TEXT' to your client clipboard."

# OSC 52 sequence
# \033]52;c; -> Start OSC 52 copy to clipboard
# base64 data -> The text encoded
# \a -> Bell (End of sequence)

encoded=$(echo -n "$TEXT" | base64 | tr -d '\n')

echo "Method 1: Direct OSC 52 (Works if outside tmux)"
printf "\033]52;c;%s\a" "$encoded"
echo

echo "Method 2: Tmux Passthrough (Required inside tmux)"
# Wraps the sequence in \ePtmux;...\e\\
printf "\033Ptmux;\033\033]52;c;%s\007\033\\" "$encoded"

echo
echo "Done. Try pasting on Windows (Ctrl+V) now."
echo "If this worked, PuTTY is configured correctly."
echo "If this failed, PuTTY 'Allow terminal to access clipboard' is NOT working or supported."
