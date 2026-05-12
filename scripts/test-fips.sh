#!/bin/bash
# ==============================================================================
# test-fips.sh — Blocklist gate for the FIPS 140-3 install path
# ==============================================================================
# Greps the FIPS-scoped files for tokens that name non-FIPS-approved
# cryptographic modules or tools that bundle them. Exits non-zero on any hit,
# printing every offending line so review is one cat away from a fix.
#
# SCOPE (only these paths — the non-FIPS dotfiles tree is intentionally
# excluded; FIPS users never deploy from it):
#   - home-fips/
#   - scripts/install-fips.sh
#   - scripts/test-fips.sh           (self-check; comments allow naming the
#                                     tokens we ban — see ALLOW_SELF below)
#   - platform/packages-fips.txt
#   - docs/FIPS.md                   (allowed to name banned tokens in prose;
#                                     guarded by ALLOW_DOC)
#
# USAGE:
#   bash scripts/test-fips.sh        # CI / make test-fips
#
# EXIT CODES:
#   0 — clean
#   1 — banned token present in scope
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Banned token list — extended regex. Add new entries as upstream FIPS guidance
# evolves. Use word-boundary anchors where short tokens would otherwise hit
# benign strings (e.g. "age" the cosmetic word vs. "age" the encryption tool).
BANNED='atuin|libsodium|xchacha[0-9-]*|chacha20-poly1305|argon2|ed25519|x25519|curve25519|\brage\b|\bage-encryption\b|cosign|sigstore|wireguard-tools'

# Files that legitimately reference banned tokens in prose/code and are
# therefore excluded from the grep gate. Keep this list short and explicit;
# every entry is an audit waiver.
ALLOW_SELF="scripts/test-fips.sh"
ALLOW_DOC="docs/FIPS.md"

scope_paths=(
    home-fips
    scripts/install-fips.sh
    platform/packages-fips.txt
)

# Build a single grep invocation: search the scope, exclude the waiver files
# and .git/, return non-zero on any match.
hits=$(grep -rEnI \
    --exclude-dir=.git \
    --exclude="$(basename "$ALLOW_SELF")" \
    --exclude="$(basename "$ALLOW_DOC")" \
    "$BANNED" \
    "${scope_paths[@]}" 2>/dev/null || true)

if [ -n "$hits" ]; then
    echo "FAIL: non-FIPS token present in FIPS scope" >&2
    echo "$hits" >&2
    exit 1
fi

echo "OK: no banned tokens in FIPS scope"
