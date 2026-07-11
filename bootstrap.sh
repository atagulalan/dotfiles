#!/usr/bin/env bash
# Fresh-machine bootstrap for a new CachyOS install.
# Clones the repo, installs packages interactively, stows configs, runs extras.
#
# One-liner (fish/bash uyumlu):
#   curl -fsSL https://raw.githubusercontent.com/atagulalan/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

# When piped (curl | bash), stdin is the pipe; reattach prompts to the terminal.
[[ -t 0 ]] || exec </dev/tty

REPO="https://github.com/atagulalan/dotfiles.git"
DIR="$HOME/dotfiles"

echo "==> Installing prerequisites (git, stow, paru)"
sudo pacman -S --needed --noconfirm git stow paru

if [[ ! -d $DIR/.git ]]; then
    echo "==> Cloning $REPO"
    git clone "$REPO" "$DIR"
else
    echo "==> $DIR already exists, pulling latest"
    git -C "$DIR" pull --ff-only
fi
cd "$DIR"

echo
echo "==> Installing packages (interactive)"
./install-packages.sh

echo
echo "==> Stowing configs"
# A stow package = top-level dir with a dot-prefixed entry at its root.
# mimeapps is excluded: install.sh copies it instead of symlinking.
packages=()
for d in */; do
    d=${d%/}
    [[ $d == mimeapps ]] && continue
    if find "$d" -maxdepth 1 -name ".*" -print -quit | grep -q .; then
        packages+=("$d")
    fi
done
echo "Packages: ${packages[*]}"
read -rp "Existing configs will be REPLACED by repo versions. Continue? [y/N] " ok
if [[ $ok =~ ^[yY] ]]; then
    # --adopt pulls pre-existing target files into the repo so stow can link;
    # git restore then discards them, so the committed configs win.
    stow --adopt "${packages[@]}"
    git restore .
else
    echo "Skipped stow."
fi

echo
echo "==> Running extras (bin scripts, desktop entries, mimeapps)"
./install.sh

if [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]] && command -v dconf &>/dev/null; then
    echo
    read -rp "Load GNOME dconf settings (keybindings, extensions, etc.)? [y/N] " g
    [[ $g =~ ^[yY] ]] && ./gnome/restore.sh
fi

echo
echo "==> Bootstrap complete. Log out and back in for everything to take effect."
