#!/bin/bash
# Install packages and symlink home/ into $HOME with GNU Stow.
#
# Preferred (reviewable, pinned locally):
#   git clone https://github.com/deey001/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && bash scripts/install.sh
#
# Optional one-liner — pin a commit SHA, review the script, then pipe:
#   curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/8879ae54aa55021cf909a9fbe9b834d93cdc5fab/scripts/install.sh | bash
# Avoid .../master/... — that ref moves. Supply-chain risk if you skip review.
#
#   ~/dotfiles/scripts/install.sh                  # from a local clone
#   ~/dotfiles/scripts/install.sh --test           # syntax check + stow dry run, changes nothing
#   ~/dotfiles/scripts/install.sh --sync-omarchy   # refresh the bundled Omarchy shell defaults (on Omarchy)
#
# Safe to re-run. Existing files that would be replaced are moved to
# ~/.dotfiles-backup/<timestamp>/ first; scripts/uninstall.sh puts them back.
# Secrets belong in untracked locals (.bash_local, .gitconfig.local) — see .gitignore.

REPO=https://github.com/deey001/dotfiles.git

if [[ -f ${BASH_SOURCE[0]:-} ]]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
else
  # Piped from curl: clone (or update) ~/dotfiles, then continue from there.
  DOTFILES_DIR="$HOME/dotfiles"
  if [[ -d $DOTFILES_DIR/.git ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only || echo "! Could not fast-forward $DOTFILES_DIR, using it as-is"
  else
    git clone "$REPO" "$DOTFILES_DIR"
  fi
fi

set -euo pipefail
cd "$DOTFILES_DIR"

case "${1:-}" in
  "") ;;
  --test)
    bash -n home/.bashrc home/.local/share/omarchy-shell/portable scripts/*.sh
    stow -n --no-folding --dir="$DOTFILES_DIR" --target="$HOME" home
    echo "ok"
    exit
    ;;
  --sync-omarchy)
    src=/usr/share/omarchy/default/bash dest=home/.local/share/omarchy-shell/default/bash
    [[ -d $src ]] || { echo "Omarchy not found at $src" >&2; exit 1; }
    rm -rf "$dest" && cp -r "$src" "$dest"
    git status --short "$dest"
    exit
    ;;
  *)
    echo "Usage: install.sh [--test | --sync-omarchy]" >&2
    exit 1
    ;;
esac

# Install each package on its own so one missing name doesn't abort the rest.
install_list() {
  local cmd=$1 list=$2 pkg
  for pkg in $(awk '!/^[[:space:]]*#/ && NF {print $1}' "$list"); do
    $cmd "$pkg" > /dev/null 2>&1 || echo "  skipped: $pkg"
  done
}

# LazyVim needs nvim >= 0.11.2; older distros (e.g. Ubuntu 24.04) ship 0.9.x.
install_nvim() {
  local min=0.11.2 cur asset dir="$HOME/.local/share/nvim-linux"
  cur=$(nvim --version 2> /dev/null | sed -nE '1s/^NVIM v([0-9.]+).*/\1/p')
  [[ -n $cur && $(printf '%s\n%s\n' "$min" "$cur" | sort -V | head -1) == "$min" ]] && return
  case "$(uname -m)" in
    x86_64) asset=nvim-linux-x86_64.tar.gz ;;
    aarch64) asset=nvim-linux-arm64.tar.gz ;;
    *) echo "  nvim ${cur:-missing} is too old; install >= $min manually"; return ;;
  esac
  echo "--- Installing Neovim to $dir ---"
  rm -rf "$dir" && mkdir -p "$dir"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$asset" | tar -xz -C "$dir" --strip-components=1
  ln -sf "$dir/bin/nvim" "$HOME/.local/bin/nvim"
}

echo "--- Packages ---"
mkdir -p "$HOME/.local/bin"
case "$(uname)" in
  Darwin)
    command -v brew &> /dev/null ||
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew bundle --file="$DOTFILES_DIR/Brewfile"
    ;;
  Linux)
    if [[ -f /etc/arch-release ]]; then
      install_list "sudo pacman -S --needed --noconfirm" platform/packages/arch.txt
    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get update -qq
      install_list "sudo apt-get install -y" platform/packages/ubuntu.txt
    elif [[ -f /etc/redhat-release ]]; then
      install_list "sudo dnf install -y" platform/packages/rhel.txt
    fi
    install_nvim
    ;;
esac

# Debian/Ubuntu ship fd and bat as fdfind and batcat.
command -v fd &> /dev/null || ! command -v fdfind &> /dev/null || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
command -v bat &> /dev/null || ! command -v batcat &> /dev/null || ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"

if ! command -v starship &> /dev/null; then
  echo "--- Installing starship to ~/.local/bin ---"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" > /dev/null
fi

echo "--- Linking dotfiles ---"
# Drop dangling links left behind by files removed from the repo.
find "$HOME" -maxdepth 1 -type l -lname "*dotfiles/*" ! -exec test -e {} \; -delete
find "$HOME/.config" "$HOME/.local/share" -maxdepth 5 -type l -lname "*dotfiles/*" ! -exec test -e {} \; -delete 2> /dev/null || true

# Move aside anything stow would otherwise refuse to overwrite.
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
while IFS= read -r rel; do
  target="$HOME/$rel"
  if [[ -e $target || -L $target ]] && [[ $(readlink -f "$target") != "$DOTFILES_DIR/home/$rel" ]]; then
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$target" "$backup/$rel"
    echo "  backed up ~/$rel"
  fi
done < <(cd home && find . -type f -o -type l | sed 's|^\./||')

stow -R --no-folding --dir="$DOTFILES_DIR" --target="$HOME" home
echo "Done. Open a new shell to load the config."
