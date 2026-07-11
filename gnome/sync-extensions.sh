#!/usr/bin/env bash
# Lokaldeki ozel eklentileri repoya geri kopyalar (fork guncellemesi sonrasi).
# gnome/extensions/ altinda zaten var olan UUID'ler senkronlanir.
# Kullanim: ./sync-extensions.sh            kopyala, degisiklikleri goster
#           ./sync-extensions.sh --commit   ustune commit + push da yap
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_EXT="$HOME/.local/share/gnome-shell/extensions"
REPO_EXT="$SCRIPT_DIR/extensions"

for dst in "$REPO_EXT"/*/; do
    uuid=$(basename "$dst")
    src="$LOCAL_EXT/$uuid"
    if [[ ! -d $src ]]; then
        echo "! $uuid lokalde kurulu degil, atlandi"
        continue
    fi
    rm -rf "$dst"
    cp -a "$src" "$REPO_EXT/$uuid"
    echo "~ $uuid repoya kopyalandi"
done

cd "$SCRIPT_DIR/.."
if git status --porcelain gnome/extensions | grep -q .; then
    echo
    git status --short gnome/extensions
    if [[ ${1:-} == "--commit" ]]; then
        git add gnome/extensions
        git commit -m "chore: ozel eklentiler senkronlandi"
        git push
    else
        echo
        echo "Commit + push icin: ./gnome/sync-extensions.sh --commit"
    fi
else
    echo "Degisiklik yok, repo zaten guncel."
fi
