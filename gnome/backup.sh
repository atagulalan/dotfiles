#!/usr/bin/env bash
# Ana makinedeki guncel GNOME durumunu repoya alir ve pushlar.
# Kullanim: ./backup.sh            yedekle + commit + push
#           ./backup.sh --no-push  sadece dosyalari guncelle, git'e dokunma
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> dconf dump aliniyor (/org/gnome/)"
dconf dump /org/gnome/ >dconf.ini

echo "==> Arkaplan kopyalaniyor"
cp "$HOME/.config/background" ../backgrounds/gnome-background.png

echo "==> XDG kullanici dizinleri (user-dirs.dirs)"
cp "$HOME/.config/user-dirs.dirs" user-dirs.dirs

echo "==> Kenar cubugu (gtk-3.0/bookmarks)"
cp "$HOME/.config/gtk-3.0/bookmarks" gtk-bookmarks

echo "==> Ozel eklentiler senkronlaniyor"
./sync-extensions.sh

# Public repoya gidecek dump'ta suphe ceken bir sey var mi?
if grep -niE "password|token|secret|api.?key" dconf.ini | grep -vE "password=.?(false|none|'')" | head -3 | grep -q .; then
    echo
    echo "UYARI: dconf.ini icinde supheli anahtar(lar) var, pushlamadan once kontrol et:"
    grep -niE "password|token|secret|api.?key" dconf.ini | head -3
fi

cd ..
if ! git status --porcelain gnome/ backgrounds/ | grep -q .; then
    echo "Degisiklik yok, repo zaten guncel."
    exit 0
fi

echo
git status --short gnome/ backgrounds/

if [[ ${1:-} == "--no-push" ]]; then
    echo "(--no-push: commit atlanmadi, dosyalar hazir)"
    exit 0
fi

git add gnome/ backgrounds/
git commit -m "chore: gnome yedegi $(date +%Y-%m-%d) (dconf, arkaplan, user-dirs, bookmarks)"
git push
echo "Yedek pushlandi."
