#!/bin/bash
# Install packages, then link this repo into $HOME.
#
#   git clone https://github.com/deey001/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && bash install/install.sh
#
#   bash install/install.sh --test           # syntax check, changes nothing
#   bash install/install.sh --sync-omarchy   # refresh default/bash from an Omarchy machine
#
# Files are symlinked with ln. Stow is not used: Oracle Linux 10 does not
# ship it. Safe to re-run. Anything that would be replaced is moved to
# ~/.dotfiles-backup/<timestamp>/ first.
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
    bash -n default/bashrc default/portable install/*.sh
    [[ -f bin/clip && -d config && -d default/bash ]]
    echo "ok"
    exit
    ;;
  --sync-omarchy)
    src=/usr/share/omarchy/default/bash dest=default/bash
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
  cur=$(nvim --version 2> /dev/null | sed -nE '1s/^NVIM v([0-9.]+).*/\1/p' || true)
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
      install_list "sudo pacman -S --needed --noconfirm" install/packages/arch.txt
    elif [[ -f /etc/debian_version ]]; then
      sudo apt-get update -qq
      install_list "sudo apt-get install -y" install/packages/ubuntu.txt
    elif [[ -f /etc/redhat-release ]]; then
      install_list "sudo dnf install -y" install/packages/rhel.txt
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
find "$HOME/.config" "$HOME/.local" -maxdepth 6 -type l -lname "*dotfiles/*" ! -exec test -e {} \; -delete 2> /dev/null || true

backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
# Move aside a file or directory that is not already this source.
protect() {
  local src=$1 dest=$2
  [[ -e $dest || -L $dest ]] || return 0
  [[ $(readlink -f "$dest") == $(readlink -f "$src") ]] && return 0
  local rel=${dest#"$HOME"/}
  mkdir -p "$backup/$(dirname "$rel")"
  mv "$dest" "$backup/$rel"
  echo "  backed up ~/$rel"
}

while IFS= read -r rel; do
  protect "$DOTFILES_DIR/config/$rel" "$HOME/.config/$rel"
done < <(cd config && find . \( -type f -o -type l \) | sed 's|^\./||')
while IFS= read -r rel; do
  protect "$DOTFILES_DIR/bin/$rel" "$HOME/.local/bin/$rel"
done < <(cd bin && find . \( -type f -o -type l \) | sed 's|^\./||')

link_into_home() {
  local src=$1 dest=$2
  protect "$src" "$dest"
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
}
link_tree() {
  local src_root=$1 dest_root=$2 rel
  while IFS= read -r rel; do
    link_into_home "$src_root/$rel" "$dest_root/$rel"
  done < <(cd "$src_root" && find . \( -type f -o -type l \) | sed 's|^\./||')
}
link_tree "$DOTFILES_DIR/config" "$HOME/.config"
link_tree "$DOTFILES_DIR/bin" "$HOME/.local/bin"
link_into_home "$DOTFILES_DIR/default/bashrc" "$HOME/.bashrc"
link_into_home "$DOTFILES_DIR/default/bash_profile" "$HOME/.bash_profile"
link_into_home "$DOTFILES_DIR/default/gitconfig" "$HOME/.gitconfig"
link_into_home "$DOTFILES_DIR/default/gitattributes" "$HOME/.gitattributes"
link_into_home "$DOTFILES_DIR/default/portable" "$HOME/.local/share/omarchy-shell/portable"
link_into_home "$DOTFILES_DIR/default/bash" "$HOME/.local/share/omarchy-shell/default/bash"
echo "Done. Open a new shell to load the config."
