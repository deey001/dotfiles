# Bash Configuration Deep Audit & Improvement Plan

**Target:** ARM64 Ubuntu/Debian servers — headless, SSH-only  
**Stack:** bash + ble.sh + starship + atuin + carapace + fzf + zoxide  
**Scope:** `.bashrc`, `.bash_aliases`, `.bash_exports`, `.bash_functions`, `.bash_profile`, `.bash_wrappers`, `.blerc`, `.inputrc`

---

## Table of Contents

1. [Critical Bug Fixes (Issues 1–10)](#1-critical-bug-fixes)
2. [Additional Issues Found](#2-additional-issues-found)
3. [shopt Reference for Modern Bash](#3-shopt-reference)
4. [Performance Optimizations](#4-performance-optimizations)
5. [Security Improvements](#5-security-improvements)
6. [New Tools Worth Adding](#6-new-tools-worth-adding)
7. [Proposed .bashrc Rewrite — Full Structure](#7-proposed-bashrc-rewrite)
8. [zsh Migration Analysis](#8-zsh-migration-analysis)

---

## 1. Critical Bug Fixes

### Issue 1 — fastfetch runs twice on SSH login

**Root cause:** `.bash_profile` sources `.bashrc`. On an SSH login, `shopt -q login_shell` is true for that one shell. But if the user re-sources `.bashrc` manually (`source ~/.bashrc`), or if the system sources it a second time via `/etc/profile.d/` hooks, the guard re-fires because it only checks `login_shell` — which never changes in the same process.

More critically on some Ubuntu setups: `/etc/bash.bashrc` is sourced *before* `.bash_profile` by the SSH subsystem, causing `.bashrc` to be entered twice (once by the system, once by `.bash_profile`).

**Fix — exported session flag:**

```bash
# Guard fastfetch with an exported flag. The variable lives in the login shell's
# environment. Any re-sourcing of .bashrc within the SAME process is blocked by
# the flag. New SSH sessions get a clean environment, so fastfetch runs exactly once.
if command -v fastfetch >/dev/null 2>&1 \
    && shopt -q login_shell \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi
```

**Why `export`?** Exported vars propagate to child processes. If the user runs `bash -l` from within the SSH session, it inherits `_FASTFETCH_RAN=1` and skips fastfetch — which is the desired behaviour for nested login shells.

**Why not SHLVL?** tmux starts each pane as a fresh process where `SHLVL` resets to 1, making it unreliable as a "first login" indicator.

---

### Issue 2 — IS_ONLINE ping runs on every new shell

**Root cause:** `export IS_ONLINE` inside `.bashrc` is exported, but tmux panes are *children of the tmux server process*, not of the SSH login shell. They don't inherit the login shell's environment. So every pane runs `ping -c 1 8.8.8.8`.

**Fix — file cache with TTL:**

```bash
# Cache the connectivity check. Refreshes at most once every 5 minutes
# across ALL shells (tmux panes, subshells, etc.).
_online_cache="${HOME}/.cache/is_online"
mkdir -p "${HOME}/.cache"
if [[ ! -f "$_online_cache" ]] || \
   [[ -z "$(find "$_online_cache" -mmin -5 2>/dev/null)" ]]; then
    if ping -c 1 -W 1 8.8.8.8 &>/dev/null 2>&1; then
        echo 1 > "$_online_cache"
    else
        echo 0 > "$_online_cache"
    fi
fi
export IS_ONLINE=$(< "$_online_cache")
unset _online_cache
```

**Notes:**
- `-W 1` (1 second timeout vs default ~5s) makes the failure case fast
- `find -mmin -5` checks mtime without parsing `date` output — portable across Linux distros
- On an air-gapped server, the first shell of the day pays the 1s cost, all subsequent shells read the cache file instantly

---

### Issue 3 — bind commands conflict with ble.sh TAB handling

**Root cause:** After `source ~/.local/share/blesh/ble.sh --noattach`, `$BLE_VERSION` is set. The shell options section runs unconditionally, and `bind "TAB:menu-complete"` fights with ble.sh's TAB binding defined in `.blerc` (`ble-bind -m emacs -f 'TAB' 'menu-complete'`). Both try to own TAB, causing erratic behaviour in the completion menu.

**Fix — gate all bind calls behind a ble.sh check:**

```bash
# Only apply readline bind commands when ble.sh is NOT active.
# ble.sh replaces readline's completion UI entirely; these bind calls
# conflict with ble.sh's own bindings in .blerc.
if [[ -z "${BLE_VERSION-}" ]]; then
    bind "set completion-ignore-case on"          2>/dev/null
    bind "set show-all-if-ambiguous on"           2>/dev/null
    bind "TAB:menu-complete"                      2>/dev/null
    bind '"\e[Z":menu-complete-backward'          2>/dev/null
    bind "set menu-complete-display-prefix on"    2>/dev/null
    bind "set colored-stats on"                   2>/dev/null
    bind "set colored-completion-prefix on"       2>/dev/null
fi
```

Note: `BLE_VERSION` is set immediately when ble.sh is sourced with `--noattach`, so this check works at the point in `.bashrc` where shell options are configured.

The `.inputrc` settings (`completion-ignore-case on`, `colored-stats on`, etc.) still apply to readline even when ble.sh is active — only the `bind` *command-line calls* conflict.

---

### Issue 4 — PROMPT_COMMAND clobbers other tools

**Root cause:** `PROMPT_COMMAND='history -a'` (simple assignment) is set early. If starship or atuin also uses a simple assignment instead of the append pattern, one overwrites the other. More subtly: if `.bashrc` is re-sourced, `history -a` is re-set without the existing PROMPT_COMMAND content.

**Fix — always use the append/prepend pattern:**

```bash
# Prepend history -a, preserving any PROMPT_COMMAND set before this file loads
# (e.g., by /etc/bash.bashrc or GNOME Terminal's pre-exec hooks).
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
```

This makes `history -a` run *first*, then any previously registered commands run after. Starship and modern atuin already use this same pattern in their `init bash` output, so they will append correctly on top.

**For bash 5.1+ — array form (most robust):**

```bash
# Array form: each tool appends independently without string surgery.
# Requires all tools to support array PROMPT_COMMAND or to use += explicitly.
PROMPT_COMMAND=('history -a')
# Tools then do: PROMPT_COMMAND+=('starship_precmd')
```

The array form is safer but requires verifying that every tool (atuin, starship) handles it. Currently both tools support it as of their 2024 releases. Recommended for new setups.

---

### Issue 5 — Alias duplication (ls, grep, cat)

**Root cause:** The "Color Support" section in `.bashrc` sets:
```bash
alias ls='ls --color=auto'
alias grep='grep --color=auto'
```
Then immediately the "Aliases" section sets:
```bash
alias ls='eza --color=auto --icons'   # overwrites the above
```
And `.bash_aliases` *also* sets `grep --color=auto` and `cat=bat`.

**Fix — remove ls/grep/fgrep/egrep aliases from the color section:**

```bash
# Color Support section: ONLY set LS_COLORS via dircolors.
# Do NOT set aliases here — the Aliases section below handles all of them
# with proper tool-availability guards.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" \
        || eval "$(dircolors -b)"
fi
```

The aliases then live in ONE place (the Aliases section / `.bash_aliases`) with correct fallback ordering:

```bash
# ls: eza → ls --color (fallback)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -alF --icons'
    alias la='eza -A --icons'
    alias l='eza -CF --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# grep: always colorize
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
```

---

### Issue 6 — Missing glob options

```bash
# ── Glob & Pattern Matching ────────────────────────────────────────────────
shopt -s globstar    # **/*.sh matches recursively (zsh behavior)
shopt -s extglob     # !(*.txt), @(a|b), +(pattern) extended patterns
shopt -s nullglob    # unmatched glob expands to nothing instead of literal string
shopt -s cdspell     # auto-correct minor typos: "cd Dcouments" → "Documents"
shopt -s dirspell    # auto-correct typos in directory completion
shopt -s autocd      # type a directory name alone to cd into it (like zsh auto_cd)
shopt -s no_empty_cmd_completion  # don't attempt completion on an empty line (slow)
```

**Warning on `nullglob`:** Some scripts rely on `*` returning literally `*` when there's no match. In function bodies, consider toggling it:

```bash
some_function() {
    local -; shopt -s nullglob  # local to this function only (bash 4.4+)
    for f in *.conf; do ...     # safe: no match → empty loop, not *.conf
    done
}
```

**`autocd` note:** This conflicts with the `alias cd='z'` (zoxide). Remove `alias cd='z'` and use zoxide's `zi` for interactive fuzzy jump. Or set `alias cd='z'` and also keep `autocd` — they actually coexist fine because `autocd` invokes the `cd` builtin, which the alias replaces.

---

### Issue 7 — No direnv support

```bash
# direnv: per-directory .envrc files for project-level environment variables.
# Essential for managing multiple projects with different tool versions or secrets.
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi
```

Install on Ubuntu/Debian:
```bash
apt install direnv
# or: curl -sfL https://direnv.net/install.sh | bash
```

Usage: `echo 'export DATABASE_URL=...' >> .envrc && direnv allow`

---

### Issue 8 — IS_DOCKER broken on cgroupv2

**Root cause:** `grep -q docker /proc/1/cgroup` only works on cgroupv1. On cgroupv2 (Ubuntu 22.04+ default), `/proc/1/cgroup` contains just `0::/` with no "docker" string.

**Fix — multi-layer detection:**

```bash
_detect_container() {
    # Layer 1: Docker's own marker file (most reliable, always present in Docker)
    [[ -f /.dockerenv ]] && return 0
    # Layer 2: Podman's marker file
    [[ -f /run/.containerenv ]] && return 0
    # Layer 3: cgroupv1 legacy path (Docker on older kernels)
    grep -q 'docker\|lxc\|kubepods' /proc/1/cgroup 2>/dev/null && return 0
    # Layer 4: cgroupv2 — check if we are NOT the init process namespace
    # In a container, /proc/1/ns/pid differs from the host's PID namespace
    # systemd-detect-virt is the most reliable userspace check
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        systemd-detect-virt -q --container 2>/dev/null && return 0
    fi
    return 1
}
if _detect_container; then export IS_DOCKER=1; else export IS_DOCKER=0; fi
unset -f _detect_container
```

---

### Issue 9 — carapace `complete -r` order bug

**Root cause (reading the actual file):** The current `.bashrc` has:

```bash
source <(carapace _carapace bash)          # carapace registers: complete -F _carapace tmux
complete -r tmux git docker kubectl helm   # BUG: removes carapace's registrations!
```

The comment says "remove stale system completions" but the stale completions were already overwritten by carapace. `complete -r` here is *removing carapace's own completions*, leaving `tmux`, `git`, etc. with no completion handler.

**Fix — reverse the order:**

```bash
if command -v carapace >/dev/null 2>&1; then
    unset CARAPACE_BRIDGES
    # Remove system completions FIRST so carapace doesn't have to fight them.
    # bash-completion loaded above may have registered handlers for these tools.
    complete -r tmux git docker kubectl helm 2>/dev/null
    # Now carapace registers its own — these won't be removed.
    source <(carapace _carapace bash)
fi
```

**Deeper fix — cache carapace init (see §4 Performance).**

---

### Issue 10 — No CDPATH for quick navigation

```bash
# In .bash_exports — add after PATH setup
# CDPATH: colon-separated list of directories searched on `cd dirname`.
# The leading colon means "current directory first" (important — without it,
# `cd foo` won't find ./foo if another CDPATH dir also has a foo/).
export CDPATH=":${HOME}:${HOME}/projects:${HOME}/work:${HOME}/src"
```

With this, `cd dotfiles` from anywhere resolves to `~/projects/dotfiles` if that directory exists.

---

## 2. Additional Issues Found

### 2a — `alias find='fd'` is dangerous

fd has a completely different CLI interface from GNU find. Any script or muscle memory using `find -name "*.txt" -exec ...` will break. Use a different name:

```bash
# In .bash_aliases — rename, don't replace
if command -v fd >/dev/null 2>&1; then
    # Keep 'find' as GNU find. Use 'fd' or 'fdf' as the modern alias.
    alias fdf='fd'   # or just use 'fd' directly — it's installed as 'fd'
    alias oldfind='find'  # Remove alias find='fd' entirely
    unalias find 2>/dev/null
fi
```

Same applies to `alias ps='procs'` (procs has completely different flags) and `alias df='duf'` (duf has different output format). These break any script that calls those commands with standard flags. Recommendation: use `oldX` aliases for originals but keep the main commands pointing to system binaries. Use the modern tool aliases under new names.

### 2b — PATH appended instead of prepended in `.bash_exports`

```bash
# Current (system tools take priority — user tools are SHADOWED):
export PATH="$PATH:$HOME/bin:$HOME/.local/bin"

# Fix (user-installed tools take priority):
export PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
```

This matters when you install a newer `nvim` to `~/.local/bin/nvim` but `/usr/bin/nvim` is an older version. With the current setup, the old one runs. See §5 for full PATH ordering.

### 2c — rbenv init in `.bash_exports` runs on every shell

`eval "$(rbenv init -)"` forks a subprocess every shell startup (~50-100ms). Use lazy loading:

```bash
# In .bash_exports
if [ -d "${HOME}/.rbenv" ]; then
    export PATH="${HOME}/.rbenv/bin:${PATH}"
    export PATH="${HOME}/.rbenv/plugins/ruby-build/bin:${PATH}"
    # Lazy load: only init rbenv when first called
    rbenv() {
        unset -f rbenv
        eval "$(command rbenv init - bash)"
        rbenv "$@"
    }
fi
```

### 2d — `read()` wrapper defined in `.blerc` (FIXED)
The `read() { builtin read "$@" 2>/dev/null; }` workaround for bash 5.2 is defined in `.blerc`. This silences the "not a valid identifier" noise caused by older completion scripts in Bash 5.2+.

### 2e — atuin conflicts with ble.sh's Ctrl+R / Up arrow

atuin's default `init bash` hooks both Ctrl+R and Up arrow. ble.sh also owns Up arrow for history search. This creates a conflict where pressing Up gives inconsistent behavior depending on which hook fires first.

```bash
# In .bashrc, atuin init section:
if command -v atuin >/dev/null 2>&1; then
    if [[ -n "${BLE_VERSION-}" ]]; then
        # ble.sh is active: disable atuin's Up arrow binding.
        # Use Ctrl+R (or atuin's own binding) for history search.
        eval "$(atuin init bash --disable-up-arrow)"
    else
        eval "$(atuin init bash)"
    fi
fi
```

### 2f — Missing `cmdhist` and `lithist` for multiline commands

```bash
shopt -s cmdhist    # Save multiline commands as a single history entry
shopt -s lithist    # Preserve newlines in multiline history (not semicolons)
```

Without `cmdhist`, a multiline `for` loop gets saved as multiple disconnected entries in history, making it impossible to re-run.

### 2g — `HISTIGNORE` is not set

```bash
# Don't pollute history with noise commands
HISTIGNORE="ls:ll:la:l:cd:pwd:exit:clear:history:bg:fg:jobs:c:q"
```

### 2h — `HISTTIMEFORMAT` defined in `.bash_exports` but used by `.bashrc`

`HISTTIMEFORMAT` is a bash builtin variable. It should be set in `.bashrc` alongside the other `HIST*` variables, not in `.bash_exports`. Exports file should only contain variables needed by child processes.

### 2i — `color_prompt` variable is set but never used

```bash
case "$TERM" in xterm-color|*-256color) color_prompt=yes;; esac
```

`color_prompt` is set but nothing subsequently branches on it (since starship handles the prompt). Either use it to conditionally set a fallback PS1, or remove it.

### 2j — `whatsgoingon()` function uses `pushd`/`popd` without error handling

In `.bash_wrappers`, the `whatsgoingon` function does `pushd "$i" >/dev/null` without checking if the directory is accessible. On a server with NFS mounts or permission-restricted dirs, this can hang or produce confusing errors. Add error guard:

```bash
pushd "$i" >/dev/null 2>&1 || continue
```

### 2k — `distribution()` function uses `source /etc/os-release`

`source` (`.`) executes the file in the current shell. `/etc/os-release` contains variable assignments like `ID=ubuntu` that are safe, but also `PRETTY_NAME="Ubuntu 22.04.3 LTS"` which might shadow existing variables. Use a subshell:

```bash
distribution() {
    local dtype="unknown"
    if [ -r /etc/os-release ]; then
        local ID ID_LIKE
        # Read in subshell to avoid polluting current environment
        eval "$(grep -E '^(ID|ID_LIKE)=' /etc/os-release)"
        # ... rest of function
    fi
    echo "$dtype"
}
```

---

## 3. shopt Reference

Complete set of recommended shopt options for an interactive bash shell on Ubuntu/Debian ARM64 servers:

```bash
# ── History ───────────────────────────────────────────────────────────────────
shopt -s histappend     # append to history file, never overwrite (REQUIRED)
shopt -s cmdhist        # save multiline commands as one entry
shopt -s lithist        # preserve newlines in multiline history

# ── Globbing & Patterns ───────────────────────────────────────────────────────
shopt -s globstar       # **/*.sh recursive glob (like zsh)
shopt -s extglob        # !(*.txt) @(a|b) +(pattern) extended patterns
shopt -s nullglob       # unmatched globs → empty, not literal string
shopt -s cdspell        # cd Dcouments → Documents (typo correction)
shopt -s dirspell       # tab-complete directory names with typo tolerance

# ── Navigation ────────────────────────────────────────────────────────────────
shopt -s autocd         # type a directory path alone to cd into it
shopt -s cdable_vars    # cd VARNAME where VARNAME is a directory path variable

# ── Terminal ──────────────────────────────────────────────────────────────────
shopt -s checkwinsize   # update LINES/COLUMNS after each command (REQUIRED)

# ── Completion ────────────────────────────────────────────────────────────────
shopt -s no_empty_cmd_completion  # don't complete on empty line

# ── Misc ──────────────────────────────────────────────────────────────────────
shopt -s checkhash      # verify hashed command paths before using them
shopt -s hostcomplete   # complete hostnames after @

# NOT recommended:
# shopt -s dotglob      # globs match .files — breaks many scripts
# shopt -s failglob     # error on unmatched glob — too strict for interactive use
```

**zsh equivalents table:**

| zsh `setopt`       | bash `shopt`                     | Notes                                    |
|--------------------|----------------------------------|------------------------------------------|
| `globstar`         | `shopt -s globstar`              | Exact equivalent                         |
| `extendedglob`     | `shopt -s extglob`               | Similar, but syntax differs              |
| `nullglob`         | `shopt -s nullglob`              | Exact equivalent                         |
| `cdspell`          | `shopt -s cdspell`               | Exact equivalent                         |
| `autocd`           | `shopt -s autocd`                | Exact equivalent                         |
| `appendhistory`    | `shopt -s histappend`            | Exact equivalent                         |
| `histverify`       | `shopt -s histverify`            | Exact equivalent                         |
| `interactivecomments` | on by default in bash         | n/a                                      |
| `share_history`    | `bleopt history_share=1`         | ble.sh option, not shopt                 |
| `complete_in_word` | No direct equivalent             | carapace/ble.sh handle this              |
| `auto_menu`        | `bind "set menu-complete-display-prefix on"` | Readline only                |
| Global aliases     | ❌ No equivalent                 | zsh-exclusive feature                    |
| Suffix aliases     | ❌ No equivalent                 | zsh-exclusive feature                    |
| `zmv`              | ❌ No equivalent                 | Use `rename` or `mmv` on Linux           |
| `vared`            | ❌ No equivalent                 | ble.sh `ble-edit-str` is partial         |

---

## 4. Performance Optimizations

### Baseline profiling

Add this temporarily to the TOP of `.bashrc` to profile startup time:

```bash
# Profile bash startup: PS4 trick
# Uncomment, open a new shell, look at /tmp/bash_profile_$(date +%s).txt
# PS4='+ $(date "+%s%N") '
# exec 3>&2 2>/tmp/bash_startup_$(date +%s).txt
# set -x
```

Clean up profiling at the BOTTOM of `.bashrc`:
```bash
# { set +x; } 2>/dev/null; exec 2>&3 3>&-
```

Or use `bash -x -i -c exit 2>&1 | head -60` for a quick view.

### A — Cache slow `eval "$(tool init bash)"` calls

Each `eval "$(starship init bash)"`, `eval "$(atuin init bash)"`, `eval "$(zoxide init bash)"` forks a subprocess. On first run these are ~20-80ms each. Cache the output:

```bash
# Generic init caching function. Usage:
#   _cached_eval starship "starship init bash"
_cached_eval() {
    local name="$1"
    local cmd="$2"
    local cache="${HOME}/.cache/bash_init_${name}"
    local tool_path
    tool_path=$(command -v "$name" 2>/dev/null) || return 0
    # Regenerate cache if: missing, or tool binary is newer than cache
    if [[ ! -f "$cache" ]] || [[ "$tool_path" -nt "$cache" ]]; then
        eval "$cmd" > "$cache" 2>/dev/null
    fi
    source "$cache"
}

# Then replace:
#   eval "$(starship init bash)"    →  _cached_eval starship "starship init bash"
#   eval "$(zoxide init bash)"      →  _cached_eval zoxide "zoxide init bash"
#   eval "$(atuin init bash)"       →  _cached_eval atuin "atuin init bash --disable-up-arrow"
```

Note: carapace completions change frequently with tool updates, so cache invalidation by binary mtime is important.

### B — Cache carapace init output

`source <(carapace _carapace bash)` is a process substitution that forks carapace every shell startup. Cache it:

```bash
if command -v carapace >/dev/null 2>&1; then
    unset CARAPACE_BRIDGES
    complete -r tmux git docker kubectl helm 2>/dev/null
    _carapace_cache="${HOME}/.cache/carapace_init.bash"
    _carapace_bin=$(command -v carapace)
    if [[ ! -f "$_carapace_cache" ]] || [[ "$_carapace_bin" -nt "$_carapace_cache" ]]; then
        carapace _carapace bash > "$_carapace_cache" 2>/dev/null
    fi
    source "$_carapace_cache"
    unset _carapace_cache _carapace_bin
fi
```

### C — Lazy-load rbenv, pyenv, nvm

```bash
# Lazy rbenv: only fully initialized when first used
if [[ -d "${HOME}/.rbenv" ]]; then
    export PATH="${HOME}/.rbenv/bin:${PATH}"
    rbenv() {
        unset -f rbenv
        eval "$(command rbenv init - bash)"
        rbenv "$@"
    }
fi

# Lazy pyenv
if [[ -d "${HOME}/.pyenv" ]]; then
    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    pyenv() {
        unset -f pyenv
        eval "$(command pyenv init - bash)"
        pyenv "$@"
    }
fi
```

### D — Defer fastfetch output until after prompt is drawn

Instead of blocking shell startup with fastfetch, print it before the first prompt:

```bash
# Print fastfetch after first prompt draw using PROMPT_COMMAND one-shot
if command -v fastfetch >/dev/null 2>&1 \
    && shopt -q login_shell \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    # Use a one-shot PROMPT_COMMAND that prints fastfetch before first prompt,
    # then removes itself. This lets the shell appear instantly.
    _fastfetch_once() {
        fastfetch
        # Remove self from PROMPT_COMMAND
        PROMPT_COMMAND="${PROMPT_COMMAND//_fastfetch_once;/}"
        PROMPT_COMMAND="${PROMPT_COMMAND//_fastfetch_once/}"
        unset -f _fastfetch_once
    }
    PROMPT_COMMAND="_fastfetch_once${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
```

### E — Avoid `command -v` repeated checks

Cache tool paths in variables to avoid repeated forks:

```bash
# Pre-check tools once; use variables throughout
_HAS_EZA=0; _HAS_BAT=0; _HAS_FZF=0; _HAS_ZOXIDE=0
command -v eza     >/dev/null 2>&1 && _HAS_EZA=1
command -v bat     >/dev/null 2>&1 && _HAS_BAT=1
command -v batcat  >/dev/null 2>&1 && _HAS_BATCAT=1
command -v fzf     >/dev/null 2>&1 && _HAS_FZF=1
command -v zoxide  >/dev/null 2>&1 && _HAS_ZOXIDE=1

(( _HAS_EZA )) && alias ls='eza --color=auto --icons'
# etc.
unset _HAS_EZA _HAS_BAT _HAS_BATCAT _HAS_FZF _HAS_ZOXIDE
```

This saves one fork per `command -v` check. On a slow server with many tools, this can shave 20-50ms from startup.

---

## 5. Security Improvements

### PATH ordering

```bash
# BEFORE (system tools shadow user tools):
export PATH="$PATH:$HOME/bin:$HOME/.local/bin"

# AFTER (user tools take priority; system fallback preserved):
export PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
```

**Why this is safe:** Your `~/.local/bin` should have permissions `700` or `750`. If set correctly, only you can write there. This is standard XDG practice.

**PATH deduplication** (add to end of `.bash_exports`):

```bash
# Deduplicate PATH entries while preserving order.
# Re-sourcing .bashrc or .bash_exports won't accumulate duplicate paths.
if [[ -n "$PATH" ]]; then
    export PATH=$(awk -v RS=':' -v ORS=':' '!seen[$0]++' <<< "$PATH" | sed 's/:$//')
fi
```

### Secure `EDITOR` fallback chain

```bash
# Current has a subtle bug: 'which' can return nothing (empty string)
# if nvim isn't found, setting EDITOR="" which breaks many tools.
for _editor in nvim vim vi nano; do
    if command -v "$_editor" >/dev/null 2>&1; then
        export EDITOR="$_editor"
        export VISUAL="$_editor"
        break
    fi
done
unset _editor
```

### Don't export `IS_*` flags unnecessarily

`IS_SSH`, `IS_WSL`, `IS_DOCKER`, `IS_TMUX` don't need to be exported (they're not used by child processes). Use plain assignment:

```bash
# Only IS_ONLINE and IS_SSH need export if scripts reference them.
# IS_TMUX, IS_WSL, IS_DOCKER are shell-only; no need to pollute child envs.
[[ -n "${SSH_CLIENT:-}${SSH_TTY:-}" ]] && IS_SSH=1 || IS_SSH=0
# etc.
export IS_SSH  # Only this one, if you use it in tmux configs or scripts
```

---

## 6. New Tools Worth Adding

### mise (formerly rtx) — replaces rbenv + pyenv + nvm in one tool

```bash
# Install: curl https://mise.run | sh
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi
```

mise manages Node, Python, Ruby, Go, and 500+ other tools via `.mise.toml` or `.tool-versions` files. It's significantly faster than individual version managers (single binary, ~5ms activation). Highly recommended for servers where you need specific language versions per project.

### direnv — per-directory environment

```bash
# Install: apt install direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi
```

Creates `.envrc` files per project: `export DATABASE_URL=...`. Shell automatically loads/unloads on `cd`. Works with mise via `mise activate`.

### fzf improvements — better default command

```bash
# Use fd (or find) for fzf's file listing — respects .gitignore
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
```

### fzf key bindings additions

```bash
# fzf: Ctrl+T = file picker, Alt+C = cd picker, Ctrl+R = history (atuin or fzf)
# Add to FZF_DEFAULT_OPTS:
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --preview-window=right:50%:wrap"
```

### zoxide better integration

```bash
# Remove 'alias cd=z' approach — use zi for interactive fzf-powered jump
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
    # zi = interactive fuzzy cd (replaces 'alias ff')
    # z  = smart cd (frecency-based, use directly, don't alias cd to it)
    alias cdi='zi'   # mnemonic: cd interactive
fi
```

Keeping `cd` as the builtin prevents breakage when scripts call `cd` with standard flags (`cd -P`, `cd -L`).

### bat improvements

```bash
# Better bat configuration
if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then
    _bat=$(command -v bat 2>/dev/null || command -v batcat)
    alias cat="$_bat --paging=never"
    alias oldcat='/bin/cat'
    # bat for man pages (colored)
    export MANPAGER="sh -c 'col -bx | $bat -l man -p'"
    export MANROFFOPT="-c"
    unset _bat
fi
```

### History tooling verdict: Atuin > hstr > McFly for SSH servers

| Tool   | Sync | SQLite | ble.sh compat | Verdict                    |
|--------|------|--------|---------------|----------------------------|
| Atuin  | ✅   | ✅     | ✅ (with flag) | **Keep** — best overall    |
| hstr   | ❌   | ❌     | ✅            | **Remove** — Atuin replaces it |
| McFly  | ❌   | ✅     | ⚠️ conflicts  | Skip for SSH-primary setup |

Remove `hstr` alias — it's redundant when atuin is installed.

---

## 7. Proposed .bashrc Rewrite

Full structure with all fixes applied. Annotations explain each section's purpose and order.

```bash
# ==============================================================================
# .bashrc — Bash Configuration (interactive shells only)
# ==============================================================================
# Load order: .bash_profile → .bashrc → .bash_exports → .bash_aliases
#             → .bash_functions → .bash_wrappers → .bash_local → ble-attach
# ==============================================================================

# ── 1. Interactive-only guard ─────────────────────────────────────────────────
case $- in *i*) ;; *) return ;; esac

# ── 2. ble.sh early init (MUST be before everything that touches readline) ─────
# BLE_VERSION is set after this; used later to gate conflicting bind calls.
if [[ -f ~/.local/share/blesh/ble.sh ]] && [[ -t 1 ]]; then
    # read() wrapper: suppresses "not a valid identifier" errors on bash 5.2
    # (Defined here for early init; also in .blerc for the attach phase)
    if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 2) )); then
        read() { builtin read "$@" 2>/dev/null; }
    fi
    export BASH_COMPAT=5.1
    source ~/.local/share/blesh/ble.sh --noattach 2>/dev/null
fi

# ── 3. History settings ────────────────────────────────────────────────────────
HISTCONTROL=ignoredups:ignorespace   # Use erasedups only if you want dedup across all sessions
HISTSIZE=50000
HISTFILESIZE=100000
HISTIGNORE="ls:ll:la:l:cd:pwd:exit:clear:history:bg:fg:jobs:c:q:vi:vim"
shopt -s histappend   # never overwrite history file
shopt -s cmdhist      # multiline commands as one entry
shopt -s lithist      # preserve newlines (not semicolons) in multiline
# PROMPT_COMMAND: append pattern so starship/atuin can safely add their own hooks
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ── 4. Environment detection ───────────────────────────────────────────────────
[[ -n "${SSH_CLIENT:-}${SSH_TTY:-}" ]] && export IS_SSH=1 || export IS_SSH=0
grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null && export IS_WSL=1 || export IS_WSL=0
if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] \
   || grep -qE 'docker|lxc|kubepods' /proc/1/cgroup 2>/dev/null; then
    export IS_DOCKER=1
else
    export IS_DOCKER=0
fi
[[ -n "${TMUX:-}" ]] && export IS_TMUX=1 || export IS_TMUX=0

# ── 5. Connectivity check (cached, max one ping per 5 minutes) ─────────────────
_online_cache="${HOME}/.cache/is_online"
mkdir -p "${HOME}/.cache"
if [[ ! -f "$_online_cache" ]] || \
   [[ -z "$(find "$_online_cache" -mmin -5 2>/dev/null)" ]]; then
    ping -c 1 -W 1 8.8.8.8 &>/dev/null && echo 1 > "$_online_cache" \
                                        || echo 0 > "$_online_cache"
fi
export IS_ONLINE=$(< "$_online_cache")
unset _online_cache

# ── 6. Shell options ───────────────────────────────────────────────────────────
shopt -s checkwinsize           # keep LINES/COLUMNS accurate
shopt -s globstar               # **/*.sh recursive glob
shopt -s extglob                # !(*.txt) extended patterns
shopt -s nullglob               # unmatched glob → empty (not literal)
shopt -s cdspell                # typo correction for cd
shopt -s dirspell               # typo correction in tab-complete
shopt -s autocd                 # bare directory name → cd
shopt -s no_empty_cmd_completion
shopt -s checkhash              # verify hashed paths
stty -ixon 2>/dev/null          # enable Ctrl-S/Ctrl-Q for fzf

# ── 7. Readline bindings (only when ble.sh is NOT active) ─────────────────────
if [[ -z "${BLE_VERSION-}" ]]; then
    bind "set completion-ignore-case on"       2>/dev/null
    bind "set show-all-if-ambiguous on"        2>/dev/null
    bind "set menu-complete-display-prefix on" 2>/dev/null
    bind "set colored-stats on"                2>/dev/null
    bind "set colored-completion-prefix on"    2>/dev/null
    bind "TAB:menu-complete"                   2>/dev/null
    bind '"\e[Z":menu-complete-backward'       2>/dev/null
fi

# ── 8. Color & terminal setup ──────────────────────────────────────────────────
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
# dircolors: set LS_COLORS ONLY — aliases are set below
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ── 9. Aliases (single source of truth) ───────────────────────────────────────
# ls: eza → ls --color fallback
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -alF --icons --git'
    alias la='eza -A --icons'
    alias l='eza -CF --icons'
    alias tree='eza --tree --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi
# Always color grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ── 10. Source modular files ───────────────────────────────────────────────────
[[ -f ~/.bash_exports   ]] && source ~/.bash_exports
[[ -f ~/.bash_aliases   ]] && source ~/.bash_aliases
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
[[ -f ~/.bash_wrappers  ]] && source ~/.bash_wrappers

# ── 11. System bash-completion ────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# ── 12. Carapace (order matters: remove system completions FIRST, then register) ──
if command -v carapace >/dev/null 2>&1; then
    unset CARAPACE_BRIDGES
    # Remove system completions BEFORE carapace registers its own
    complete -r tmux git docker kubectl helm 2>/dev/null
    # Cache carapace init; regenerate only when binary changes
    _cc="${HOME}/.cache/carapace_init.bash"
    if [[ ! -f "$_cc" ]] || [[ "$(command -v carapace)" -nt "$_cc" ]]; then
        carapace _carapace bash > "$_cc" 2>/dev/null
    fi
    source "$_cc"; unset _cc
fi

# ── 13. fzf ────────────────────────────────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash 2>/dev/null)" || {
        [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] \
            && source /usr/share/doc/fzf/examples/key-bindings.bash
        [[ -f /usr/share/doc/fzf/examples/completion.bash ]] \
            && source /usr/share/doc/fzf/examples/completion.bash
    }
    export FZF_DEFAULT_OPTS="
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
        --layout=reverse --border --height=~40%
        --bind='ctrl-/:toggle-preview'"
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi

# ── 14. zoxide ────────────────────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)" 2>/dev/null
    alias cdi='zi'   # interactive fuzzy cd; keep 'cd' as the builtin
fi

# ── 15. Atuin (after fzf/zoxide so atuin's Ctrl+R takes priority) ─────────────
if command -v atuin >/dev/null 2>&1; then
    if [[ -n "${BLE_VERSION-}" ]]; then
        eval "$(atuin init bash --disable-up-arrow)"
    else
        eval "$(atuin init bash)"
    fi
fi

# ── 16. direnv ────────────────────────────────────────────────────────────────
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# ── 17. mise (language version manager) ───────────────────────────────────────
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

# ── 18. Starship prompt (MUST be after atuin and direnv) ─────────────────────
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ── 19. Local/private config ──────────────────────────────────────────────────
[[ -f ~/.bash_local ]] && source ~/.bash_local

# ── 20. Login summary (once per SSH session, not in tmux) ─────────────────────
if command -v fastfetch >/dev/null 2>&1 \
    && shopt -q login_shell \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi

# ── 21. ble.sh attach (MUST be last) ─────────────────────────────────────────
[[ ${BLE_VERSION-} ]] && ble-attach 2>/dev/null
```

---

## 8. zsh Migration Analysis

### Should you migrate headless SSH servers from bash to zsh?

**Short answer: No. Stay on bash for servers. Use zsh on workstations/dev laptops.**

### Argument for staying on bash (servers)

| Factor | Impact |
|--------|--------|
| `/bin/sh` on Ubuntu is `dash`, not bash — but system scripts and your dotfiles target bash | Consistency: bash everywhere |
| Default shell in `/etc/passwd` is bash for new Ubuntu accounts | Zero friction with sysadmin tools |
| All existing scripts, cron jobs, and `.sh` files target bash | No migration needed |
| ble.sh reproduces zsh's killer features (syntax highlighting, autosuggestions, fzf-tab equivalent via carapace) | Feature parity achieved |
| SSH sessions are short-lived; the interactive features zsh excels at matter less | Lower ROI |
| Ansible, Chef, and CM tools target bash | Operational consistency |

### Features zsh has that bash genuinely can't replicate

These are actual gaps, not just "use a different tool":

1. **Global aliases** — `alias -g L='| less'` allows `cat file L` anywhere in the pipeline. No bash equivalent.
2. **Suffix aliases** — `alias -s py=python` makes `./script.py` auto-run with python. No bash equivalent.
3. **`zmv`** — rename files with pattern matching: `zmv '(*).txt' '$1.md'`. Use `rename` on Linux as partial substitute.
4. **`zstyle` completion system** — per-context completion configuration (e.g., "show git branches with previews"). carapace partially compensates.
5. **Associative array syntax** — `declare -A` works in bash 4+, but zsh's `(( ))` and `${assoc[@]}` syntax is cleaner for complex data structures.
6. **`vared`** — interactive editing of shell variables. No bash equivalent; ble.sh `ble-edit-str` is a partial workaround.
7. **`autoload`** — lazy-load function files from `FPATH`. Bash requires manual sourcing.
8. **Completion `compdef`** — define completions per-function, per-alias cleanly.

### Features bash can replicate with the right tools

| zsh feature | bash + tools equivalent | Quality |
|-------------|------------------------|---------|
| Syntax highlighting | ble.sh | ✅ Excellent |
| Autosuggestions | ble.sh | ✅ Excellent |
| History substring search | atuin | ✅ Better (syncs) |
| fzf-tab dropdown | carapace + ble.sh | ✅ Good |
| `**` recursive globs | `shopt -s globstar` | ✅ Exact |
| `setopt autocd` | `shopt -s autocd` | ✅ Exact |
| `setopt nullglob` | `shopt -s nullglob` | ✅ Exact |
| Smart cd (frecency) | zoxide | ✅ Exact |
| Per-dir environment | direnv | ✅ Exact |
| Language versioning | mise | ✅ Better |
| Prompt theming | starship | ✅ Exact |

### Migration checklist (if you do decide to migrate a machine)

If you ever migrate a dev workstation to zsh as the primary shell:

- [ ] `chsh -s $(which zsh)` on the target machine
- [ ] Move ble.sh features to `zsh-syntax-highlighting` + `zsh-autosuggestions` + `zsh-history-substring-search`
- [ ] Replace carapace bash completion with carapace zsh (enable `CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'`)
- [ ] Replace `shopt -s autocd` with `setopt autocd`
- [ ] Replace `shopt -s globstar` with `setopt globstar` (zsh uses `**` by default)
- [ ] Replace `shopt -s nullglob` with `setopt nullglob`
- [ ] Replace `HISTCONTROL` with `setopt histignorespace histignorealldupes`
- [ ] Replace `PROMPT_COMMAND` with `precmd()` hook function
- [ ] Replace ble.sh TAB bindings with `fzf-tab` plugin
- [ ] Add `setopt share_history` (replaces `history_share=1` in ble.sh)
- [ ] Add `setopt hist_verify` (confirm before running history expansion)
- [ ] `.bash_aliases` and `.bash_functions` work in zsh unchanged (POSIX-compatible)
- [ ] Test all scripts for `[[ ]]` vs `[ ]` differences (zsh has subtle differences)
- [ ] Replace `shopt -s extglob` with `setopt extendedglob` (note: pattern syntax differs)
- [ ] Add `autoload -Uz compinit && compinit` for zsh completion init
- [ ] Keep bash as server shell — `SHELL=/bin/bash` in `.profile` for remote connections

### Verdict

**For this specific use case (headless ARM64 Ubuntu/Debian SSH servers):**

> Bash + ble.sh + atuin + carapace + starship gives you 95% of the zsh interactive experience with zero migration risk, no dependency on zsh being installed, and full compatibility with system tools. The 5% gap (global aliases, `zmv`, etc.) doesn't matter in a headless SSH context.

**Migrate zsh on:** dev laptops, macOS workstations, any machine where you do heavy interactive editing and want the full zsh plugin ecosystem (zinit/zplug/oh-my-zsh).

---

## Quick-win Checklist

Apply these in order — each is a self-contained change:

- [ ] **Fix IS_ONLINE cache** (Issue 2) — biggest startup speedup for tmux users
- [ ] **Fix carapace `complete -r` order** (Issue 9) — tmux/git/docker completions are currently broken
- [ ] **Fix PROMPT_COMMAND append pattern** (Issue 4) — prevents silent breakage with multiple tools
- [ ] **Gate bind calls behind BLE_VERSION check** (Issue 3) — stops ble.sh TAB fighting
- [ ] **Add exported `_FASTFETCH_RAN` guard** (Issue 1) — fixes double fastfetch
- [ ] **Add missing shopt options** (Issue 6) — `globstar`, `extglob`, `nullglob`, `autocd`, `cdspell`
- [ ] **Remove duplicate ls/grep aliases from color section** (Issue 5)
- [ ] **Fix carapace** ordering bug (Issue 9)
- [ ] **Add cgroupv2 Docker detection** (Issue 8)
- [ ] **Add CDPATH** (Issue 10)
- [ ] **Add `direnv hook bash`** (Issue 7)
- [ ] **Fix `alias find='fd'` → use `fdf` or `alias fdf='fd'`** (Issue 2a)
- [ ] **Prepend user bins in PATH** (Issue 2b)
- [ ] **Lazy-load rbenv** (Issue 2c)
- [ ] **Add `--disable-up-arrow` to atuin when ble.sh active** (Issue 2e)
- [x] **Consolidate `read()` wrapper in `.blerc`** (Issue 2d)
- [ ] **Add `shopt -s cmdhist lithist`** (Issue 2f)
- [ ] **Add `HISTIGNORE`** (Issue 2g)
- [ ] **Cache carapace/starship/zoxide init** (Performance §A–B)
- [ ] **Lazy-load version managers** (Performance §C)
