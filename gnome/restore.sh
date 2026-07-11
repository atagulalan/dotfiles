#!/usr/bin/env bash
# GNOME ayarlarını dconf'a yükle + arkaplanı kopyala
# Kullanım: ./restore.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "GNOME dconf ayarları yükleniyor..."
# dconf.ini içindeki mutlak yollar kullanıcı adına bağlı; $HOME'a çevir.
sed "s|/home/xava|$HOME|g" "$SCRIPT_DIR/dconf.ini" | dconf load /org/gnome/

# dconf'un referans verdiği dosyalar (duvar kağıdı vb.) GNOME'un beklediği
# yere kopyalanır; dconf yolları sed ile bu makinenin $HOME'una çevrildi.
if compgen -G "$SCRIPT_DIR/../backgrounds/wallpaper/*" >/dev/null; then
    echo "Duvar kağıdı kopyalanıyor..."
    mkdir -p "$HOME/.local/share/backgrounds"
    cp "$SCRIPT_DIR/../backgrounds/wallpaper/"* "$HOME/.local/share/backgrounds/"
fi

# xdg-user-dirs-update dosyayı yeniden yazabildiği için kopya (symlink değil).
if [[ -f $SCRIPT_DIR/user-dirs.dirs ]]; then
    echo "XDG kullanıcı dizinleri uygulanıyor..."
    cp "$SCRIPT_DIR/user-dirs.dirs" "$HOME/.config/user-dirs.dirs"
    while IFS='=' read -r key val; do
        [[ $key == XDG_*_DIR ]] || continue
        dir=$(eval echo "$val")
        [[ $dir != "$HOME" ]] && mkdir -p "$dir"
    done < <(grep -E '^XDG_' "$SCRIPT_DIR/user-dirs.dirs")
fi

# Nautilus/GTK kenar çubuğu bu bookmark listesinden gelir.
if [[ -f $SCRIPT_DIR/gtk-bookmarks ]]; then
    echo "Kenar çubuğu bookmark'ları uygulanıyor..."
    mkdir -p "$HOME/.config/gtk-3.0"
    sed "s|/home/xava|$HOME|g" "$SCRIPT_DIR/gtk-bookmarks" >"$HOME/.config/gtk-3.0/bookmarks"
fi

echo "Tamamlandı."
