#!/usr/bin/env bash
# Zen Browser profilini geri yukler. Zen KAPALIYKEN calistirilmali.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZENDIR="$HOME/.config/zen"

[[ -f $SCRIPT_DIR/profile-name.txt ]] || { echo "Repoda zen yedegi yok." >&2; exit 1; }
rel=$(<"$SCRIPT_DIR/profile-name.txt")
DEST="$ZENDIR/$rel"

if pgrep -f "zen-browser|zen-bin" &>/dev/null; then
    echo "UYARI: Zen calisiyor gorunuyor; kapatip tekrar calistir." >&2
    exit 1
fi

mkdir -p "$DEST"
cp -a "$SCRIPT_DIR/profile/." "$DEST/"

# prefs.js icindeki mutlak yollari bu makinenin HOME'una cevir.
sed -i "s|/home/xava|$HOME|g" "$DEST/prefs.js"

# Profili kaydet ve varsayilan yap (mevcut profiles.ini ustune yazilir).
cat >"$ZENDIR/profiles.ini" <<EOF
[Profile0]
Name=Default (release)
IsRelative=1
Path=$rel
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF

echo "Zen profili geri yuklendi: $rel"
echo "Not: sifreler/gecmis tasinmaz. Yer imleri ilk aciliste bookmarkbackups'tan otomatik gelir."
