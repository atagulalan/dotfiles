#!/usr/bin/env bash
# backup.sh ile alinan sifreli secrets arsivini yerine acar.
# Kullanim: ./restore.sh <secrets-....tar.gpg> [--list]
#   --list  sadece icerigi gosterir, hicbir sey yazmaz.
set -euo pipefail

ARCHIVE="${1:?Kullanim: $0 <arsiv.tar.gpg> [--list]}"
LIST="${2:-}"
[[ -f $ARCHIVE ]] || { echo "Arsiv bulunamadi: $ARCHIVE" >&2; exit 1; }

STAGE="$(mktemp -d)"
chmod 700 "$STAGE"
trap 'rm -rf "$STAGE"' EXIT

read -rsp "Arsiv sifresi: " p; echo
gpg --batch --quiet --no-symkey-cache --pinentry-mode loopback \
    --passphrase-fd 3 -d "$ARCHIVE" 3<<<"$p" | tar -C "$STAGE" -xf - ||
    { echo "Acilamadi (sifre yanlis olabilir)." >&2; exit 1; }
unset p

if [[ $LIST == --list ]]; then
    for t in home root zen; do
        [[ -f $STAGE/$t.tar ]] && { echo "[$t]"; tar -tf "$STAGE/$t.tar" | sed 's/^/  /'; }
    done
    exit 0
fi

if [[ -f $STAGE/home.tar ]]; then
    tar -C "$HOME" -xpf "$STAGE/home.tar"
    # ssh/gpg izinleri yanlissa calismazlar.
    [[ -d $HOME/.ssh ]] && { chmod 700 ~/.ssh; find ~/.ssh -type f ! -name '*.pub' ! -name known_hosts\* -exec chmod 600 {} +; }
    [[ -d $HOME/.gnupg ]] && { chmod 700 ~/.gnupg; find ~/.gnupg -type f -exec chmod 600 {} +; }
    echo "Ev dizini dosyalari yuklendi."
fi

if [[ -f $STAGE/root.tar ]]; then
    read -rp "Sistem dosyalari (/etc, sudo ister) yuklensin mi? [Y/n] " a
    if [[ ! $a =~ ^[nN] ]]; then
        sudo tar -C / --same-owner -xpf "$STAGE/root.tar"
        echo "Sistem dosyalari yuklendi (NetworkManager/coolercontrol icin servisleri yeniden baslat)."
    fi
fi

if [[ -f $STAGE/zen.tar ]]; then
    ZENDIR="$HOME/.config/zen"
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    rel=""
    [[ -f $REPO_DIR/zen/profile-name.txt ]] && rel=$(<"$REPO_DIR/zen/profile-name.txt")
    if [[ -z $rel ]]; then
        echo "Zen profil adi bilinmiyor (zen/profile-name.txt yok); Zen dosyalari atlandi." >&2
    elif pgrep -f "zen-browser|zen-bin" &>/dev/null; then
        echo "Zen acik; Zen dosyalari atlandi. Kapatip tekrar: $0 $ARCHIVE" >&2
    else
        mkdir -p "$ZENDIR/$rel"
        tar -C "$ZENDIR/$rel" -xpf "$STAGE/zen.tar"
        echo "Zen sifreleri/cerezleri/gecmisi yuklendi."
    fi
fi

echo "Tamam."
