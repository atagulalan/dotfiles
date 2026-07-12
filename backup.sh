#!/usr/bin/env bash
# Tum yedekleri alir (GNOME + Zen + etc + paket listesi) ve tek commit ile pushlar.
# Kullanim: ./backup.sh [--no-push]
set -euo pipefail

cd "$(dirname "$0")"

./gnome/backup.sh --no-push
echo
if [[ -f $HOME/.config/zen/profiles.ini ]]; then
    ./zen/backup.sh --no-push
else
    echo "Zen kurulu degil, atlandi."
fi
echo
./etc/backup.sh --no-push

echo
# Referans amacli tam paket listesi; kurulum icin packages.txt kullanilir.
{
    echo "# Otomatik uretilir (backup.sh), elle duzenleme. Kurulum listesi: packages.txt"
    echo "# pacman -Qqe:"
    pacman -Qqe
    echo "# --- AUR/yabanci paketler (pacman -Qqm) ---"
    pacman -Qqm
} >packages-snapshot.txt
echo "Paket listesi guncellendi (packages-snapshot.txt)."

echo
if ! git status --porcelain | grep -q .; then
    echo "Degisiklik yok, repo guncel."
    exit 0
fi
git status --short | head -20
[[ ${1:-} == "--no-push" ]] && exit 0
git add -A
git commit -m "chore: yedek $(date +%Y-%m-%d)"
git push
echo "Yedek pushlandi."
