#!/bin/bash
# ==============================================================================
# install-fips.sh — Oracle Linux 9.x FIPS 140-3 install path
# ==============================================================================
# Deploys the FIPS-scoped dotfiles tree (home-fips/) on a FIPS-validated host.
# Refuses to run anywhere else.
#
# WHAT IT DOES (phase 1 stub — gates only; package + stow + tool installs
# arrive in later phases):
#   1. Verifies the host has the FIPS kernel module enabled.
#   2. Verifies the host is Oracle Linux 9.x (the only FOSS distro shipping
#      a FIPS 140-3 validated crypto module at the time of writing).
#   3. Runs scripts/test-fips.sh — fails closed if any banned crypto token is
#      present in the FIPS-scoped files.
#   4. Removes any non-FIPS dotfiles stow links so the two trees can't
#      co-exist on the same host.
#   5. Stows home-fips/ into $HOME.
#
# USAGE:
#   sudo dnf install -y stow git
#   bash scripts/install-fips.sh
#
# EXIT CODES:
#   0 — install succeeded
#   1 — gate failure (not FIPS, wrong distro, or banned token present)
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── 1. FIPS kernel mode check ─────────────────────────────────────────────────
# /proc/sys/crypto/fips_enabled is the canonical kernel-side indicator.
# 1 = FIPS module loaded and enforcing. 0 or missing = non-FIPS kernel.
fips_file=/proc/sys/crypto/fips_enabled
if [ ! -r "$fips_file" ] || [ "$(cat "$fips_file")" != "1" ]; then
    echo "FAIL: kernel FIPS mode not active." >&2
    echo "  /proc/sys/crypto/fips_enabled must read '1'." >&2
    echo "  Oracle Linux 9: 'fips-mode-setup --enable' + reboot." >&2
    exit 1
fi

# ── 2. Distro check (Oracle Linux 9.x only) ───────────────────────────────────
# Only one FOSS distro currently ships a FIPS 140-3 validated module. Reject
# anything else so we don't ship a half-compliant config.
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}:${VERSION_ID:-}" in
        ol:9*|"oraclelinux:9"*) ;;
        *)
            echo "FAIL: unsupported distro for FIPS install: ${ID:-unknown} ${VERSION_ID:-?}" >&2
            echo "  Supported: Oracle Linux 9.x" >&2
            exit 1
            ;;
    esac
else
    echo "FAIL: /etc/os-release missing — cannot identify distro." >&2
    exit 1
fi

# ── 3. Repo blocklist gate ────────────────────────────────────────────────────
# Refuse to deploy if any banned crypto token leaked into the FIPS scope.
bash "$DOTFILES_DIR/scripts/test-fips.sh"

# ── 4. Drop the non-FIPS tree if it is currently stowed ───────────────────────
# We never want both trees overlaying $HOME — the non-FIPS one carries
# tools/configs the FIPS gate just rejected.
if command -v stow >/dev/null 2>&1 && [ -d "$DOTFILES_DIR/home" ]; then
    echo "--- Unstowing non-FIPS tree (home/) if present ---"
    stow -D --dir="$DOTFILES_DIR" --target="$HOME" home 2>/dev/null || true
fi

# ── 5. Stow the FIPS tree ─────────────────────────────────────────────────────
# Phase 1 stub: the tree is a placeholder (.gitkeep only). Later phases will
# populate .bashrc, tmux.conf, etc. The stow call is wired in now so the
# end-to-end flow can be smoke-tested as content lands.
if ! command -v stow >/dev/null 2>&1; then
    echo "Installing GNU Stow..."
    sudo dnf install -y stow
fi

echo "--- Stowing FIPS tree (home-fips/) ---"
stow -R --dir="$DOTFILES_DIR" --target="$HOME" home-fips

echo "======================================================================"
echo "FIPS install (phase 1 skeleton) finished."
echo "Next phases: bashrc + ble.sh + tmux + nvim + starship + packages."
echo "======================================================================"
