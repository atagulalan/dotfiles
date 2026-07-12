#!/usr/bin/env bash
# /etc ve /opt konfiglerini geri yukler (sudo ister):
# coolercontrol, ollama servis override'i, zapret.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d $SCRIPT_DIR/coolercontrol ]]; then
    echo "coolercontrol konfigleri /etc/coolercontrol'a kopyalaniyor..."
    sudo mkdir -p /etc/coolercontrol
    sudo cp "$SCRIPT_DIR/coolercontrol/"* /etc/coolercontrol/
    sudo chown root:root /etc/coolercontrol/*.toml /etc/coolercontrol/*.json
    if command -v systemctl &>/dev/null && systemctl list-unit-files coolercontrold.service &>/dev/null; then
        echo "coolercontrold servisi etkinlestiriliyor..."
        sudo systemctl enable --now coolercontrold
        sudo systemctl restart coolercontrold
    fi
    echo "Tamam. Not: profil/fan egrileri donanim UID'lerine bagli;"
    echo "farkli donanimda eslesmeyen girisleri CoolerControl arayuzden duzeltmen gerekir."
fi

if [[ -f $SCRIPT_DIR/ollama/override.conf ]]; then
    echo "ollama servis override'i yukleniyor..."
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    # Kullanici adi/home yolu yeni makineye uyarlanir (xava -> yeni ad).
    sed -e "s|^User=.*|User=$USER|" -e "s|^Group=.*|Group=$USER|" \
        -e "s|/home/[^/\"]*|$HOME|g" "$SCRIPT_DIR/ollama/override.conf" |
        sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null
    sudo systemctl daemon-reload
    echo "Tamam. ollama paketi kuruluysa: sudo systemctl restart ollama"
fi

if [[ -f $SCRIPT_DIR/zapret/config ]]; then
    if [[ -d /opt/zapret ]]; then
        echo "zapret config /opt/zapret'e kopyalaniyor..."
        sudo cp "$SCRIPT_DIR/zapret/config" /opt/zapret/config
        echo "Tamam. Hostlist'ler yedekte yok; /opt/zapret/ipset altina elle ekle."
    else
        echo "UYARI: /opt/zapret yok. Once zapret'i kur, sonra tekrar: ./etc/restore.sh"
    fi
fi
