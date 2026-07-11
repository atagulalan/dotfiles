#!/usr/bin/env bash
# GNOME ayarlarını dconf'a yükle + arkaplanı kopyala
# Kullanım: ./restore.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "GNOME dconf ayarları yükleniyor..."
# dconf.ini içindeki mutlak yollar kullanıcı adına bağlı; $HOME'a çevir.
sed "s|/home/xava|$HOME|g" "$SCRIPT_DIR/dconf.ini" | dconf load /org/gnome/

# GNOME arkaplanı ~/.config/background dosyasından okur (symlink değil kopya:
# duvar kağıdı değiştirilince GNOME bu dosyanın üzerine yazar).
echo "Arkaplan kopyalanıyor..."
cp "$SCRIPT_DIR/../backgrounds/gnome-background.png" "$HOME/.config/background"

echo "Tamamlandı."
