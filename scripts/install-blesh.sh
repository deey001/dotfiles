#!/bin/bash
# install-blesh.sh — Build and install ble.sh from latest master
# Usage: bash ~/dotfiles/scripts/install-blesh.sh
set -euo pipefail

REPO="https://github.com/akinomyoga/ble.sh.git"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Removing old ble.sh..."
rm -rf "$HOME/.local/share/blesh"

if ! command -v make >/dev/null 2>&1; then
    echo "Error: 'make' is required. Install with: sudo apt install make"
    exit 1
fi

echo "Cloning ble.sh master (with submodules)..."
git clone --recursive --depth 1 --shallow-submodules \
    "$REPO" "$TMPDIR/ble.sh"

echo "Building and installing to ~/.local..."
make -C "$TMPDIR/ble.sh" install PREFIX="$HOME/.local"

# ── bash 5.2 compatibility patch ──────────────────────────────────────────────
# bash 5.2 rejects empty variable names in 'read'. ble.sh b99cadb calls
# builtin read with empty var names from completion functions (no upstream fix).
# Patch the exact line in the installed file so the fix survives ble-attach.
#
# PRIMARY:   ble.sh line ~27744 — ble/builtin/read/.read-arguments
#   Adds [[ $arg ]] && guard before ble/array#push vars "$arg"
# SECONDARY: lib/core-complete.sh line ~2550 — limit-exceeded hook
#   Wraps ble/bash/read call to filter empty args from "$@"
echo "Applying bash 5.2 compatibility patch..."

_BLESH="$HOME/.local/share/blesh/ble.sh"
_COMPLETE="$HOME/.local/share/blesh/lib/core-complete.sh"

# Detect sed -i syntax (BSD/macOS requires '', GNU/Linux does not)
_SED_INPLACE=(-i)
if sed --version 2>/dev/null | grep -q GNU; then
    _SED_INPLACE=(-i)
else
    _SED_INPLACE=(-i '')
fi

# Patch 1: filter empty variable names in read argument parsing
if grep -qF 'ble/array#push vars "$arg"' "$_BLESH" 2>/dev/null; then
    sed "${_SED_INPLACE[@]}" \
        's/ble\/array#push vars "\$arg"/[[ $arg ]] \&\& ble\/array#push vars "$arg"/' \
        "$_BLESH"
    echo "  ✓ ble.sh patched: empty var guard added to .read-arguments"
else
    echo "  ✓ ble.sh: pattern not found (may already be fixed upstream)"
fi

# Patch 2: filter empty args in the limit-exceeded completion hook
if grep -qF 'ble/bash/read "$@" < /dev/null' "$_COMPLETE" 2>/dev/null; then
    sed "${_SED_INPLACE[@]}" \
        's|ble/bash/read "\$@" < /dev/null|local _fa=(); local _a; for _a in "$@"; do [[ $_a ]] \&\& _fa+=("$_a"); done; ble/bash/read "${_fa[@]}" < /dev/null|' \
        "$_COMPLETE"
    echo "  ✓ core-complete.sh patched: empty arg filter added to limit hook"
else
    echo "  ✓ core-complete.sh: pattern not found (may already be fixed upstream)"
fi

unset _BLESH _COMPLETE _SED_INPLACE

BLE_VER=$(grep -o "BLE_VERSION=[^ ;]*" "$HOME/.local/share/blesh/ble.sh" 2>/dev/null | head -1 || echo "unknown")
echo ""
echo "Done! Version: ${BLE_VER}"
echo "Run: exec bash && echo \$BLE_VERSION"
