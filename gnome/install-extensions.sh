#!/usr/bin/env bash
# GNOME eklentilerini extensions.gnome.org'dan indirip kurar.
# Etkinleştirme dconf'tan gelir (restore.sh), oturum yenileyince aktifleşir.
set -uo pipefail

UUIDS=(
    blur-my-shell@aunetx
    color-picker@tuberry
    current-monitor-window-app-switcher@thmatosbr
    dash-to-panel@jderose9.github.com
    just-perfection-desktop@just-perfection
    no-overview@fthx
    quicksettings-audio-devices-hider@marcinjahn.com
    Rounded_Corners@lennart-k
    screentospace@dilzhan.dev
    tiling-assistant@leleat-on-github
    user-theme@gnome-shell-extensions.gcampax.github.com
    vicinae@dagimg-dot
    Vitals@CoreCoding.com
)

ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
ok=0
fail=()
for uuid in "${UUIDS[@]}"; do
    if gnome-extensions info "$uuid" &>/dev/null; then
        echo "= $uuid (zaten kurulu)"
        ok=$((ok + 1))
        continue
    fi
    json=$(curl -fsSG "https://extensions.gnome.org/extension-info/" \
        --data-urlencode "uuid=$uuid" \
        --data-urlencode "shell_version=$ver" 2>/dev/null) || json=""
    dl=$(printf '%s' "$json" | grep -o '"download_url": *"[^"]*"' | cut -d\" -f4)
    if [[ -z $dl ]]; then
        echo "X $uuid: extensions.gnome.org'da bulunamadi (shell $ver)"
        fail+=("$uuid")
        continue
    fi
    tmp=$(mktemp --suffix=.shell-extension.zip)
    if curl -fsSL "https://extensions.gnome.org$dl" -o "$tmp" &&
        gnome-extensions install --force "$tmp" &>/dev/null; then
        echo "+ $uuid kuruldu"
        ok=$((ok + 1))
    else
        echo "X $uuid: kurulum basarisiz"
        fail+=("$uuid")
    fi
    rm -f "$tmp"
done

# Repo'da tasinan ozel eklentiler (fork/custom, EGO listesinde degiller).
# Kopyalama her calismada yapilir ki repo'daki surum her zaman kazansin.
EXTSRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/extensions"
DEST="$HOME/.local/share/gnome-shell/extensions"
if [[ -d $EXTSRC ]]; then
    mkdir -p "$DEST"
    for src in "$EXTSRC"/*/; do
        uuid=$(basename "$src")
        rm -rf "${DEST:?}/$uuid"
        cp -a "$src" "$DEST/$uuid"
        echo "+ $uuid (repo'dan kopyalandi)"
        ok=$((ok + 1))
    done
fi

echo
echo "$ok kuruldu/mevcut, ${#fail[@]} basarisiz."
if ((${#fail[@]})); then
    printf '  eksik: %s\n' "${fail[@]}"
    echo "  (bunlari manuel kur veya UUID listesinden cikar)"
fi
