# ==============================================================================
# .bash_functions — Custom Shell Functions
# ==============================================================================
# Sourced by: .bashrc (after .bash_exports and .bash_aliases)
# Purpose:    Reusable utility functions for file management, navigation,
#             archive handling, system info, and fuzzy finding.
#
# Dependencies:
#   - fzf (required by fcd, fv, fp)
#   - nvim (required by fv)
#   - pbcopy or xclip (required by fp for clipboard support)
#
# Convention: Functions that cd into a directory have a 'g' suffix (mkdirg,
#             cpg, mvg) to distinguish them from their standard counterparts.
# ==============================================================================

# ── Archive extraction ─────────────────────────────────────────────────────────

# extract — Universal archive extractor
# Usage:   extract file1.tar.gz file2.zip file3.7z
# Params:  $@ — one or more archive file paths
# Returns: Extracts each archive in-place; prints error for unknown types
extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case $archive in
                *.tar.bz2) tar xvjf "$archive" ;;
                *.tar.gz) tar xvzf "$archive" ;;
                *.bz2) bunzip2 "$archive" ;;
                *.rar) rar x "$archive" ;;
                *.gz) gunzip "$archive" ;;
                *.tar) tar xvf "$archive" ;;
                *.tbz2) tar xvjf "$archive" ;;
                *.tgz) tar xvzf "$archive" ;;
                *.zip) unzip "$archive" ;;
                *.Z) uncompress "$archive" ;;
                *.7z) 7z x "$archive" ;;
                *) echo "don't know how to extract '$archive'..." ;;
            esac
        else
            echo "'$archive' is not a valid file!"
        fi
    done
}

# ── Text search ────────────────────────────────────────────────────────────────

# ftext — Search for text in all files under CWD (recursive grep with pager)
# Usage:   ftext "TODO"
# Params:  $1 — search pattern (passed to grep)
# Returns: Colorized matches piped through less for pagination
ftext() {
    # -i case-insensitive
    # -I ignore binary files
    # -H causes filename to be printed
    # -r recursive search
    # -n causes line number to be printed
    grep -iIHrn --color=always "$1" . | less -r
}

# ── Directory creation & navigation ────────────────────────────────────────────

# mkdirg — Create directory (with parents) and cd into it
# Usage:   mkdirg my/new/project
# Params:  $1 — directory path to create
mkdirg() {
    mkdir -p "$1"
    cd "$1"
}

# cpg — Copy file to a directory and cd into that directory
# Usage:   cpg config.yaml /etc/myapp/
# Params:  $1 — source file, $2 — destination (file or directory)
# Note:    Only cd's if $2 is an existing directory; otherwise plain copy
cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# mvg — Move file to a directory and cd into that directory
# Usage:   mvg report.pdf ~/Documents/
# Params:  $1 — source file, $2 — destination (file or directory)
# Note:    Only cd's if $2 is an existing directory; otherwise plain move
mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# up — Go up N directories (e.g., `up 3` is equivalent to `cd ../../..`)
# Usage:   up 3
# Params:  $1 — number of levels to ascend (defaults to 1 if omitted)
up() {
    local d=""
    limit=$1
    for ((i = 1; i <= limit; i++)); do
        d=$d/..
    done
    d=$(echo $d | sed 's/^\///')      # Strip leading slash for relative path
    if [ -z "$d" ]; then
        d=..                          # Default to one level up
    fi
    cd $d
}

# ── Path utilities ─────────────────────────────────────────────────────────────

# pwdtail — Returns the last 2 path components of the working directory
# Usage:   pwdtail  →  "projects/myapp"
# Returns: Echoes "parent/current" to stdout (useful in prompts or scripts)
pwdtail() {
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# ── System information ─────────────────────────────────────────────────────────

# ver — Show the current OS version, dispatched by distribution family
# Usage:   ver
# Returns: Prints distro-specific version info to stdout
# Depends: distribution() function below
ver() {
    local dtype
    dtype=$(distribution)

    case $dtype in
        "redhat")
            if [ -s /etc/redhat-release ]; then
                cat /etc/redhat-release
            else
                cat /etc/issue
            fi
            uname -a
            ;;
        "debian")
            lsb_release -a
            ;;
        "arch")
            cat /etc/os-release
            ;;
        *)
            if [ -s /etc/issue ]; then
                cat /etc/issue
            else
                echo "Error: Unknown distribution"
                exit 1
            fi
            ;;
    esac
}

# distribution — Detect the current Linux distribution family
# Usage:   distribution  →  "debian" | "redhat" | "arch" | "unknown"
# Returns: Echoes one of: "redhat", "debian", "arch", "unknown"
# Note:    Also defined in .bashrc — kept here so functions file is self-contained
distribution() {
    local dtype="unknown"

    # Parse /etc/os-release (systemd standard, available on all modern distros)
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            fedora|rhel|centos)
                dtype="redhat"
                ;;
            ubuntu|debian)
                dtype="debian"
                ;;
            arch|manjaro)
                dtype="arch"
                ;;
            *)
                # Fallback: check ID_LIKE for derivative distros (e.g., Rocky, Pop!_OS)
                if [ -n "$ID_LIKE" ]; then
                    case $ID_LIKE in
                        *fedora*|*rhel*|*centos*)
                            dtype="redhat"
                            ;;
                        *ubuntu*|*debian*)
                            dtype="debian"
                            ;;
                        *arch*)
                            dtype="arch"
                            ;;
                    esac
                fi
                ;;
        esac
    fi

    echo $dtype
}

# ── Fuzzy finding (requires fzf) ──────────────────────────────────────────────

# fcd — Fuzzy find a directory under CWD and cd into it
# Usage:   fcd  →  interactive fzf picker → cd into selection
# Depends: fzf
# Note:    Hidden directories (.*) are excluded to keep results clean
fcd() {
    local dir
    dir=$(find . -type d -not -path '*/.*' 2>/dev/null | fzf +m) && cd "$dir"
}

# fv — Fuzzy find a file under CWD and open it in Neovim
# Usage:   fv  →  interactive fzf picker → opens in nvim
# Depends: fzf, nvim
fv() {
    local file
    file=$(find . -type f -not -path '*/.*' 2>/dev/null | fzf +m) && nvim "$file"
}

# fp — Fuzzy find a file and copy its path to the system clipboard
# Usage:   fp  →  interactive fzf picker → path copied to clipboard
# Depends: fzf, pbcopy (macOS) or xclip (Linux)
# Note:    Cross-platform clipboard via `command -v` guard chain
fp() {
    local file
    file=$(find . -type f -not -path '*/.*' 2>/dev/null | fzf +m)
    if [ -n "$file" ]; then
        echo -n "$file" | if command -v pbcopy >/dev/null 2>&1; then pbcopy; elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; fi
        echo "Copied: $file"
    fi
}

# ── HTTP alias (guard-checked) ─────────────────────────────────────────────────
# NOTE: This duplicates the alias in .bash_aliases — kept for backwards compat
# in case .bash_functions is sourced independently.
# Quick HTTP requests with xh (if available)
if command -v xh >/dev/null 2>&1; then
    alias http='xh'
fi

# ── Suggested additions (uncomment to enable) ─────────────────────────────────
# # mkcd — alias for mkdirg (more intuitive name)
# mkcd() { mkdirg "$@"; }
#
# # tre — tree with color, ignoring .git and node_modules
# tre() { tree -aC -I '.git|node_modules|__pycache__|.venv' --dirsfirst "$@" | less -FRNX; }
#
# # gclone — git clone and cd into the repo
# gclone() { git clone "$1" && cd "$(basename "$1" .git)"; }
#
# # backup — create a timestamped backup of a file
# backup() { cp "$1" "${1}.$(date +%Y%m%d_%H%M%S).bak"; }
#
# # portcheck — check if a port is in use
# portcheck() { lsof -i :"$1"; }
