#!/usr/bin/env bash
# /etc konfiglerini geri yukler (sudo ister). Simdilik: coolercontrol.
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
