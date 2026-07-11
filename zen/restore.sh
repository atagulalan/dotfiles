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

# Mutlak yollari bu makinenin HOME'una cevir (prefs.js + extensions.json vb.
# eklenti kayitlari xpi'lere tam yolla isaret eder).
sed -i "s|/home/xava|$HOME|g" "$DEST/prefs.js"
find "$DEST" -maxdepth 1 -name '*.json' -exec sed -i "s|/home/xava|$HOME|g" {} +
# Eski yedeklerden gelmis olabilir; eski yollar icerir, Zen yeniden uretir.
rm -f "$DEST/addonStartup.json.lz4"

# Kurulum kimlikleri: Zen varsayilan profili [InstallXXXX] bolumunden okur.
# Yedekteki + hedef makinede olusmus kimliklerin hepsini bizim profile yonlendir.
ids=$(cat "$SCRIPT_DIR/install-ids.txt" 2>/dev/null || true)
[[ -f $ZENDIR/profiles.ini ]] &&
    ids+=" $(grep -oP '^\[Install\K[0-9A-F]+(?=\])' "$ZENDIR/profiles.ini" || true)"
ids=$(printf '%s\n' $ids | sort -u)

{
    cat <<EOF
[Profile0]
Name=Default (release)
IsRelative=1
Path=$rel
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF
    for id in $ids; do
        printf '\n[Install%s]\nDefault=%s\nLocked=1\n' "$id" "$rel"
    done
} >"$ZENDIR/profiles.ini"

echo "Zen profili geri yuklendi: $rel"
echo "Not: sifreler/gecmis tasinmaz. Yer imleri ilk aciliste bookmarkbackups'tan otomatik gelir."
