#!/usr/bin/env bash
# Zen Browser profil yedegi — sifreler, gecmis, cerezler, site verileri HARIC.
# Beyaz liste yaklasimi: sadece asagida sayilanlar repoya girer (repo public!).
# Kullanim: ./backup.sh [--no-push]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZENDIR="$HOME/.config/zen"

# Gercek varsayilan profil [Install*] bolumundeki Default= satirinda yazar.
rel=$(awk -F= '/^\[Install/{f=1;next} /^\[/{f=0} f&&/^Default=/{print $2; exit}' "$ZENDIR/profiles.ini")
[[ -z $rel ]] && rel=$(awk -F= '/^Path=/{p=$2} /^Default=1/{print p; exit}' "$ZENDIR/profiles.ini")
SRC="$ZENDIR/$rel"
[[ -d $SRC ]] || { echo "Zen profili bulunamadi: $SRC" >&2; exit 1; }

# Not: addonStartup.json.lz4 alinmaz — mutlak yol icerir ve Zen onu
# extensions.json'dan yeniden uretir.
INCLUDE=(
    prefs.js user.js chrome
    extensions extensions.json extension-preferences.json
    extension-settings.json
    browser-extension-data extension-store extension-store-menus
    extension-store-userscripts
    containers.json handlers.json search.json.mozlz4
    xulstore.json
    zen-keyboard-shortcuts.json zen-themes.json zen-live-folders.jsonlz4
)

DEST="$SCRIPT_DIR/profile"
rm -rf "$DEST"
mkdir -p "$DEST"
for item in "${INCLUDE[@]}"; do
    [[ -e "$SRC/$item" ]] && cp -a "$SRC/$item" "$DEST/"
done

# Kimlik/sync metadata'sini ayikla (e-posta, cihaz adi, hesap uid/GUID'leri):
# giris bilgisi degildir ama public repoda isi yok. Sync'e her makinede
# elle giris yapilir.
sed -i '/identity\.fxaccounts\|services\.sync/d' "$DEST/prefs.js"
printf '%s\n' "$rel" >"$SCRIPT_DIR/profile-name.txt"
# Zen varsayilan profili [InstallXXXX] bolumunden secer; kimligi sakla
# (ayni paket ayni yola kuruldugundan kimlik makineler arasi aynidir).
grep -oP '^\[Install\K[0-9A-F]+(?=\])' "$ZENDIR/profiles.ini" >"$SCRIPT_DIR/install-ids.txt" || true
echo "Zen profili yedeklendi: $rel ($(du -sh "$DEST" | cut -f1))"

cd "$SCRIPT_DIR/.."
if ! git status --porcelain zen/ | grep -q .; then
    echo "Degisiklik yok."
    exit 0
fi
git status --short zen/ | head -10
[[ ${1:-} == "--no-push" ]] && exit 0
git add zen/
git commit -m "chore: zen yedegi $(date +%Y-%m-%d)"
git push
