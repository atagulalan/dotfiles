#!/usr/bin/env bash
# Repoya girmeyen gizli dosyalari (paths.txt) tek bir sifreli arsivde toplar.
# Cikti: secrets-YYYY-MM-DD.tar.gpg (gpg simetrik, AES256). Repo DISINDA tut.
# Kullanim: ./backup.sh [cikti-yolu]   (varsayilan: ~/secrets-<tarih>.tar.gpg)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${1:-$HOME/secrets-$(date +%F).tar.gpg}"
OUT="$(realpath -m "$OUT")"

case "$OUT" in
"$REPO_DIR"/*) echo "Arsiv repo icine yazilamaz (repo public!): $OUT" >&2; exit 1 ;;
esac
[[ -e $OUT ]] && { read -rp "$OUT zaten var, uzerine yazilsin mi? [y/N] " a; [[ $a =~ ^[yY] ]] || exit 1; }

home_items=() root_items=() zen_items=()
while IFS= read -r line; do
    line="${line%%#*}"; line="${line%"${line##*[![:space:]]}"}"
    [[ -z $line ]] && continue
    case "$line" in
    "~/"*) rel="${line#\~/}"; [[ -e $HOME/$rel ]] && home_items+=("$rel") ;;
    /*) sudo test -e "$line" && root_items+=("${line#/}") ;;
    zen:*) zen_items+=("${line#zen:}") ;;
    esac
done <"$SCRIPT_DIR/paths.txt"

STAGE="$(mktemp -d)"
chmod 700 "$STAGE"
trap 'rm -rf "$STAGE"' EXIT

if ((${#home_items[@]})); then
    tar -C "$HOME" --exclude='S.*' --warning=no-file-ignored -cf "$STAGE/home.tar" "${home_items[@]}"
fi

if ((${#root_items[@]})); then
    sudo tar -C / -cf "$STAGE/root.tar" "${root_items[@]}"
    sudo chown "$USER" "$STAGE/root.tar"
fi

ZENDIR="$HOME/.config/zen"
if ((${#zen_items[@]})) && [[ -f $ZENDIR/profiles.ini ]]; then
    rel=$(awk -F= '/^\[Install/{f=1;next} /^\[/{f=0} f&&/^Default=/{print $2; exit}' "$ZENDIR/profiles.ini")
    [[ -z $rel ]] && rel=$(awk -F= '/^Path=/{p=$2} /^Default=1/{print p; exit}' "$ZENDIR/profiles.ini")
    # Zen acikken sqlite dosyalari tutarsiz kopyalanabilir.
    while pgrep -f "zen-browser|zen-bin" &>/dev/null; do
        read -rp "Zen acik; kapatip Enter'a bas (s = Zen'i atla): " a || { echo; echo "Iptal." >&2; exit 1; }
        [[ $a =~ ^[sS] ]] && { zen_items=(); break; }
    done
    present=()
    for z in "${zen_items[@]}"; do [[ -e $ZENDIR/$rel/$z ]] && present+=("$z"); done
    if ((${#present[@]})); then
        tar -C "$ZENDIR/$rel" -cf "$STAGE/zen.tar" "${present[@]}"
        zen_items=("${present[@]}")
    fi
fi

echo "Alinanlar:"
for i in "${home_items[@]}"; do echo "  ~/$i"; done
for i in "${root_items[@]}"; do echo "  /$i"; done
[[ -f $STAGE/zen.tar ]] && for i in "${zen_items[@]}"; do echo "  zen:$i"; done

read -rsp "Arsiv sifresi: " p1; echo
read -rsp "Tekrar: " p2; echo
[[ $p1 == "$p2" ]] || { echo "Sifreler uyusmuyor." >&2; exit 1; }
[[ -n $p1 ]] || { echo "Bos sifre olmaz." >&2; exit 1; }

tar -C "$STAGE" -cf - $(cd "$STAGE" && ls) |
    gpg --batch --yes --no-symkey-cache --pinentry-mode loopback \
        --passphrase-fd 3 --symmetric --cipher-algo AES256 -o "$OUT" 3<<<"$p1"
chmod 600 "$OUT"
unset p1 p2

echo "Hazir: $OUT ($(du -h "$OUT" | cut -f1))"
echo "USB'ye / kendi buluta kopyala; sifreyi unutma, kurtarma yolu yok."
