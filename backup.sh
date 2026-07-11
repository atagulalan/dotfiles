#!/usr/bin/env bash
# Tum yedekleri alir (GNOME + Zen) ve tek commit ile pushlar.
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
