#!/usr/bin/env bash
# GNOME ayarlarını dconf'a yükle
# Kullanım: ./restore.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "GNOME dconf ayarları yükleniyor..."
dconf load /org/gnome/ < "$SCRIPT_DIR/dconf.ini"
echo "Tamamlandı."
