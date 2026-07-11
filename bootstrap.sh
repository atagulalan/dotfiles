#!/usr/bin/env bash
# Fresh-machine bootstrap for a new CachyOS install.
# Clones the repo, installs packages interactively, stows configs, runs extras.
#
# One-liner (fish/bash uyumlu):
#   curl -fsSL https://raw.githubusercontent.com/atagulalan/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

REPO="https://github.com/atagulalan/dotfiles.git"
DIR="$HOME/dotfiles"

# curl | bash: stdin is the script itself, so interactive prompts would eat
# the remaining script lines. Clone first, then re-exec from disk with a tty.
if [[ ! -t 0 ]]; then
    echo "==> Piped run detected; cloning and re-executing from disk"
    sudo pacman -S --needed --noconfirm git
    [[ -d $DIR/.git ]] || git clone "$REPO" "$DIR"
    git -C "$DIR" pull --ff-only || true
    exec bash "$DIR/bootstrap.sh" </dev/tty
fi

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
echo "==> Installing packages"
read -rp "Paketler: [A] hepsini kur / [i] interaktif seç / [s] atla: " mode
case ${mode:-a} in
    i | I) ./install-packages.sh ;;
    s | S) echo "Paket kurulumu atlandı." ;;
    *) ./install-packages.sh --all ;;
esac

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
read -rp "Existing configs will be REPLACED by repo versions. Continue? [Y/n] " ok
if [[ ! $ok =~ ^[nN] ]]; then
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

# nvm.fish (fisher eklentisi repo'da) varsayilan node surumunu istiyor;
# kurulu degilse acilista hata veriyor. Stow sonrasi indirip kuralim.
nvmver=$(grep -oP 'nvm_default_version:\K[0-9.]+' fish/.config/fish/fish_variables 2>/dev/null || true)
if [[ -n $nvmver ]] && command -v fish &>/dev/null; then
    echo
    echo "==> Node $nvmver kuruluyor (nvm.fish)"
    fish -c "nvm install $nvmver" ||
        echo "nvm install basarisiz; sonra elle: fish -c 'nvm install $nvmver'"
fi

# oh-my-fish: prompt temasi + bass, ayarlari stow'lanan ~/.config/omf'tan okur.
if [[ ! -d $HOME/.local/share/omf ]] && command -v fish &>/dev/null; then
    echo
    echo "==> oh-my-fish kuruluyor"
    omftmp=$(mktemp)
    curl -fsSL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install -o "$omftmp"
    fish "$omftmp" --noninteractive --yes || echo "omf kurulumu basarisiz; elle: fish $omftmp --noninteractive"
    rm -f "$omftmp"
    fish -c "omf install" || true
    # omf installer conf.d/omf.fish'i korumasiz surumle ezebilir; geri al
    git -C "$DIR" checkout -- fish/.config/fish/conf.d/omf.fish 2>/dev/null || true
fi

if [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]] && command -v dconf &>/dev/null; then
    echo
    read -rp "GNOME kurulumu: eklentiler + dconf ayarları + arkaplan? [Y/n] " g
    if [[ ! $g =~ ^[nN] ]]; then
        ./gnome/install-extensions.sh
        ./gnome/restore.sh
    fi
fi

if [[ -f zen/profile-name.txt ]]; then
    echo
    read -rp "Zen Browser profili geri yüklensin mi (eklentiler, ayarlar)? [Y/n] " z
    if [[ ! $z =~ ^[nN] ]]; then
        ./zen/restore.sh || echo "Zen geri yükleme başarısız (Zen açık olabilir), sonra tekrar: ./zen/restore.sh"
    fi
fi

echo
echo "==> Bootstrap tamamlandı."
read -rp "Değişikliklerin aktifleşmesi için oturum kapatılsın mı? [Y/n] " lo
if [[ ! $lo =~ ^[nN] ]]; then
    if command -v gnome-session-quit &>/dev/null; then
        gnome-session-quit --logout --no-prompt
    else
        loginctl terminate-session "${XDG_SESSION_ID:-}"
    fi
fi
