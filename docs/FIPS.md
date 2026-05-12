# FIPS 140-3 Install Path

This dotfiles repository contains two parallel install trees:

| Path | Scope | Audience |
|------|-------|----------|
| `home/` + `scripts/install.sh` | Multi-distro, multi-shell, cosmetic | General use |
| `home-fips/` + `scripts/install-fips.sh` | Oracle Linux 9.x, bash-only, audited | FIPS 140-3 hosts |

The two trees are mutually exclusive on a host. `install-fips.sh` unstows the
non-FIPS tree before stowing the FIPS tree.

## Scope statement

The FIPS path is deployed on hosts where `/proc/sys/crypto/fips_enabled` reads
`1` and the OS is Oracle Linux 9.x. Only Oracle Linux 9.x is supported because
it is the only FOSS distribution shipping a FIPS 140-3 validated
cryptographic module at the time of writing (Ubuntu Pro FIPS, RHEL FIPS,
SUSE FIPS all require paid subscriptions).

The dotfiles themselves do not perform cryptography. Compliance comes from:

1. The host kernel running with the FIPS module enforcing.
2. The host's system OpenSSL / NSS / GnuTLS being the FIPS-validated build.
3. Every tool the dotfiles install using the host's system libcrypto for any
   TLS, signing, or hashing — never bundling its own cipher implementation.

The blocklist below enumerates tools that violate point 3.

## Blocklist (refused by `scripts/test-fips.sh`)

Tools and tokens that ship their own non-FIPS cryptographic module. If any
appears in `home-fips/`, `scripts/install-fips.sh`, or
`platform/packages-fips.txt`, the install refuses to run.

| Token | Why blocked |
|-------|-------------|
| `atuin` | Encrypts the local history DB with XChaCha20-Poly1305 + Argon2id (libsodium). |
| `libsodium` | Library implementing ChaCha20-Poly1305, Curve25519, Argon2 — none on the FIPS 140-3 approved list. |
| `xchacha20`, `chacha20-poly1305` | Stream cipher families outside FIPS approval. |
| `argon2` | Memory-hard KDF; not on the FIPS-approved KDF list (PBKDF2/HKDF are). |
| `ed25519`, `x25519`, `curve25519` | Edwards-curve / Montgomery-curve primitives; FIPS 186-5 approves ECDSA on P-256/P-384/P-521 and EdDSA only as of 2023 with strict parameter restrictions — we choose ECDSA P-256 by default to stay within the safest interpretation. |
| `age`, `rage` | File encryption tools built on X25519 + ChaCha20-Poly1305. |
| `cosign`, `sigstore` | Default to Ed25519 signing keys. |
| `wireguard-tools` | Protocol is Curve25519 + ChaCha20-Poly1305 — not FIPS-approved transport. |

## Allowlist (FIPS path tools)

Every tool below performs no cryptography of its own, or delegates all
cryptography to the host's FIPS-validated system libraries. Confirmed at the
versions shipped in Oracle Linux 9.x base + AppStream + EPEL unless noted.

| Tool | Role | Crypto source |
|------|------|---------------|
| `bash`, `readline`, `bash-completion` | Shell + line editing + completions | None |
| `ble.sh` (pinned to `v0.4.0-devel3`) | Bash predictive text + syntax highlight | Pure bash; none |
| `tmux` | Terminal multiplexer | None |
| `neovim` (`>= 0.11.2`, installed via GitHub release tarball) | Editor | None (Lua); plugin manager `git`/`curl` use system libcrypto |
| `starship` (single static binary from upstream) | Prompt | None |
| `git`, `curl`, `openssh-clients` (distro packages) | VCS, HTTP, SSH | System OpenSSL FIPS module |
| `fzf`, `ripgrep`, `fd-find`, `bat`, `eza`, `zoxide`, `direnv`, `git-delta` | Modern CLI replacements | None |

## Install verification

Run on the target host after `bash scripts/install-fips.sh`:

```bash
# 1. Confirm FIPS kernel mode
cat /proc/sys/crypto/fips_enabled                   # must print 1

# 2. Confirm OpenSSL is the FIPS-validated build
openssl version                                      # version + "FIPS"
openssl list -providers | grep -i fips               # 'fips' provider active

# 3. Confirm no banned tokens leaked into the deployed tree
bash scripts/test-fips.sh                            # 'OK: no banned tokens...'

# 4. Confirm shell start performs no network calls
strace -e trace=network -f bash -lc exit 2>&1 | \
    grep -v 'AF_UNIX' | grep -E 'connect|sendto|recvfrom' && \
    echo "FAIL: network traffic on shell start" || echo "OK: silent"
```

## Update procedure

1. Pull from upstream: `git pull && git submodule update --init --recursive`.
2. Re-run `bash scripts/test-fips.sh` before deploy — refuses if any new
   banned token entered the scope.
3. Re-run `bash scripts/install-fips.sh`. Stow is idempotent.

Any new tool added to `home-fips/` or `platform/packages-fips.txt` must be
appended to the Allowlist above with its crypto-source justification.
